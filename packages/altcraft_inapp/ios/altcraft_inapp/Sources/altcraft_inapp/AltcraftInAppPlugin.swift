import Flutter
import UIKit
import AltcraftCore
import AltcraftInApp

/// Flutter plugin entry point for the Altcraft In-App module.
public class AltcraftInAppPlugin: NSObject, FlutterPlugin {
  /// Registers the In-App method channel with the plugin registrar.
  ///
  /// - Parameter registrar: Flutter plugin registrar used to attach channels to the binary messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    InAppInitRegistryBridge.registerContributor()
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/inapp", binaryMessenger: registrar.messenger())
    let bridge = InAppBridge(methodChannel: methodChannel)
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
  }
}

/// Bridges Flutter platform-channel calls to the native Altcraft In-App SDK.
///
/// Handles In-App subscriptions, screen tracking, triggers, and placement
/// requests. The bridge guarantees that every method call is completed with
/// either a success value or a FlutterError, preventing Dart-side await calls
/// from hanging.
class InAppBridge: NSObject {
  /// Method channel used to deliver native callbacks to Dart.
  private let methodChannel: FlutterMethodChannel

  /// Creates a bridge bound to the plugin method channel.
  ///
  /// - Parameter methodChannel: Channel used for incoming calls and callbacks.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
    super.init()
  }

  /// Routes a Flutter method call to the corresponding native In-App handler.
  ///
  /// - Parameters:
  ///   - call: Method call received from Dart.
  ///   - result: Completion callback that must be called exactly once.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "inAppSubscribe": handleInAppSubscribe(call, result: result)
    case "inAppUnsubscribe": handleInAppUnsubscribe(call, result: result)
    case "setScreen": handleSetScreen(call, result: result)
    case "trigger": handleTrigger(call, result: result)
    case "getPlacements": handleGetPlacements(result: result)
    case "setAnimations": handleSetAnimations(call, result: result)
    case "jsonContentSubscribe": handleJsonContentSubscribe(result: result)
    case "jsonContentUnsubscribe": handleJsonContentUnsubscribe(result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS inapp", details: nil))
    }
  }

  // MARK: - Handlers

  /// Subscribes to In-App notifications through the native SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing subscription options.
  ///   - result: Completion callback resolved when the command is accepted by the native SDK.
  private func handleInAppSubscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    AltcraftSDK.inApp.subscription.subscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      customFields: jsonCompatible(args["customFields"] as? [String: Any]),
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
    result(nil)
  }

  /// Unsubscribes from In-App notifications through the native SDK.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing unsubscribe options.
  ///   - result: Completion callback resolved when the command is accepted by the native SDK.
  private func handleInAppUnsubscribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    AltcraftSDK.inApp.subscription.unsubscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: jsonCompatible(args["profileFields"] as? [String: Any]),
      customFields: jsonCompatible(args["customFields"] as? [String: Any]),
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
    result(nil)
  }

  /// Sets the current screen for In-App placement matching.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `screen`.
  ///   - result: Completion callback.
  private func handleSetScreen(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let screen = args["screen"] as? String else {
      result(FlutterError(code: "ERR", message: "screen missing", details: nil))
      return
    }
    AltcraftSDK.inApp.setScreen(screen: screen)
    result(nil)
  }

  /// Fires an In-App trigger by name.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing `name`.
  ///   - result: Completion callback.
  private func handleTrigger(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let name = args["name"] as? String else {
      result(FlutterError(code: "ERR", message: "name missing", details: nil))
      return
    }
    AltcraftSDK.inApp.trigger(name: name)
    result(nil)
  }

  /// Requests available In-App placements from the server.
  ///
  /// - Parameter result: Completion callback.
  private func handleGetPlacements(result: @escaping FlutterResult) {
    AltcraftSDK.inApp.getPlacements()
    result(nil)
  }

  /// Replaces the in-app view animation listener with one built from the
  /// received animation specs.
  ///
  /// Specs are matched by campaign identifier; a spec without an identifier
  /// acts as the fallback for any campaign. Specs without a match leave the
  /// view untouched.
  ///
  /// - Parameters:
  ///   - call: Flutter method call containing the animation specs.
  ///   - result: Completion callback.
  private func handleSetAnimations(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let raw = args?["animations"] as? [[String: Any]] ?? []
    let specs = raw.map { AnimationSpec(dict: $0) }

    AltcraftSDK.inApp.animation { animator in
      guard let spec = specs.first(where: { $0.companyId != nil && $0.companyId == animator.companyId })
        ?? specs.first(where: { $0.companyId == nil }),
        spec.hasAnimatedProperties else {
        return
      }

      animator.prepare { view in
        spec.prepare(view)
      }

      animator.animate(
        duration: spec.duration,
        delay: spec.delay,
        options: spec.curveOption,
        animations: { view in
          spec.animate(view)
        },
        completion: nil
      )
    }
    result(nil)
  }

  /// Subscribes to JSON content of JSON-content in-app campaigns.
  ///
  /// The native SDK keeps a single subscriber. Content may be delivered from a
  /// background queue, so the channel call is dispatched to the main queue.
  ///
  /// - Parameter result: Completion callback.
  private func handleJsonContentSubscribe(result: @escaping FlutterResult) {
    AltcraftSDK.inApp.jsonContent.subscribe { [weak self] json in
      DispatchQueue.main.async {
        self?.methodChannel.invokeMethod("onJsonContent", arguments: json)
      }
    }
    result(nil)
  }

  /// Removes the JSON content subscriber.
  ///
  /// - Parameter result: Completion callback.
  private func handleJsonContentUnsubscribe(result: @escaping FlutterResult) {
    AltcraftSDK.inApp.jsonContent.unsubscribe()
    result(nil)
  }

  // MARK: - Helpers

  /// Parsed animation spec received from Flutter.
  ///
  /// Neutral values are `alpha` 1, `translate` 0, `scale` 1 and `rotation` 0.
  /// A missing value keeps the neutral state.
  private struct AnimationSpec {
    let companyId: Int?
    let duration: TimeInterval
    let delay: TimeInterval
    let easing: String
    let alphaFrom: CGFloat?
    let alphaTo: CGFloat?
    let translateXFrom: CGFloat?
    let translateXTo: CGFloat?
    let translateYFrom: CGFloat?
    let translateYTo: CGFloat?
    let scaleXFrom: CGFloat?
    let scaleXTo: CGFloat?
    let scaleYFrom: CGFloat?
    let scaleYTo: CGFloat?
    let rotationFrom: CGFloat?
    let rotationTo: CGFloat?

    /// Creates a spec from a Flutter dictionary.
    init(dict: [String: Any]) {
      companyId = (dict["companyId"] as? NSNumber)?.intValue
      duration = ((dict["durationMs"] as? NSNumber)?.doubleValue ?? 350.0) / 1000.0
      delay = ((dict["delayMs"] as? NSNumber)?.doubleValue ?? 0.0) / 1000.0
      easing = dict["easing"] as? String ?? "easeInOut"
      alphaFrom = AnimationSpec.cgFloat(dict, "alphaFrom")
      alphaTo = AnimationSpec.cgFloat(dict, "alphaTo")
      translateXFrom = AnimationSpec.cgFloat(dict, "translateXFrom")
      translateXTo = AnimationSpec.cgFloat(dict, "translateXTo")
      translateYFrom = AnimationSpec.cgFloat(dict, "translateYFrom")
      translateYTo = AnimationSpec.cgFloat(dict, "translateYTo")
      scaleXFrom = AnimationSpec.cgFloat(dict, "scaleXFrom")
      scaleXTo = AnimationSpec.cgFloat(dict, "scaleXTo")
      scaleYFrom = AnimationSpec.cgFloat(dict, "scaleYFrom")
      scaleYTo = AnimationSpec.cgFloat(dict, "scaleYTo")
      rotationFrom = AnimationSpec.cgFloat(dict, "rotationFrom")
      rotationTo = AnimationSpec.cgFloat(dict, "rotationTo")
    }

    /// Whether the spec changes opacity or the transform matrix.
    var hasAnimatedProperties: Bool {
      alphaFrom != nil || alphaTo != nil || hasTransform
    }

    /// Whether the spec animates any transform channel.
    private var hasTransform: Bool {
      translateXFrom != nil || translateXTo != nil ||
        translateYFrom != nil || translateYTo != nil ||
        scaleXFrom != nil || scaleXTo != nil ||
        scaleYFrom != nil || scaleYTo != nil ||
        rotationFrom != nil || rotationTo != nil
    }

    /// Applies the starting state without running an animation.
    @MainActor
    func prepare(_ view: UIView) {
      if alphaFrom != nil || alphaTo != nil {
        view.alpha = alphaFrom ?? 1
      }
      if hasTransform {
        view.transform = transform(from: true)
      }
    }

    /// Applies the target state; must run inside a `UIView` animation block.
    @MainActor
    func animate(_ view: UIView) {
      if alphaFrom != nil || alphaTo != nil {
        view.alpha = alphaTo ?? 1
      }
      if hasTransform {
        view.transform = transform(from: false)
      }
    }

    /// Builds the transform matrix from either the starting or the target values.
    private func transform(from: Bool) -> CGAffineTransform {
      var transform = CGAffineTransform(
        translationX: from ? translateXFrom ?? 0 : translateXTo ?? 0,
        y: from ? translateYFrom ?? 0 : translateYTo ?? 0
      )
      transform = transform.scaledBy(
        x: from ? scaleXFrom ?? 1 : scaleXTo ?? 1,
        y: from ? scaleYFrom ?? 1 : scaleYTo ?? 1
      )
      let rotation = from ? rotationFrom ?? 0 : rotationTo ?? 0
      transform = transform.rotated(by: rotation * .pi / 180)
      return transform
    }

    /// Maps the easing identifier to UIKit animation options.
    var curveOption: UIView.AnimationOptions {
      switch easing {
      case "linear": return .curveLinear
      case "easeIn": return .curveEaseIn
      case "easeInOut": return .curveEaseInOut
      default: return .curveEaseOut
      }
    }

    /// Reads an optional number from a Flutter dictionary.
    private static func cgFloat(_ dict: [String: Any], _ key: String) -> CGFloat? {
      guard let number = dict[key] as? NSNumber else { return nil }
      return CGFloat(number.doubleValue)
    }
  }

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
}
