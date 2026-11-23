import Flutter
import UIKit
import AltcraftCore
import AltcraftTarget

/// Flutter plugin entry point for the Altcraft target module.
public class AltcraftTargetPlugin: NSObject, FlutterPlugin {
  /// Registers the target method channel with the plugin registrar.
  ///
  /// - Parameter registrar: Flutter plugin registrar used to attach channels to the binary messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let bridge = TargetBridge()
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/target", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
  }
}

/// Bridges Flutter platform-channel calls to the native Altcraft target SDK.
///
/// Handles mobile event tracking.
class TargetBridge: NSObject {
  /// Routes a Flutter method call to the corresponding native target handler.
  ///
  /// - Parameters:
  ///   - call: Method call received from Dart.
  ///   - result: Completion callback that must be called exactly once.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "sendTarget": handleSendTarget(call, result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS target", details: nil))
    }
  }

  // MARK: - Handlers

  /// Sends a mobile event through the native Altcraft SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing event, matching, profile, subscription, and UTM data.
  ///   - result: Completion callback resolved when the event is accepted by the native SDK.
  private func handleSendTarget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    AltcraftSDK.target.sendTarget(
      sid: sid, eventName: eventName,
      sendMessageId: args["sendMessageId"] as? String,
      payload: jsonCompatible(args["payload"] as? [String: Any]),
      matching: jsonCompatible(args["matching"] as? [String: Any]),
      matchingType: args["matchingType"] as? String,
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      subscription: subscription, utm: utm)
    result(nil)
  }

  // MARK: - Helpers

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
}
