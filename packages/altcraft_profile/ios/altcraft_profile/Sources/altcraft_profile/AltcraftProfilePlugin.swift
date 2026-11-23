import Flutter
import UIKit
import AltcraftCore
import AltcraftProfile

/// Flutter plugin entry point for the Altcraft profile module.
public class AltcraftProfilePlugin: NSObject, FlutterPlugin {
  /// Registers the profile method channel with the plugin registrar.
  ///
  /// - Parameter registrar: Flutter plugin registrar used to attach channels to the binary messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let bridge = ProfileBridge()
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/profile", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
  }
}

/// Bridges Flutter platform-channel calls to the native Altcraft profile SDK.
///
/// Handles profile field updates.
class ProfileBridge: NSObject {
  /// Routes a Flutter method call to the corresponding native profile handler.
  ///
  /// - Parameters:
  ///   - call: Method call received from Dart.
  ///   - result: Completion callback that must be called exactly once.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateProfileFields": handleUpdateProfileFields(call, result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS profile", details: nil))
    }
  }

  // MARK: - Handlers

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
    AltcraftSDK.profile.updateProfileFields(
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      skipTriggers: args["skipTriggers"] as? Bool)
    result(nil)
  }

  // MARK: - Helpers

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
