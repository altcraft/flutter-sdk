import Foundation
import AltcraftCore
import AltcraftPush

/// Registers the push configuration with the core Flutter plugin's
/// initialization registry.
///
/// The registry lives in the core plugin and is discovered through the
/// Objective-C runtime, mirroring how the native iOS SDK discovers module
/// providers. Core remains independent of the push module.
enum PushInitRegistryBridge {
  /// Registers the push contributor if the core registry is linked.
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
    _ = shared.perform(registerSelector, with: AltcraftFlutterPushContributor())
  }
}

/// Applies the push module configuration to the shared SDK builder.
@objc(AltcraftFlutterPushContributor)
final class AltcraftFlutterPushContributor: NSObject {
  /// Applies the push configuration through the native push module extension.
  ///
  /// The contributor always adds a push configuration (with native defaults
  /// when no options were provided) so the native push module is registered.
  @objc(contributeBuilder:moduleConfigs:)
  func contribute(
    builder: AltcraftConfiguration.Builder,
    moduleConfigs: NSDictionary
  ) {
    let config = moduleConfigs["push"] as? [String: Any] ?? [:]
    let providers = (config["providerPriority"] as? [Any])?
      .compactMap { $0 as? String } ?? []
    builder.pushConfig(providerPriority: providers)
  }
}
