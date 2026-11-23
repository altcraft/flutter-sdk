import Foundation
import AltcraftCore

/// Process-wide registry of module initialization contributors.
///
/// Module Flutter plugins (push, in-app) register an Objective-C-visible
/// contributor object when they are attached to the Flutter engine. The core
/// plugin applies all registered contributors right before calling
/// `AltcraftSDK.initialization`, so the core module stays unaware of concrete
/// modules while still producing a single native configuration.
///
/// The class is discovered by module plugins through the Objective-C runtime
/// (`NSClassFromString("AltcraftFlutterInitRegistry")`), mirroring how the
/// native iOS SDK discovers module providers.
@objc(AltcraftFlutterInitRegistry)
final class AltcraftFlutterInitRegistry: NSObject {
  /// Shared registry instance.
  @objc static let shared = AltcraftFlutterInitRegistry()

  /// Returns the shared registry instance (Objective-C runtime entry point).
  @objc class func sharedInstance() -> AltcraftFlutterInitRegistry {
    shared
  }

  private let lock = NSLock()
  private var contributors: [NSObject] = []

  /// Registers a module contributor.
  ///
  /// Registration is idempotent by contributor type, so re-attaching the
  /// Flutter engine does not duplicate module configurations.
  @objc func registerContributor(_ contributor: NSObject) {
    lock.lock()
    defer { lock.unlock() }
    let contributorType = type(of: contributor)
    guard !contributors.contains(where: { type(of: $0) == contributorType }) else {
      return
    }
    contributors.append(contributor)
  }

  /// Applies all registered contributors to the SDK configuration builder.
  ///
  /// Each contributor implements the Objective-C selector
  /// `contributeBuilder:moduleConfigs:` and applies its own module
  /// configuration through the native module extension.
  func applyAll(
    builder: AltcraftConfiguration.Builder,
    moduleConfigs: [String: [String: Any]]
  ) {
    lock.lock()
    let snapshot = contributors
    lock.unlock()

    let selector = NSSelectorFromString("contributeBuilder:moduleConfigs:")
    let boxedConfigs = moduleConfigs as NSDictionary
    for contributor in snapshot {
      guard contributor.responds(to: selector) else { continue }
      _ = contributor.perform(selector, with: builder, with: boxedConfigs)
    }
  }
}
