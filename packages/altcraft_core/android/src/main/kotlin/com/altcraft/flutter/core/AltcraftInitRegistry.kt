package com.altcraft.flutter.core

import androidx.annotation.Keep
import com.altcraft.sdk.config.AltcraftConfiguration

/**
 * Contributes a module configuration to the SDK builder during initialization.
 *
 * Implemented by module Flutter plugins (push, in-app) and registered in
 * [AltcraftInitRegistry]. The core plugin never references concrete modules.
 */
@Keep
fun interface AltcraftInitContributor {
    /**
     * Applies this module's configuration to [builder].
     *
     * @param builder SDK configuration builder shared by all contributors.
     * @param moduleConfigs Module configurations received from Dart, keyed by
     * module identifier (for example `push` or `inapp`).
     */
    fun contribute(
        builder: AltcraftConfiguration.Builder,
        moduleConfigs: Map<String, Map<String, Any?>>
    )
}

/**
 * Process-wide registry of module initialization contributors.
 *
 * Module Flutter plugins register themselves when attached to the Flutter
 * engine; the core plugin applies all registered contributors right before
 * calling `AltcraftSDK.initialization`. This keeps the core module unaware of
 * concrete modules while still producing a single native configuration.
 */
@Keep
object AltcraftInitRegistry {
    private val lock = Any()
    private val contributors = mutableListOf<AltcraftInitContributor>()

    /**
     * Registers a module contributor.
     *
     * Registration is idempotent: a contributor class is registered at most
     * once per process, so re-attaching the Flutter engine does not duplicate
     * module configurations.
     */
    fun register(contributor: AltcraftInitContributor) {
        synchronized(lock) {
            if (contributors.none { it::class == contributor::class }) {
                contributors.add(contributor)
            }
        }
    }

    /**
     * Applies all registered contributors to [builder].
     */
    fun applyAll(
        builder: AltcraftConfiguration.Builder,
        moduleConfigs: Map<String, Map<String, Any?>>
    ) {
        val snapshot = synchronized(lock) { contributors.toList() }
        snapshot.forEach { contributor ->
            try {
                contributor.contribute(builder, moduleConfigs)
            } catch (_: Exception) {
                // A module configuration error must not prevent core
                // initialization or other modules from being configured.
            }
        }
    }
}
