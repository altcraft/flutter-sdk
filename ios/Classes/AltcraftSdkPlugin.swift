import Flutter
import UIKit
import Altcraft

/// Flutter plugin entry point that registers method and event channels for Altcraft SDK.
public class AltcraftSdkPlugin: NSObject, FlutterPlugin {
  /// Registers the Flutter method channel and event channel with the plugin registrar.
  ///
  /// - Parameter registrar: Flutter plugin registrar used to attach channels to the binary messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let bridge = SdkBridge()
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/sdk", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
    let eventChannel = FlutterEventChannel(name: "com.altcraft/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(bridge)
  }
}

/// Bridges Flutter platform-channel calls to the native Altcraft iOS SDK.
///
/// The bridge guarantees that every MethodChannel call is completed with either
/// a success value or a FlutterError, preventing Dart-side await calls from hanging.
class SdkBridge: NSObject, FlutterStreamHandler {
  nonisolated(unsafe) private var eventSink: FlutterEventSink?
  private var eventSubscriptionCancelled = false

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

  /// Routes a Flutter method call to the corresponding native Altcraft SDK handler.
  ///
  /// - Parameters:
  ///   - call: Method call received from Dart.
  ///   - result: Completion callback that must be called exactly once.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize": handleInitialize(call, result: result)
    case "getPushToken": handleGetPushToken(result: result)
    case "setPushToken": handleSetPushToken(call, result: result)
    case "clear": handleClear(result: result)
    case "mobileEvent": handleMobileEvent(call, result: result)
    case "pushSubscribe": handlePushSubscribe(call, result: result)
    case "pushSuspend": handlePushSuspend(call, result: result)
    case "pushUnSubscribe": handlePushUnSubscribe(call, result: result)
    case "unSuspendPushSubscription": handleUnSuspend(result: result)
    case "getStatusOfLatestSubscription": handleGetLatestStatus(result: result)
    case "getStatusOfLatestSubscriptionForProvider": handleGetLatestStatusForProvider(call, result: result)
    case "getStatusForCurrentSubscription": handleGetCurrentStatus(result: result)
    case "updateProfileFields": handleUpdateProfileFields(call, result: result)
    case "forcedTokenUpdate": handleForcedTokenUpdate(result: result)
    case "deleteDeviceToken": handleDeleteDeviceToken(call, result: result)
    case "changePushProviderPriorityList": handleChangePriority(call, result: result)
    case "isAltcraftPush": result(false)
    case "takePush", "deliveryEvent", "openEvent":
      result(FlutterError(
        code: "UNAVAILABLE_ON_IOS",
        message: "\(call.method) is not available on iOS",
        details: nil
      ))
    case "requestNotificationPermission", "unlockInitialOperationsInThisSession": result(nil)
    case "setAppGroup": handleSetAppGroup(call, result: result)
    case "setUserDefaultsValue": handleSetUserDefaults(call, result: result)
    case "unsubscribeFromEvents": handleUnsubscribeFromEvents(result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS", details: nil))
    }
  }

  // Sendable wrapper: captures FlutterResult via @unchecked Sendable box
  /// Thread-safe wrapper used to complete Flutter results from native async callbacks.
  private final class ResultAction: @unchecked Sendable {
    private let resultBox: ResultBox
    private let valueProvider: ValueProvider

    /// Creates an action that resolves a Flutter result with a lazily evaluated value.
    ///
    /// - Parameters:
    ///   - result: Flutter completion callback.
    ///   - value: Value provider executed when the action is completed.
    init(_ result: @escaping FlutterResult, _ value: @autoclosure @escaping () -> Any?) {
      self.resultBox = ResultBox(result)
      self.valueProvider = ValueProvider(value)
    }

    /// Completes the stored Flutter result on the main thread.
    func execute() {
      resultBox.call(valueProvider.get() ?? NSNull())
    }
  }

  /// Stores a Flutter result callback in a Sendable container.
  private final class ResultBox: @unchecked Sendable {
    nonisolated(unsafe) private var result: FlutterResult?
    /// Stores the Flutter result callback.
    ///
    /// - Parameter result: Flutter completion callback.
    init(_ result: @escaping FlutterResult) { self.result = result }
    /// Resolves the stored Flutter result with a codec-safe value.
    ///
    /// - Parameter value: Value returned to Dart.
    func call(_ value: Any) {
      guard let r = self.result else { return }
      let boxedValue = SendableBox(value)
      DispatchQueue.main.async {
        r(boxedValue.get() as Any? ?? NSNull())
      }
    }
  }

  /// Wraps a lazily computed result value for cross-thread use.
  private final class ValueProvider: @unchecked Sendable {
    private let closure: () -> Any?
    /// Creates a value provider.
    ///
    /// - Parameter closure: Closure that returns the value to send to Dart.
    init(_ closure: @escaping () -> Any?) { self.closure = closure }
    /// Returns the stored value.
    func get() -> Any? { closure() }
  }

  /// Wraps arbitrary values captured by asynchronous closures.
  private final class SendableBox: @unchecked Sendable {
    private let closure: () -> Any?
    /// Stores a value inside the box.
    ///
    /// - Parameter value: Value to capture.
    init(_ value: Any?) { self.closure = { value } }
    func get() -> Any? { closure() }
  }

  // MARK: - Handlers

  /// Initializes the native Altcraft SDK using configuration received from Dart.
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
    let providerList = (config["providerPriorityList"] as? [Any])?.compactMap { $0 as? String }
    let enableLogging = config["enableLogging"] as? Bool
    let rToken = config["rToken"] as? String
    let appInfo: AppInfo? = appInfoDict.map {
      AppInfo(
        appID: $0["appID"] as? String ?? "",
        appIID: $0["appIID"] as? String ?? "",
        appVer: $0["appVer"] as? String ?? "1.0.0"
      )
    }
    guard let altcraftConfig = AltcraftConfiguration.Builder()
      .setApiUrl(apiUrl)
      .setRToken(rToken)
      .setAppInfo(appInfo)
      .setProviderPriorityList(providerList)
      .setEnableLogging(enableLogging)
      .build() else {
      result(FlutterError(
        code: "ALTCRAFT_INIT_INVALID_CONFIG",
        message: "failed to build Altcraft configuration",
        details: nil
      ))
      return
    }
    let initResultBox = SendableBox(result as Any?)
    AltcraftSDK.shared.initialization(configuration: altcraftConfig) { success in
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

  /// Reads the currently stored native push token and returns it to Dart.
  ///
  /// - Parameter result: Completion callback returning a token map or `nil`.
  private func handleGetPushToken(result: @escaping FlutterResult) {
    let tokenHolder = TokenHolder()
    let action = ResultAction(result, tokenHolder.dict())
    AltcraftSDK.shared.pushTokenFunctions.getPushToken { tokenData in
      tokenHolder.set(tokenData.map { ($0.provider, $0.token) })
      action.execute()
    }
  }

  /// Holds push token data until an asynchronous native callback completes.
  private final class TokenHolder: @unchecked Sendable {
    nonisolated(unsafe) private var data: (String, String)?
    /// Stores push provider and token values.
    ///
    /// - Parameter d: Tuple containing provider and token.
    func set(_ d: (String, String)?) { data = d }
    /// Converts stored token data into a Flutter codec-safe dictionary.
    /// Converts the stored native response into a Flutter codec-safe dictionary.
    func dict() -> Any? { data.map { ["provider": $0.0, "token": $0.1] } }
  }

  /// Saves or clears a push token for a specific provider.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `provider` and optional `token`.
  ///   - result: Completion callback.
  private func handleSetPushToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let provider = args["provider"] as? String else {
      result(FlutterError(code: "ERR", message: "provider missing", details: nil))
      return
    }
    AltcraftSDK.shared.pushTokenFunctions.setPushToken(provider: provider, pushToken: args["token"] as? String)
    result(nil)
  }

  /// Clears data managed by the native Altcraft SDK.
  ///
  /// - Parameter result: Completion callback resolved after native clear callback.
  private func handleClear(result: @escaping FlutterResult) {
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.shared.clear { action.execute() }
  }

  /// Sends a mobile event through the native Altcraft SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing event, matching, profile, subscription, and UTM data.
  ///   - result: Completion callback resolved when the event is accepted by the native SDK.
  private func handleMobileEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    guard let sid = args["sid"] as? String, !sid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      result(FlutterError(code: "ERR", message: "sid must not be empty", details: nil))
      return
    }
    guard let eventName = args["eventName"] as? String, !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      result(FlutterError(code: "ERR", message: "eventName must not be empty", details: nil))
      return
    }
    let utmMap = args["utm"] as? [String: Any]
    let utm: UTM? = utmMap.map {
      UTM(campaign: $0["campaign"] as? String, content: $0["content"] as? String,
          keyword: $0["keyword"] as? String, medium: $0["medium"] as? String,
          source: $0["source"] as? String, temp: $0["temp"] as? String)
    }
    let subscription: (any Subscription)? = (args["subscription"] as? [String: Any]).flatMap { self.toSubscription(dict: $0) }
    AltcraftSDK.shared.mobileEventFunctions.mobileEvent(
      sid: sid, eventName: eventName,
      sendMessageId: args["sendMessageId"] as? String,
      payload: jsonCompatible(args["payload"] as? [String: Any]),
      matching: jsonCompatible(args["matching"] as? [String: Any]),
      matchingType: args["matchingType"] as? String,
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      subscription: subscription, utm: utm)
    result(nil)
  }

  /// Creates or updates a push subscription through the native SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing subscription options.
  ///   - result: Completion callback resolved when the command is accepted by the native SDK.
  private func handlePushSubscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    AltcraftSDK.shared.pushSubscriptionFunctions.pushSubscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: args["profileFields"] as? [String: Any],
      customFields: args["customFields"] as? [String: Any],
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
    result(nil)
  }

  /// Suspends the current push subscription through the native SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing subscription options.
  ///   - result: Completion callback resolved when the command is accepted by the native SDK.
  private func handlePushSuspend(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    AltcraftSDK.shared.pushSubscriptionFunctions.pushSuspend(
      sync: args["sync"] as? Bool ?? true,
      profileFields: args["profileFields"] as? [String: Any],
      customFields: args["customFields"] as? [String: Any],
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
    result(nil)
  }

  /// Unsubscribes the current push subscription through the native SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing unsubscribe options.
  ///   - result: Completion callback resolved when the command is accepted by the native SDK.
  private func handlePushUnSubscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    AltcraftSDK.shared.pushSubscriptionFunctions.pushUnSubscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: args["profileFields"] as? [String: Any],
      customFields: args["customFields"] as? [String: Any],
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
    result(nil)
  }

  /// Restores a suspended push subscription and returns the native response.
  ///
  /// - Parameter result: Completion callback returning a response map or `nil`.
  private func handleUnSuspend(result: @escaping FlutterResult) {
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.unSuspendPushSubscription { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  /// Requests the status of the latest push subscription operation.
  ///
  /// - Parameter result: Completion callback returning a response map or `nil`.
  private func handleGetLatestStatus(result: @escaping FlutterResult) {
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.getStatusOfLatestSubscription { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  /// Requests the latest push subscription status for a specific provider.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing optional `provider`.
  ///   - result: Completion callback returning a response map or `nil`.
  private func handleGetLatestStatusForProvider(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else { result(nil); return }
    let provider = args["provider"] as? String
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.getStatusOfLatestSubscriptionForProvider(
      provider: provider) { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  /// Requests the current push subscription status.
  ///
  /// - Parameter result: Completion callback returning a response map or `nil`.
  private func handleGetCurrentStatus(result: @escaping FlutterResult) {
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.getStatusForCurrentSubscription { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  /// Holds an SDK response until an asynchronous native callback completes.
  private final class ResponseHolder: @unchecked Sendable {
    nonisolated(unsafe) private var response: ResponseWithHttp?
    /// Stores the latest native response.
    ///
    /// - Parameter r: Native response with HTTP status.
    func set(_ r: ResponseWithHttp?) { self.response = r }
    func dict() -> Any? {
      guard let r = response else { return nil }
      var dict: [String: Any?] = [:]
      dict["http_code"] = r.httpCode as Any?
      if let resp = r.response {
        do {
          let data = try JSONEncoder().encode(resp)
          if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["response"] = SdkBridge.toSnakeCase(json)
          }
        } catch {
          dict["response"] = nil
        }
      } else {
        dict["response"] = nil
      }
      return dict
    }
  }

  /// Updates profile fields through the native SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `profileFields` and optional `skipTriggers`.
  ///   - result: Completion callback resolved when the command is accepted by the native SDK.
  private func handleUpdateProfileFields(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    AltcraftSDK.shared.profileFunctions.updateProfileFields(
      profileFields: args["profileFields"] as? [String: Any],
      skipTriggers: args["skipTriggers"] as? Bool)
    result(nil)
  }

  /// Forces push token update through the native SDK.
  ///
  /// - Parameter result: Completion callback resolved after native update callback.
  private func handleForcedTokenUpdate(result: @escaping FlutterResult) {
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.shared.pushTokenFunctions.forcedTokenUpdate { action.execute() }
  }

  /// Deletes a stored device token for a specific provider.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `provider`.
  ///   - result: Completion callback resolved after native delete callback.
  private func handleDeleteDeviceToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let provider = args["provider"] as? String else {
      result(FlutterError(code: "ERR", message: "provider missing", details: nil))
      return
    }
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.shared.pushTokenFunctions.deleteDeviceToken(provider: provider) { action.execute() }
  }

  /// Changes the native push provider priority list.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `priorityList`.
  ///   - result: Completion callback.
  private func handleChangePriority(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    let priorityList = (args["priorityList"] as? [Any])?.compactMap { $0 as? String } ?? []
    AltcraftSDK.shared.pushTokenFunctions.changePushProviderPriorityList(priorityList)
    result(nil)
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
    AltcraftSDK.shared.setAppGroup(groupName: groupName)
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

  // MARK: - Helpers

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
      "code": event.eventCode ?? NSNull(),
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
      if let responseWithHttp = val as? ResponseWithHttp {
        sanitized[key] = responseToDict(responseWithHttp)
      } else if let response = val as? Response {
        sanitized[key] = responseToJsonDict(response)
      } else {
        sanitized[key] = val
      }
    }
    return sanitized
  }

  /// Encodes a native response model into a JSON dictionary.
  ///
  /// - Parameter response: Native SDK response model.
  /// - Returns: JSON dictionary or `nil` if encoding fails.
  private func responseToJsonDict(_ response: Response) -> [String: Any?]? {
    do {
      let data = try JSONEncoder().encode(response)
      return try JSONSerialization.jsonObject(with: data) as? [String: Any?]
    } catch {
      return nil
    }
  }

  /// Converts a native response with HTTP status into a Flutter codec-safe dictionary.
  ///
  /// - Parameter response: Native response with optional response body.
  /// - Returns: Response dictionary or `nil`.
  private func responseToDict(_ response: ResponseWithHttp?) -> [String: Any?]? {
    guard let response else { return nil }
    var dict: [String: Any?] = [:]
    dict["http_code"] = response.httpCode as Any?
    if let resp = response.response {
      do {
        let data = try JSONEncoder().encode(resp)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          dict["response"] = SdkBridge.toSnakeCase(json)
        }
      } catch {
        dict["response"] = nil
      }
    } else {
      dict["response"] = nil
    }
    return dict
  }

  /// Converts a Flutter category dictionary into native `CategoryData`.
  ///
  /// - Parameter dict: Category dictionary received from Dart.
  /// - Returns: Native category data model.
  private func toCategoryData(dict: [String: Any]) -> CategoryData {
    CategoryData(name: dict["name"] as? String, title: dict["title"] as? String,
                 steady: dict["steady"] as? Bool, active: dict["active"] as? Bool)
  }

  /// Converts a Flutter subscription dictionary into a native subscription model.
  ///
  /// Supports `email`, `sms`, `push`, and `cc_data` subscription channels.
  ///
  /// The bridge reads `channel` as the primary discriminator and keeps `type`
  /// as a fallback for backward compatibility with older Dart payloads.
  ///
  /// Validation is strict: if required fields are missing or empty, `nil` is
  /// returned so the subscription is not sent to the native SDK.
  ///
  /// - Parameter dict: Subscription dictionary received from Dart.
  /// - Returns: Native subscription model or `nil` when the channel is unsupported
  ///   or required fields are missing.
  private func toSubscription(dict: [String: Any]) -> (any Subscription)? {
    let channel = dict["channel"] as? String ?? dict["type"] as? String ?? ""
    guard !channel.isEmpty else { return nil }

    let cf = toJV(
      (dict["customFields"] as? [String: Any])
        ?? (dict["custom_fields"] as? [String: Any])
    )
    let cats = dict["cats"] as? [String]
    guard let rid = (dict["resourceId"] as? Int)
      ?? (dict["resource_id"] as? Int),
      rid > 0 else {
      return nil
    }
    let st = dict["status"] as? String
    let pr = dict["priority"] as? Int

    switch channel {
    case "email":
      guard let email = dict["email"] as? String, !email.isEmpty else {
        return nil
      }
      return EmailSubscription(
        resourceId: rid,
        email: email,
        status: st,
        priority: pr,
        customFields: cf,
        cats: cats
      )

    case "sms":
      guard let phone = dict["phone"] as? String, !phone.isEmpty else {
        return nil
      }
      return SmsSubscription(
        resourceId: rid,
        phone: phone,
        status: st,
        priority: pr,
        customFields: cf,
        cats: cats
      )

    case "push":
      guard let provider = dict["provider"] as? String, !provider.isEmpty,
            let subscriptionId = dict["subscriptionId"] as? String
              ?? dict["subscription_id"] as? String,
            !subscriptionId.isEmpty else {
        return nil
      }
      return PushSubscription(
        resourceId: rid,
        provider: provider,
        subscriptionId: subscriptionId,
        status: st,
        priority: pr,
        customFields: cf,
        cats: cats
      )

    case "cc_data":
      guard let ccChannel = dict["ccChannel"] as? String
        ?? dict["cc_channel"] as? String,
            !ccChannel.isEmpty,
            let ccDataRaw = dict["ccData"] as? [String: Any]
              ?? dict["cc_data"] as? [String: Any],
            let ccData = toJV(ccDataRaw) else {
        return nil
      }
      return CcDataSubscription(
        resourceId: rid,
        channel: ccChannel,
        ccData: ccData,
        status: st,
        priority: pr,
        customFields: cf,
        cats: cats
      )

    default:
      return nil
    }
  }

  /// Converts a Swift dictionary into an Altcraft JSONValue dictionary.
  ///
  /// - Parameter dict: Dictionary with arbitrary JSON-like values.
  /// - Returns: JSONValue dictionary or `nil`.
  private func toJV(_ dict: [String: Any]?) -> [String: JSONValue]? {
    guard let dict else { return nil }
    var r: [String: JSONValue] = [:]
    for (k, v) in dict { r[k] = toJV(v) }
    return r
  }

  /// Converts a Swift value into Altcraft `JSONValue`.
  ///
  /// - Parameter value: JSON-like Swift value.
  /// - Returns: Equivalent JSONValue representation.
  private func toJV(_ value: Any) -> JSONValue {
    if let s = value as? String { return .string(s) }
    if let b = value as? Bool { return .bool(b) }
    if let n = value as? Int { return .number(Double(n)) }
    if let n = value as? Double { return .number(n) }
    if let a = value as? [Any] { return .array(a.map { toJV($0) }) }
    if let d = value as? [String: Any] { return .object(toJV(d) ?? [:]) }
    if value is NSNull { return .null }
    return .string(String(describing: value))
  }

  /// Converts a Flutter dictionary into JSON-compatible `[String: Any]`.
  ///
  /// Preserves native types (String, Bool, Int, Double, Array, Dictionary)
  /// instead of converting everything to String.
  ///
  /// - Parameter dict: Dictionary with arbitrary JSON-like values.
  /// - Returns: JSON-compatible dictionary or `nil`.
  private func jsonCompatible(_ dict: [String: Any]?) -> [String: Any]? {
    guard let dict else { return nil }
    var result: [String: Any] = [:]
    for (k, v) in dict {
      result[k] = jsonCompatibleValue(v)
    }
    return result
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
    if let dict = value as? [String: Any] { return jsonCompatible(dict) ?? value }
    if value is NSNull { return NSNull() }
    return String(describing: value)
  }

  /// Converts camelCase keys in a dictionary to snake_case recursively.
  ///
  /// - Parameter dict: Dictionary with camelCase keys.
  /// - Returns: Dictionary with snake_case keys.
  private static func toSnakeCase(_ dict: [String: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in dict {
      let snakeKey = Self.camelToSnake(key)
      result[snakeKey] = Self.convertValue(value)
    }
    return result
  }

  /// Recursively converts values for snake_case normalization.
  private static func convertValue(_ value: Any) -> Any {
    if let dict = value as? [String: Any] {
      return Self.toSnakeCase(dict)
    } else if let arr = value as? [Any] {
      return arr.map { Self.convertValue($0) }
    }
    return value
  }

  /// Converts a camelCase string to snake_case.
  private static func camelToSnake(_ input: String) -> String {
    var result = ""
    for (index, char) in input.enumerated() {
      if char.isUppercase && index > 0 {
        result += "_"
      }
      result += char.lowercased()
    }
    return result
  }
}
