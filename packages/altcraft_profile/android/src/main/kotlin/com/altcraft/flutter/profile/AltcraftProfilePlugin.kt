package com.altcraft.flutter.profile

import android.content.Context
import android.util.Log
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.profile.profile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin entry point for the Altcraft profile module.
 *
 * Registers the profile method channel.
 */
class AltcraftProfilePlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var bridge: ProfileBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "com.altcraft/profile")
        val instance = ProfileBridge(binding.applicationContext)
        bridge = instance
        methodChannel = channel
        channel.setMethodCallHandler(instance)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        bridge = null
    }
}

/**
 * Bridges Flutter platform-channel calls to the native Altcraft profile SDK.
 *
 * Handles profile field updates.
 */
class ProfileBridge(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "updateProfileFields" -> handleUpdateProfileFields(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- updateProfileFields ----

    private fun handleUpdateProfileFields(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val skipTriggers = args["skipTriggers"] as? Boolean
            AltcraftSDK.profile.updateProfileFields(context, profileFields, skipTriggers)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_profile_bridge", "updateProfileFields failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }
}
