import Flutter
import UIKit
import AltcraftCore
import AltcraftPush
import AltcraftInApp

/// Flutter plugin entry point for the Altcraft umbrella package.
///
/// Registers the umbrella method channel and handles full SDK initialization:
/// the core configuration is assembled together with the configurations of the
/// connected modules (push, in-app) on the native side.
public class AltcraftSdkPlugin: NSObject, FlutterPlugin {
  /// Registers the umbrella method channel with the plugin registrar.
  ///
  /// - Parameter registrar: Flutter plugin registrar used to attach channels to the binary messenger.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let bridge = SdkInitBridge()
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/sdk", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
  }
}

/// Bridges the Flutter initialization call to the native Altcraft SDK.
///
/// Builds the full AltcraftConfiguration, including the push and in-app module
/// configurations, and starts native SDK initialization. The bridge
/// guarantees that the method call is completed with either a success value
/// or a FlutterError, preventing Dart-side await calls from hanging.
class SdkInitBridge: NSObject {
  /// Wraps arbitrary values captured by asynchronous closures.
  final class SendableBox: @unchecked Sendable {
    private let closure: () -> Any?
    /// Stores a value inside the box.
    ///
    /// - Parameter value: Value to capture.
    init(_ value: Any?) { self.closure = { value } }
    func get() -> Any? { closure() }
  }

  /// Routes a Flutter method call to the corresponding handler.
  ///
  /// - Parameters:
  ///   - call: Method call received from Dart.
  ///   - result: Completion callback that must be called exactly once.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize": handleInitialize(call, result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS sdk", details: nil))
    }
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
    let altcraftConfig = AltcraftConfiguration.Builder(
      apiUrl: apiUrl,
      rToken: rToken,
      appInfo: appInfo,
      enableLogging: enableLogging
    )
    .pushConfig(providerPriority: providerList ?? [])
    .inAppConfig(
      inAppAutoRequest: true,
      placementsRequestInterval: .init(value: 900, unit: .seconds),
      maxPlacements: 10
    )
    .build()
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
}
