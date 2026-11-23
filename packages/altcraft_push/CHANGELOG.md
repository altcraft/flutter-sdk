## 1.0.0

- Added `PushConfig` and the `AltcraftConfigBuilder.pushConfig` extension. Push options (provider priority, Android icon, receiver modules, notification channel) are applied at initialization by the core plugin through a shared native registry.
- `cats` parameters now accept typed `CategoryData` values.
- Native module event catalog exposure (`moduleEvents`).
- Initial release: push module (subscriptions, tokens, provider management, push events).
