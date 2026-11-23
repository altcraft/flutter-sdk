package com.altcraft.flutter

import android.content.Context
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.config.AltcraftConfiguration
import com.altcraft.sdk.data.models.CoreModels.PropertyModel.AppInfo
import com.altcraft.sdk.inapp.config.inAppConfig
import com.altcraft.sdk.push.config.pushConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.time.Duration.Companion.minutes

/**
 * Flutter plugin entry point for the Altcraft umbrella package.
 *
 * Registers the umbrella method channel and handles full SDK initialization:
 * the core configuration is assembled together with the configurations of the
 * connected modules (push, in-app) on the native side.
 */
class AltcraftSdkPlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var bridge: SdkInitBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "com.altcraft/sdk")
        val instance = SdkInitBridge(binding.applicationContext)
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
 * Bridges the Flutter initialization call to the native Altcraft SDK.
 *
 * Builds the full AltcraftConfiguration, including the push and in-app module
 * configurations, and starts native SDK initialization.
 */
class SdkInitBridge(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> handleInitialize(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- initialize ----

    private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
        val config = call.arguments as? Map<String, Any> ?: run {
            result.error("ALTCRAFT_INIT_INVALID_CONFIG", "config is null", null)
            return
        }

        val apiUrl = config["apiUrl"] as? String ?: run {
            result.error("ALTCRAFT_INIT_INVALID_CONFIG", "apiUrl is missing", null)
            return
        }

        val appInfoMap = config["appInfo"] as? Map<String, Any>
        val appInfo = appInfoMap?.let {
            AppInfo(
                appID = it["appID"] as? String ?: "",
                appIID = it["appIID"] as? String ?: "",
                appVer = it["appVer"] as? String ?: "1.0.0"
            )
        }

        val providerList =
            (config["providerPriorityList"] as? List<*>)?.map { it.toString() }
        val enableLogging = config["enableLogging"] as? Boolean
        val rToken = config["rToken"] as? String
        val icon = when (val raw = config["android_icon"]) {
            is Number -> raw.toInt()
            is String -> context.resources.getIdentifier(
                raw, "drawable", context.packageName
            ).takeIf { it != 0 }
            else -> null
        }
        val pushReceiverModules =
            (config["android_pushReceiverModules"] as? List<*>)?.map { it.toString() }
        val pushChannelName = config["android_pushChannelName"] as? String
        val pushChannelDescription = config["android_pushChannelDescription"] as? String

        val altcraftConfig = AltcraftConfiguration.Builder(
            apiUrl = apiUrl,
            rToken = rToken,
            appInfo = appInfo,
            enableLogging = enableLogging
        ).pushConfig(
            icon = icon,
            providerPriority = providerList ?: emptyList(),
            pushReceiverModules = pushReceiverModules ?: emptyList(),
            pushChannelName = pushChannelName,
            pushChannelDescription = pushChannelDescription
        ).inAppConfig(
            inAppAutoRequest = true,
            placementsRequestInterval = 15.minutes,
            maxPlacements = 10
        ).build()

        AltcraftSDK.initialization(context, altcraftConfig) { res ->
            try {
                if (res.isSuccess) {
                    result.success(null)
                } else {
                    result.error("ALTCRAFT_INIT_ERROR", res.exceptionOrNull()?.message, null)
                }
            } catch (e: Exception) {
                result.error("SDK_ERROR", e.message, null)
            }
        }
    }
}
