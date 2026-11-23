import Foundation
import AltcraftCore
import AltcraftInApp

/// Registers the In-App configuration with the core Flutter plugin's
/// initialization registry.
///
/// The registry lives in the core plugin and is discovered through the
/// Objective-C runtime, mirroring how the native iOS SDK discovers module
/// providers. Core remains independent of the In-App module.
enum InAppInitRegistryBridge {
  /// Registers the In-App contributor if the core registry is linked.
  static func registerContributor() {
    guard let registryClass = NSClassFromString("AltcraftFlutterInitRegistry") else {
      return
    }
    let sharedSelector = NSSelectorFromString("sharedInstance")
    guard let shared = (registryClass as AnyObject)
      .perform(sharedSelector)?
      .takeUnretainedValue() as? NSObject else {
      return
    }
    let registerSelector = NSSelectorFromString("registerContributor:")
    guard shared.responds(to: registerSelector) else { return }
    _ = shared.perform(registerSelector, with: AltcraftFlutterInAppContributor())
  }
}

/// Applies the In-App module configuration to the shared SDK builder.
@objc(AltcraftFlutterInAppContributor)
final class AltcraftFlutterInAppContributor: NSObject {
  /// Applies the In-App configuration through the native In-App module
  /// extension. When no options were provided, native defaults are applied
  /// explicitly.
  @objc(contributeBuilder:moduleConfigs:)
  func contribute(
    builder: AltcraftConfiguration.Builder,
    moduleConfigs: NSDictionary
  ) {
    let config = moduleConfigs["inapp"] as? [String: Any] ?? [:]
    let autoRequest = config["inAppAutoRequest"] as? Bool ?? true
    let intervalMs =
      (config["placementsRequestIntervalMs"] as? NSNumber)?.doubleValue
      ?? 1_800_000
    let maxPlacements =
      (config["maxPlacements"] as? NSNumber)?.intValue ?? 500
    builder.inAppConfig(
      inAppAutoRequest: autoRequest,
      placementsRequestInterval: Measurement(
        value: intervalMs,
        unit: UnitDuration.milliseconds
      ),
      maxPlacements: maxPlacements
    )
  }
}
