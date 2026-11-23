import Flutter
import UIKit
import UserNotifications
import AltcraftCore
import AltcraftPush

/// Flutter plugin entry point for the Altcraft push module.
public class AltcraftPushPlugin: NSObject, FlutterPlugin {
  /// Registers the push method channel with the plugin registrar.
  ///
  /// - Parameter registrar: Flutter plugin registrar used to attach channels to the binary messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    PushInitRegistryBridge.registerContributor()
    let bridge = PushBridge()
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/push", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
  }
}

/// Bridges Flutter platform-channel calls to the native Altcraft push SDK.
///
/// Handles push subscriptions, tokens, provider management, and push event
/// reporting. The bridge guarantees that every method call is completed with
/// either a success value or a FlutterError, preventing Dart-side await calls
/// from hanging.
class PushBridge: NSObject {
  /// Subscription status response type returned by the Push module APIs.
  typealias StatusResponse = ResponseModel.ResponseWithHttpCode<ResponseModel.ResponseWithProfile>

  /// Routes a Flutter method call to the corresponding native push handler.
  ///
  /// - Parameters:
  ///   - call: Method call received from Dart.
  ///   - result: Completion callback that must be called exactly once.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pushSubscribe": handlePushSubscribe(call, result: result)
    case "pushSuspend": handlePushSuspend(call, result: result)
    case "pushUnSubscribe": handlePushUnSubscribe(call, result: result)
    case "unSuspendPushSubscription": handleUnSuspend(result: result)
    case "getStatusOfLatestSubscription": handleGetLatestStatus(result: result)
    case "getStatusOfLatestSubscriptionForProvider": handleGetLatestStatusForProvider(call, result: result)
    case "getStatusForCurrentSubscription": handleGetCurrentStatus(result: result)
    case "getPushToken": handleGetPushToken(result: result)
    case "setPushToken": handleSetPushToken(call, result: result)
    case "forcedTokenUpdate": handleForcedTokenUpdate(result: result)
    case "deleteDeviceToken": handleDeleteDeviceToken(call, result: result)
    case "changePushProviderPriorityList": handleChangePriority(call, result: result)
    case "isAltcraftPush": result(false)
    case "takePush": handleTakePush(call, result: result)
    case "deliveryEvent", "openEvent":
      result(FlutterError(
        code: "UNAVAILABLE_ON_IOS",
        message: "\(call.method) is not available on iOS",
        details: nil
      ))
    case "requestNotificationPermission": handleRequestNotificationPermission(result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS push", details: nil))
    }
  }

  // Sendable wrapper: captures FlutterResult via @unchecked Sendable box
  /// Thread-safe wrapper used to complete Flutter results from native async callbacks.
  final class ResultAction: @unchecked Sendable {
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
  final class ResultBox: @unchecked Sendable {
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
  final class ValueProvider: @unchecked Sendable {
    private let closure: () -> Any?
    /// Creates a value provider.
    ///
    /// - Parameter closure: Closure that returns the value to send to Dart.
    init(_ closure: @escaping () -> Any?) { self.closure = closure }
    /// Returns the stored value.
    func get() -> Any? { closure() }
  }

  /// Wraps arbitrary values captured by asynchronous closures.
  final class SendableBox: @unchecked Sendable {
    private let closure: () -> Any?
    /// Stores a value inside the box.
    ///
    /// - Parameter value: Value to capture.
    init(_ value: Any?) { self.closure = { value } }
    func get() -> Any? { closure() }
  }

  /// Holds an SDK response until an asynchronous native callback completes.
  final class ResponseHolder: @unchecked Sendable {
    nonisolated(unsafe) private var response: StatusResponse?
    /// Stores the latest native response.
    ///
    /// - Parameter r: Native response with HTTP status.
    func set(_ r: StatusResponse?) { self.response = r }
    func dict() -> Any? {
      guard let r = response else { return nil }
      var dict: [String: Any?] = [:]
      dict["http_code"] = r.httpCode as Any?
      if let resp = r.response {
        do {
          let data = try JSONEncoder().encode(resp)
          if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["response"] = PushBridge.toSnakeCase(json)
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

  /// Holds push token data until an asynchronous native callback completes.
  final class TokenHolder: @unchecked Sendable {
    nonisolated(unsafe) private var data: (String, String)?
    /// Stores push provider and token values.
    ///
    /// - Parameter d: Tuple containing provider and token.
    func set(_ d: (String, String)?) { data = d }
    /// Converts the stored native token into a Flutter codec-safe dictionary.
    func dict() -> Any? { data.map { ["provider": $0.0, "token": $0.1] } }
  }

  // MARK: - Handlers

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
    AltcraftSDK.push.subscription.subscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      customFields: jsonCompatible(args["customFields"] as? [String: Any]),
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
    AltcraftSDK.push.subscription.suspend(
      sync: args["sync"] as? Bool ?? true,
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      customFields: jsonCompatible(args["customFields"] as? [String: Any]),
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
    AltcraftSDK.push.subscription.unsubscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      customFields: jsonCompatible(args["customFields"] as? [String: Any]),
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
    AltcraftSDK.push.subscription.unSuspend { (response: StatusResponse?) in
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
    AltcraftSDK.push.subscription.latest { (response: StatusResponse?) in
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
    AltcraftSDK.push.subscription.latestForProvider(
      provider: provider) { (response: StatusResponse?) in
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
    AltcraftSDK.push.subscription.current { (response: StatusResponse?) in
      holder.set(response)
      action.execute()
    }
  }

  /// Reads the currently stored native push token and returns it to Dart.
  ///
  /// - Parameter result: Completion callback returning a token map or `nil`.
  private func handleGetPushToken(result: @escaping FlutterResult) {
    let tokenHolder = TokenHolder()
    let action = ResultAction(result, tokenHolder.dict())
    AltcraftSDK.push.token.getToken { tokenData in
      tokenHolder.set(tokenData.map { ($0.provider, $0.token) })
      action.execute()
    }
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
    AltcraftSDK.push.token.setToken(provider: provider, pushToken: args["token"] as? String)
    result(nil)
  }

  /// Forces push token update through the native SDK.
  ///
  /// - Parameter result: Completion callback resolved after native update callback.
  private func handleForcedTokenUpdate(result: @escaping FlutterResult) {
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.push.token.forcedTokenUpdate { action.execute() }
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
    AltcraftSDK.push.token.deleteToken(provider: provider) { action.execute() }
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
    AltcraftSDK.push.token.changeProviderPriority(priorityList)
    result(nil)
  }

  /// Schedules a local test push built from the supplied payload.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing the push payload.
  ///   - result: Completion callback.
  private func handleTakePush(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let message = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }

    let content = UNMutableNotificationContent()
    content.title = message["_title"] as? String ?? ""
    content.body = message["_body"] as? String ?? ""
    content.sound = .default
    content.categoryIdentifier = "Altcraft"
    content.userInfo = message

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    )

    AltcraftNSE.handleNotificationRequest(request: request) { modifiedContent in
      let finalRequest = UNNotificationRequest(
        identifier: request.identifier,
        content: modifiedContent,
        trigger: request.trigger
      )
      UNUserNotificationCenter.current().add(finalRequest) { error in
        DispatchQueue.main.async {
          if let error {
            result(FlutterError(
              code: "TAKE_PUSH_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          } else {
            result(nil)
          }
        }
      }
    }
  }

  /// Requests notification authorization from the system.
  ///
  /// - Parameter result: Completion callback with the granted flag.
  private func handleRequestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, _ in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }

  // MARK: - Helpers

  /// Converts a Flutter category dictionary into native `CategoryData`.
  ///
  /// - Parameter dict: Category dictionary received from Dart.
  /// - Returns: Native category data model.
  private func toCategoryData(dict: [String: Any]) -> CategoryData {
    CategoryData(name: dict["name"] as? String, title: dict["title"] as? String,
                 steady: dict["steady"] as? Bool, active: dict["active"] as? Bool)
  }

  /// Converts a Flutter dictionary into JSON-compatible `[String: Any]`.
  ///
  /// Preserves native types (String, Bool, Int, Double, Array, Dictionary)
  /// instead of converting everything to String.
  ///
  /// - Parameter dict: Dictionary with arbitrary JSON-like values.
  /// - Returns: JSON-compatible dictionary or `nil`.
  private func jsonCompatible(_ dict: [String: Any]?) -> [String: Any?]? {
    guard let dict else { return nil }
    var result: [String: Any?] = [:]
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
  fileprivate static func toSnakeCase(_ dict: [String: Any]) -> [String: Any] {
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
