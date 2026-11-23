@file:Suppress("UNCHECKED_CAST")

package com.altcraft.flutter.target

import android.content.Context
import android.util.Log
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.target.target
import com.altcraft.sdk.target.data.models.TargetModels
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray

/**
 * Flutter plugin entry point for the Altcraft target module.
 *
 * Registers the target method channel.
 */
class AltcraftTargetPlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var bridge: TargetBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "com.altcraft/target")
        val instance = TargetBridge(binding.applicationContext)
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
 * Bridges Flutter platform-channel calls to the native Altcraft target SDK.
 *
 * Handles mobile event tracking.
 */
class TargetBridge(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "sendTarget" -> handleSendTarget(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- sendTarget ----

    private fun handleSendTarget(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val sid = args["sid"] as? String ?: run {
                result.error("ERR", "sid is missing", null)
                return
            }
            if (sid.isBlank()) {
                result.error("ERR", "sid must not be empty", null)
                return
            }
            val eventName = args["eventName"] as? String ?: run {
                result.error("ERR", "eventName is missing", null)
                return
            }
            if (eventName.isBlank()) {
                result.error("ERR", "eventName must not be empty", null)
                return
            }
            val sendMessageId = args["sendMessageId"] as? String
            val payload = args["payload"] as? Map<String, Any?>
            val matching = args["matching"] as? Map<String, Any?>
            val matchingType = args["matchingType"] as? String
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val subscriptionMap = args["subscription"] as? Map<String, Any?>
            val utmMap = args["utm"] as? Map<String, Any?>

            val utm = utmMap?.let {
                TargetModels.UTM(
                    campaign = it["campaign"] as? String,
                    content = it["content"] as? String,
                    keyword = it["keyword"] as? String,
                    medium = it["medium"] as? String,
                    source = it["source"] as? String,
                    temp = it["temp"] as? String
                )
            }

            val subscription = subscriptionMap?.let {
                mapToSubscription(it)
            }

            AltcraftSDK.target.sendTarget(
                context = context,
                sid = sid,
                eventName = eventName,
                sendMessageId = sendMessageId,
                payload = payload,
                matching = matching,
                matchingType = matchingType,
                profileFields = profileFields,
                subscription = subscription,
                utm = utm
            )
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_target_bridge", "sendTarget failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- Helpers ----

    /**
     * Creates an SDK subscription model from a Flutter map.
     *
     * Supports email, SMS, push, and cc_data subscription payloads. Returns `null` when
     * the channel is unknown or required fields for the selected channel are missing.
     */
    private fun mapToSubscription(
        map: Map<String, Any?>
    ): TargetModels.SubscriptionModel.Subscription? {
        val channel = (map["channel"] as? String) ?: (map["type"] as? String) ?: return null
        val resourceId = (map["resourceId"] as? Number)?.toInt()
            ?: (map["resource_id"] as? Number)?.toInt() ?: return null
        val status = map["status"] as? String
        val priority = (map["priority"] as? Number)?.toInt()
        val customFields = map["customFields"] as? Map<String, Any?>
            ?: map["custom_fields"] as? Map<String, Any?>
        val cats = map["cats"] as? List<String>

        return when (channel) {
            "email" -> {
                val email = map["email"] as? String ?: return null
                TargetModels.SubscriptionModel.EmailSubscription(
                    resourceId = resourceId,
                    email = email,
                    status = status,
                    priority = priority,
                    customFields = customFields,
                    cats = cats
                )
            }

            "sms" -> {
                val phone = map["phone"] as? String ?: return null
                TargetModels.SubscriptionModel.SmsSubscription(
                    resourceId = resourceId,
                    phone = phone,
                    status = status,
                    priority = priority,
                    customFields = customFields,
                    cats = cats
                )
            }

            "push" -> {
                val provider = map["provider"] as? String ?: return null
                val subscriptionId = (map["subscriptionId"] as? String)
                    ?: (map["subscription_id"] as? String) ?: return null
                TargetModels.SubscriptionModel.PushSubscription(
                    resourceId = resourceId,
                    provider = provider,
                    subscriptionId = subscriptionId,
                    status = status,
                    priority = priority,
                    customFields = customFields,
                    cats = cats
                )
            }

            "cc_data" -> {
                val ccChannel = (map["ccChannel"] as? String)
                    ?: (map["cc_channel"] as? String) ?: return null
                val ccDataRaw = (map["ccData"] as? Map<String, Any?>)
                    ?: (map["cc_data"] as? Map<String, Any?>) ?: return null
                val ccData = mapToJsonObject(ccDataRaw)
                TargetModels.SubscriptionModel.CcDataSubscription(
                    resourceId = resourceId,
                    channel = ccChannel,
                    ccData = ccData,
                    status = status,
                    priority = priority,
                    customFields = customFields,
                    cats = cats
                )
            }

            else -> null
        }
    }

    /**
     * Converts a Map to a JsonObject for use with CcDataSubscription.
     */
    private fun mapToJsonObject(map: Map<String, Any?>): JsonObject {
        return buildJsonObject {
            for ((key, value) in map) {
                put(key, valueToJsonElement(value))
            }
        }
    }

    private fun valueToJsonElement(value: Any?): JsonElement {
        return when (value) {
            null -> JsonNull
            is String -> JsonPrimitive(value)
            is Boolean -> JsonPrimitive(value)
            is Number -> JsonPrimitive(value.toDouble())
            is Map<*, *> -> mapToJsonObject(value.mapKeys { it.key.toString() })
            is List<*> -> buildJsonArray {
                for (item in value) {
                    add(valueToJsonElement(item))
                }
            }
            else -> JsonPrimitive(value.toString())
        }
    }
}
