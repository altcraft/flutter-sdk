## 1.0.0

- Added `InAppConfig` and the `AltcraftConfigBuilder.inAppConfig` extension. In-App options (auto request, placements request interval, max placements) are applied at initialization by the core plugin; defaults match the native SDK (30 minutes, 500 placements).
- In-App view animation extended to the native bridge capabilities: independent `scaleX`/`scaleY`, target (`*To`) values and `rotation`; defaults are now 350 ms and `easeInOut` (`scaleFrom`, 300 ms and `easeOut` are removed).
- `cats` parameters now accept typed `CategoryData` values.
- Native module event catalog exposure (`moduleEvents`).
- Initial release: In-App module (subscriptions, screens, triggers, placements,
  JSON content, view animation).
- In-App handlers implemented for both Android and iOS.
