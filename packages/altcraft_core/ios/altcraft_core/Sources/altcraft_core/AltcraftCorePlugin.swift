import Flutter
import UIKit
import AltcraftCore

/// Flutter plugin entry point for the Altcraft core module.
///
/// Registers the core method channel and the shared native SDK events channel.
public class AltcraftCorePlugin: NSObject, FlutterPlugin {
  /// Registers the core method channel and event channel with the plugin registrar.
  ///
  /// - Parameter registrar: Flutter plugin registrar used to attach channels to the binary messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let bridge = CoreBridge(messenger: registrar.messenger())
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/core", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
    let eventChannel = FlutterEventChannel(name: "com.altcraft/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(bridge)
  }
}

/// Bridges Flutter platform-channel calls to the native Altcraft core SDK.
///
/// Handles core initialization, native SDK events, JWT authentication, and
/// data management. The bridge guarantees that every method call is completed
/// with either a success value or a FlutterError, preventing Dart-side await
/// calls from hanging.
class CoreBridge: NSObject, FlutterStreamHandler {
  private let methodChannel: FlutterMethodChannel
  nonisolated(unsafe) private var eventSink: FlutterEventSink?
  private var eventSubscriptionCancelled = false

  /// Creates a bridge bound to the given binary messenger.
  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: "com.altcraft/core", binaryMessenger: messenger)
    super.init()
  }

  /// Starts listening to native Altcraft SDK events and forwards them to Flutter.
  ///
  /// - Parameters:
  ///   - arguments: Optional Flutter event-channel arguments.
  ///   - eventSink: Sink used to send events to Dart.
  /// - Returns: `nil` when the stream is attached successfully.
  public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    eventSubscriptionCancelled = false
    self.eventSink = eventSink
    SDKEvents.shared.subscribe { [weak self] event in
      guard let self, !self.eventSubscriptionCancelled else { return }
      let dict: [String: Any?] = self.eventToDict(event)
      let boxedDict = SendableBox(dict as Any?)
      let boxedSink = SendableBox(self.eventSink)
      DispatchQueue.main.async {
        guard let sink = boxedSink.get() as? FlutterEventSink,
              let d = boxedDict.get() as? [String: Any?] else { return }
        sink(d)
      }
    }
    return nil
  }

  /// Stops forwarding native SDK events to Flutter.
  ///
  /// - Parameter arguments: Optional Flutter event-channel cancellation arguments.
  /// - Returns: `nil` when the stream is cancelled successfully.
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSubscriptionCancelled = true
    eventSink = nil
    SDKEvents.shared.unsubscribe()
    return nil
  }

  /// Routes a Flutter method call to the corresponding native core handler.
  ///
  /// - Parameters:
  ///   - call: Method call received from Dart.
  ///   - result: Completion callback that must be called exactly once.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize": handleInitialize(call, result: result)
    case "clear": handleClear(result: result)
    case "unlockInitialOperationsInThisSession": result(nil)
    case "setAppGroup": handleSetAppGroup(call, result: result)
    case "setUserDefaultsValue": handleSetUserDefaults(call, result: result)
    case "unsubscribeFromEvents": handleUnsubscribeFromEvents(result: result)
    case "authenticate": handleAuthenticate(result: result)
    case "logOut": handleLogOut(result: result)
    case "isAuthenticated": handleIsAuthenticated(result: result)
    case "setJwtProvider": handleSetJwtProvider(result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS core", details: nil))
    }
  }

  /// Wraps arbitrary values captured by asynchronous closures.
  final class SendableBox: @unchecked Sendable {
    private var closure: () -> Any?
    /// Stores a value inside the box.
    ///
    /// - Parameter value: Value to capture.
    init(_ value: Any?) { self.closure = { value } }
    func get() -> Any? { closure() }
    /// Replaces the stored value.
    func set(_ value: Any?) {
      self.closure = { value }
    }
  }

  /// Bridges the native JWT provider to Dart: the SDK requests a token
  /// synchronously, the bridge forwards the request to Dart over the
  /// method channel and blocks until Dart replies (bounded by a timeout).
  private final class FlutterJWTProvider: NSObject, JWTInterface {
    private let channel: FlutterMethodChannel

    /// Creates a provider that requests tokens through the given channel.
    init(channel: FlutterMethodChannel) {
      self.channel = channel
    }

    /// Returns a JWT token (synchronously).
    func getToken() -> String? {
      if Thread.isMainThread { return nil }
      let semaphore = DispatchSemaphore(value: 0)
      let box = SendableBox(nil as String?)
      DispatchQueue.main.async {
        self.channel.invokeMethod("getJwt", arguments: nil) { response in
          box.set(response as? String)
          semaphore.signal()
        }
      }
      if semaphore.wait(timeout: .now() + 10) == .success {
        return box.get() as? String
      }
      return nil
    }
  }

  // MARK: - Handlers

  /// Initializes the native Altcraft SDK core using configuration received from Dart.
  ///
  /// Module configurations (push, in-app) are contributed by module plugins
  /// through `AltcraftFlutterInitRegistry` and applied to the shared builder
  /// before native initialization starts.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing SDK configuration.
  ///   - result: Completion callback resolved after native initialization callback.
  private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let config = call.arguments as? [String: Any],
          let apiUrl = config["apiUrl"] as? String else {
      result(FlutterError(
        code: "ALTCRAFT_INIT_INVALID_CONFIG",
        message: "config/apiUrl missing",
        details: nil
      ))
      return
    }
    let appInfoDict = config["appInfo"] as? [String: Any]
    let enableLogging = config["enableLogging"] as? Bool
    let rToken = config["rToken"] as? String
    let appInfo: AppInfo? = appInfoDict.map {
      AppInfo(
        appID: $0["appID"] as? String ?? "",
        appIID: $0["appIID"] as? String ?? "",
        appVer: $0["appVer"] as? String ?? "1.0.0"
      )
    }
    let builder = AltcraftConfiguration.Builder(
      apiUrl: apiUrl,
      rToken: rToken,
      appInfo: appInfo,
      enableLogging: enableLogging
    )
    AltcraftFlutterInitRegistry.shared.applyAll(
      builder: builder,
      moduleConfigs: Self.moduleConfigs(from: config)
    )
    let altcraftConfig = builder.build()
    let initResultBox = SendableBox(result as Any?)
    AltcraftSDK.initialization(configuration: altcraftConfig) { success in
      let boxedSuccess = SendableBox(success)
      DispatchQueue.main.async {
        guard let r = initResultBox.get() as? FlutterResult else { return }
        if boxedSuccess.get() as? Bool == true {
          r(nil)
        } else {
          r(FlutterError(
            code: "INITIALIZATION_FAILED",
            message: "Altcraft SDK initialization failed",
            details: nil
          ))
        }
      }
    }
  }

  /// Clears data managed by the native Altcraft SDK.
  ///
  /// - Parameter result: Completion callback resolved after native clear callback.
  private func handleClear(result: @escaping FlutterResult) {
    AltcraftSDK.clear {
      DispatchQueue.main.async { result(nil) }
    }
  }

  /// Sets the App Group name used by the native SDK for shared storage.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `groupName`.
  ///   - result: Completion callback.
  private func handleSetAppGroup(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    guard let groupName = args["groupName"] as? String else {
      result(FlutterError(code: "ERR", message: "groupName is missing", details: nil))
      return
    }
    AltcraftSDK.setAppGroup(groupName: groupName)
    result(nil)
  }

  /// Writes or removes a string value in UserDefaults.
  ///
  /// Uses `suiteName` when provided, otherwise writes to standard UserDefaults.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `key`, optional `value`, and optional `suiteName`.
  ///   - result: Completion callback.
  private func handleSetUserDefaults(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    guard let key = args["key"] as? String else {
      result(FlutterError(code: "ERR", message: "key is missing", details: nil))
      return
    }

    let value = args["value"] as? String
    let defaults: UserDefaults
    if let suiteName = args["suiteName"] as? String {
      guard let suiteDefaults = UserDefaults(suiteName: suiteName) else {
        result(FlutterError(code: "ERR", message: "invalid suiteName", details: nil))
        return
      }
      defaults = suiteDefaults
    } else {
      defaults = UserDefaults.standard
    }

    if let value {
      defaults.setValue(value, forKey: key)
    } else {
      defaults.removeObject(forKey: key)
    }
    result(nil)
  }

  /// Unsubscribes from native SDK events and clears the current Flutter event sink.
  ///
  /// - Parameter result: Completion callback.
  private func handleUnsubscribeFromEvents(result: @escaping FlutterResult) {
    SDKEvents.shared.unsubscribe()
    eventSink = nil
    eventSubscriptionCancelled = true
    result(nil)
  }

  /// Starts SDK authentication.
  ///
  /// - Parameter result: Completion callback.
  private func handleAuthenticate(result: @escaping FlutterResult) {
    AltcraftSDK.auth.authenticate()
    result(nil)
  }

  /// Logs the user out.
  ///
  /// - Parameter result: Completion callback.
  private func handleLogOut(result: @escaping FlutterResult) {
    AltcraftSDK.auth.logOut()
    result(nil)
  }

  /// Returns whether the user is authenticated.
  ///
  /// - Parameter result: Completion callback returning a boolean.
  private func handleIsAuthenticated(result: @escaping FlutterResult) {
    let resultBox = SendableBox(result as Any?)
    Task {
      let authenticated = await AltcraftSDK.auth.isAuthenticated()
      DispatchQueue.main.async {
        guard let r = resultBox.get() as? FlutterResult else { return }
        resultBox.set(nil)
        r(authenticated)
      }
    }
  }

  /// Registers a JWT provider that the native SDK calls when it needs a token.
  ///
  /// The provider requests the token from Dart over the method channel.
  ///
  /// - Parameter result: Completion callback.
  private func handleSetJwtProvider(result: @escaping FlutterResult) {
    AltcraftSDK.auth.setJWTProvider(provider: FlutterJWTProvider(channel: methodChannel))
    result(nil)
  }

  // MARK: - Helpers

  /// Extracts module configurations from the Flutter initialization payload.
  ///
  /// The map is generic: keys are module identifiers and values are
  /// module-specific option maps produced by Dart builder extensions.
  private static func moduleConfigs(
    from config: [String: Any]
  ) -> [String: [String: Any]] {
    guard let raw = config["moduleConfigs"] as? [String: Any] else { return [:] }
    var result: [String: [String: Any]] = [:]
    for (moduleId, value) in raw {
      if let options = value as? [String: Any] {
        result[moduleId] = options
      }
    }
    return result
  }

  /// Converts a native Altcraft event into a Flutter codec-safe dictionary.
  ///
  /// - Parameter event: Native SDK event.
  /// - Returns: Event dictionary sent through the Flutter event channel.
  private func eventToDict(_ event: Event) -> [String: Any?] {
    let type: String
    if event is RetryEvent { type = "retryError" }
    else if event is ErrorEvent { type = "error" }
    else { type = "event" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US")
    formatter.timeZone = TimeZone.current
    let timestamp = formatter.string(from: event.date)
    return [
      "function": event.function,
      "code": NSNull(),
      "message": event.message ?? "",
      "type": type,
      "value": sanitizeValue(event.value) ?? NSNull(),
      "timestamp": timestamp
    ]
  }

  /// Converts nested SDK event values into Flutter codec-safe values.
  ///
  /// - Parameter value: Raw SDK event value dictionary.
  /// - Returns: Sanitized dictionary or `nil`.
  private func sanitizeValue(_ value: [String: Any]?) -> [String: Any?]? {
    guard let value else { return nil }
    var sanitized: [String: Any?] = [:]
    for (key, val) in value {
      sanitized[key] = jsonCompatibleValue(val)
    }
    return sanitized
  }

  /// Converts a single value to a JSON-compatible type.
  ///
  /// - Parameter value: Arbitrary Swift value.
  /// - Returns: JSON-compatible representation.
  private func jsonCompatibleValue(_ value: Any) -> Any {
    if value is String { return value }
    if value is Bool { return value }
    if value is Int { return value }
    if value is Double { return value }
    if let f = value as? Float { return Double(f) }
    if let arr = value as? [Any] { return arr.map { jsonCompatibleValue($0) } }
    if let dict = value as? [String: Any] {
      var result: [String: Any?] = [:]
      for (k, v) in dict { result[k] = jsonCompatibleValue(v) }
      return result
    }
    if let profile = value as? ProfileData { return profileToMap(profile) }
    if let subscription = value as? SubscriptionData { return subscriptionToMap(subscription) }
    if let category = value as? CategoryData { return categoryToMap(category) }
    if let json = value as? JSONValue { return jsonValueToCompatible(json) }
    if value is NSNull { return NSNull() }
    return String(describing: value)
  }

  /// Converts a native profile model into a codec-safe dictionary.
  private func profileToMap(_ profile: ProfileData) -> [String: Any?] {
    [
      "id": profile.id as Any?,
      "status": profile.status as Any?,
      "acid": profile.acid as Any?,
      "isTest": profile.isTest as Any?,
      "subscription": profile.subscription.map { subscriptionToMap($0) } as Any?
    ]
  }

  /// Converts a native subscription model into a codec-safe dictionary.
  private func subscriptionToMap(_ subscription: SubscriptionData) -> [String: Any?] {
    [
      "subscriptionId": subscription.subscriptionId as Any?,
      "hashId": subscription.hashId as Any?,
      "provider": subscription.provider as Any?,
      "status": subscription.status as Any?,
      "fields": subscription.fields.map { $0.mapValues { jsonValueToCompatible($0) } } as Any?,
      "cats": subscription.cats.map { $0.map { categoryToMap($0) } } as Any?
    ]
  }

  /// Converts a native subscription category into a codec-safe dictionary.
  private func categoryToMap(_ category: CategoryData) -> [String: Any?] {
    [
      "name": category.name as Any?,
      "title": category.title as Any?,
      "steady": category.steady as Any?,
      "active": category.active as Any?
    ]
  }

  /// Converts a native `JSONValue` into a codec-safe value.
  private func jsonValueToCompatible(_ value: JSONValue) -> Any {
    switch value {
    case .string(let string): return string
    case .number(let number): return number
    case .bool(let bool): return bool
    case .null: return NSNull()
    case .array(let array): return array.map { jsonValueToCompatible($0) }
    case .object(let object): return object.mapValues { jsonValueToCompatible($0) }
    }
  }
}
