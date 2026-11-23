## 1.0.0

- `AltcraftConfig` carries only core parameters; push-specific fields (`providerPriorityList`, `icon`, `iconName`, `pushReceiverModules`, `pushChannelName`, `pushChannelDescription`) were removed.
- Added `AltcraftConfigBuilder` with a generic module configuration map. Module packages contribute their options through builder extensions (`pushConfig`, `inAppConfig`); the core module forwards the map to the native SDK without depending on concrete modules.
- `AltcraftConfig.moduleConfigs` is serialized over the core method channel and applied by module contributors during native initialization.
- `Subscription.cats` is typed as `List<String>?`, matching the native and React Native models.
- Native module event catalog exposure (`moduleEvents`).
- Initial release: core module (initialization, events, authentication, data management).
