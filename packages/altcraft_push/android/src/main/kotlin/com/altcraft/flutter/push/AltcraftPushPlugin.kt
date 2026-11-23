@file:Suppress("UNCHECKED_CAST")

package com.altcraft.flutter.push

import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.altcraft.flutter.core.AltcraftInitRegistry
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.data.models.CoreModels.ProfileModel.CategoryData
import com.altcraft.sdk.data.models.CoreModels.ProfileModel.ProfileData
import com.altcraft.sdk.data.models.CoreModels.ResponseModel.ResponseWithHttpCode
import com.altcraft.sdk.data.models.CoreModels.ResponseModel.ResponseWithProfile
import com.altcraft.sdk.push.push
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Flutter plugin entry point for the Altcraft push module.
 *
 * Registers the push method channel and forwards Android activity lifecycle
 * callbacks when the plugin is attached to an Activity.
 */
class AltcraftPushPlugin : FlutterPlugin, ActivityAware {
    private var methodChannel: MethodChannel? = null
    private var bridge: PushBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "com.altcraft/push")
        val instance = PushBridge(binding.applicationContext)
        bridge = instance
        methodChannel = channel
        channel.setMethodCallHandler(instance)

        // Contribute the push configuration to the shared SDK builder used by
        // the core plugin during initialization.
        AltcraftInitRegistry.register(
            PushInitContributor(binding.applicationContext)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        bridge?.dispose()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        bridge = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        bridge?.onActivityAttached(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        bridge?.onActivityDetached()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        bridge?.onActivityAttached(binding)
    }

    override fun onDetachedFromActivity() {
        bridge?.onActivityDetached()
    }
}

/**
 * Bridges Flutter platform-channel calls to the native Altcraft push SDK.
 *
 * Handles push subscriptions, tokens, provider management, notification
 * permission requests, and push event reporting.
 */
class PushBridge(
    private val context: android.content.Context,
) : MethodChannel.MethodCallHandler {
    private val pluginJob = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.IO + pluginJob)
    private var activity: Activity? = null
    private val notificationPermissionRequestCode = 1001
    private var permissionResultCallback: ((Boolean) -> Unit)? = null
    private var permissionListener: PluginRegistry.RequestPermissionsResultListener? = null

    /**
     * Stores the current Activity and registers a permission result listener.
     */
    fun onActivityAttached(binding: ActivityPluginBinding) {
        activity = binding.activity
        permissionListener =
            PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
                if (requestCode == notificationPermissionRequestCode) {
                    val granted =
                        grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                    permissionResultCallback?.invoke(granted)
                    permissionResultCallback = null
                    true
                } else {
                    false
                }
            }
        permissionListener?.let { binding.addRequestPermissionsResultListener(it) }
    }

    /**
     * Clears the current Activity reference and resolves any pending permission request as denied.
     */
    fun onActivityDetached() {
        permissionListener = null
        activity = null
        permissionResultCallback?.invoke(false)
        permissionResultCallback = null
    }

    /**
     * Full cleanup called when the plugin is detached from the Flutter engine.
     */
    fun dispose() {
        pluginJob.cancel()
        permissionResultCallback?.invoke(false)
        permissionResultCallback = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "pushSubscribe" -> handlePushSubscribe(call, result)
                "pushSuspend" -> handlePushSuspend(call, result)
                "pushUnSubscribe" -> handlePushUnSubscribe(call, result)
                "unSuspendPushSubscription" -> handleUnSuspend(result)
                "getStatusOfLatestSubscription" -> handleGetLatestStatus(result)
                "getStatusOfLatestSubscriptionForProvider" -> handleGetLatestStatusForProvider(
                    call,
                    result
                )

                "getStatusForCurrentSubscription" -> handleGetCurrentStatus(result)
                "getPushToken" -> handleGetPushToken(result)
                "setPushToken" -> handleSetPushToken(call, result)
                "forcedTokenUpdate" -> handleForcedTokenUpdate(result)
                "deleteDeviceToken" -> handleDeleteDeviceToken(call, result)
                "changePushProviderPriorityList" -> handleChangePriority(call, result)
                "isAltcraftPush" -> handleIsAltcraftPush(call, result)
                "takePush" -> handleTakePush(call, result)
                "deliveryEvent" -> handleDeliveryEvent(call, result)
                "openEvent" -> handleOpenEvent(call, result)
                "requestNotificationPermission" -> handleRequestPermission(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- pushSubscribe ----

    private fun handlePushSubscribe(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val sync = (args["sync"] as? Boolean) != false
            val replace = args["replace"] as? Boolean
            val skipTriggers = args["skipTriggers"] as? Boolean
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val customFields = args["customFields"] as? Map<String, Any?>
            val cats = (args["cats"] as? List<Map<String, Any?>>)?.map { mapToCategoryData(it) }

            AltcraftSDK.push.subscription.subscribe(
                context = context,
                sync = sync,
                profileFields = profileFields,
                customFields = customFields,
                cats = cats,
                replace = replace,
                skipTriggers = skipTriggers
            )
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_push_bridge", "pushSubscribe failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- pushSuspend ----

    private fun handlePushSuspend(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val sync = (args["sync"] as? Boolean) != false
            val replace = args["replace"] as? Boolean
            val skipTriggers = args["skipTriggers"] as? Boolean
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val customFields = args["customFields"] as? Map<String, Any?>
            val cats = (args["cats"] as? List<Map<String, Any?>>)?.map { mapToCategoryData(it) }

            AltcraftSDK.push.subscription.suspend(
                context = context,
                sync = sync,
                profileFields = profileFields,
                customFields = customFields,
                cats = cats,
                replace = replace,
                skipTriggers = skipTriggers
            )
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_push_bridge", "pushSuspend failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- pushUnSubscribe ----

    private fun handlePushUnSubscribe(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val sync = (args["sync"] as? Boolean) != false
            val replace = args["replace"] as? Boolean
            val skipTriggers = args["skipTriggers"] as? Boolean
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val customFields = args["customFields"] as? Map<String, Any?>
            val cats = (args["cats"] as? List<Map<String, Any?>>)?.map { mapToCategoryData(it) }

            AltcraftSDK.push.subscription.unsubscribe(
                context = context,
                sync = sync,
                profileFields = profileFields,
                customFields = customFields,
                cats = cats,
                replace = replace,
                skipTriggers = skipTriggers
            )
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_push_bridge", "pushUnSubscribe failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- unSuspendPushSubscription ----

    private fun handleUnSuspend(result: MethodChannel.Result) {
        scope.launch {
            try {
                val response =
                    AltcraftSDK.push.subscription.unSuspend(context)
                withContext(Dispatchers.Main) {
                    result.success(responseToMap(response))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- getStatusOfLatestSubscription ----

    private fun handleGetLatestStatus(result: MethodChannel.Result) {
        scope.launch {
            try {
                val response =
                    AltcraftSDK.push.subscription.status.latest(context)
                withContext(Dispatchers.Main) {
                    result.success(responseToMap(response))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- getStatusOfLatestSubscriptionForProvider ----

    private fun handleGetLatestStatusForProvider(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any> ?: run { result.success(null); return }
        val provider = args["provider"] as? String
        scope.launch {
            try {
                val response =
                    AltcraftSDK.push.subscription.status.latestForProvider(
                        context,
                        provider
                    )
                withContext(Dispatchers.Main) {
                    result.success(responseToMap(response))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- getStatusForCurrentSubscription ----

    private fun handleGetCurrentStatus(result: MethodChannel.Result) {
        scope.launch {
            try {
                val response =
                    AltcraftSDK.push.subscription.status.current(context)
                withContext(Dispatchers.Main) {
                    result.success(responseToMap(response))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- getPushToken ----

    private fun handleGetPushToken(result: MethodChannel.Result) {
        scope.launch {
            try {
                val tokenData = AltcraftSDK.push.token.getToken(context)
                withContext(Dispatchers.Main) {
                    tokenData ?: run {
                        result.success(null)
                        return@withContext
                    }
                    result.success(
                        mapOf(
                            "provider" to tokenData.provider,
                            "token" to tokenData.token
                        )
                    )
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- setPushToken ----

    private fun handleSetPushToken(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val provider = args["provider"] as? String ?: run {
                result.error("ERR", "provider is missing", null)
                return
            }
            val token = args["token"] as? String
            scope.launch {
                try {
                    AltcraftSDK.push.token.setToken(context, provider, token)
                    withContext(Dispatchers.Main) { result.success(null) }
                } catch (e: Exception) {
                    Log.e("altcraft_push_bridge", "setPushToken failed: ${e.message}")
                    withContext(Dispatchers.Main) {
                        result.error("SDK_ERROR", e.message, null)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("altcraft_push_bridge", "setPushToken failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- forcedTokenUpdate ----

    private fun handleForcedTokenUpdate(result: MethodChannel.Result) {
        scope.launch {
            try {
                AltcraftSDK.push.token.forcedTokenUpdate(context)
                withContext(Dispatchers.Main) { result.success(null) }
            } catch (e: Exception) {
                Log.e(
                    "altcraft_push_bridge",
                    "forcedTokenUpdate failed: ${e.message}"
                )
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- deleteDeviceToken ----

    private fun handleDeleteDeviceToken(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any> ?: run {
            result.error("ERR", "args is null", null)
            return
        }
        val provider = args["provider"] as? String ?: run {
            result.error("ERR", "provider is missing", null)
            return
        }
        scope.launch {
            try {
                AltcraftSDK.push.token.deleteToken(context, provider)
                withContext(Dispatchers.Main) { result.success(null) }
            } catch (e: Exception) {
                Log.e(
                    "altcraft_push_bridge",
                    "deleteDeviceToken failed: ${e.message}"
                )
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- changePushProviderPriorityList ----

    private fun handleChangePriority(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any> ?: run {
            result.error("ERR", "args is null", null)
            return
        }
        val priorityList = (args["priorityList"] as? List<*>)?.map { it.toString() } ?: emptyList()
        scope.launch {
            try {
                AltcraftSDK.push.token.changeProviderPriority(context, priorityList)
                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- isAltcraftPush ----

    private fun handleIsAltcraftPush(call: MethodCall, result: MethodChannel.Result) {
        try {
            val message = safeStringMap(call.arguments as? Map<*, *>)
            val isAlt = AltcraftSDK.push.receiver.isAltcraftPush(message)
            result.success(isAlt)
        } catch (e: Exception) {
            Log.e("altcraft_push_bridge", "isAltcraftPush failed: ${e.message}")
            result.success(false)
        }
    }

    // ---- takePush ----

    private fun handleTakePush(call: MethodCall, result: MethodChannel.Result) {
        try {
            val message = safeStringMap(call.arguments as? Map<*, *>)
            AltcraftSDK.push.receiver.takePush(context, message)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_push_bridge", "takePush failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- deliveryEvent ----

    private fun handleDeliveryEvent(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any> ?: run {
            result.error("ERR", "args is null", null)
            return
        }
        val message = safeStringMap(args["message"] as? Map<*, *>)
        val messageUID = args["messageUID"] as? String
        scope.launch {
            try {
                AltcraftSDK.push.pushEvents.deliveryEvent(context, message, messageUID)
                withContext(Dispatchers.Main) { result.success(null) }
            } catch (e: Exception) {
                Log.e("altcraft_push_bridge", "deliveryEvent failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- openEvent ----

    private fun handleOpenEvent(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<String, Any> ?: run {
            result.error("ERR", "args is null", null)
            return
        }
        val message = safeStringMap(args["message"] as? Map<*, *>)
        val messageUID = args["messageUID"] as? String
        scope.launch {
            try {
                AltcraftSDK.push.pushEvents.openEvent(context, message, messageUID)
                withContext(Dispatchers.Main) { result.success(null) }
            } catch (e: Exception) {
                Log.e("altcraft_push_bridge", "openEvent failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- requestNotificationPermission ----

    private fun handleRequestPermission(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                result.success(true)
                return
            }

            val act = activity ?: run {
                result.success(false)
                return
            }

            if (ContextCompat.checkSelfPermission(
                    act,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                result.success(true)
                return
            }

            ActivityCompat.requestPermissions(
                act,
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequestCode
            )
            permissionResultCallback = { granted -> result.success(granted) }
        } catch (e: Exception) {
            Log.e(
                "altcraft_push_bridge",
                "requestNotificationPermission failed: ${e.message}"
            )
            result.success(false)
        }
    }

    // ---- Helpers ----

    /**
     * Converts a native subscription status response into a codec-safe map.
     */
    @Suppress("MISSING_DEPENDENCY_CLASS_IN_EXPRESSION_TYPE")
    private fun responseToMap(
        response: ResponseWithHttpCode<ResponseWithProfile>?
    ): Map<String, Any?>? {
        if (response == null) return null
        return codecSafe(
            mapOf(
                "http_code" to response.httpCode,
                "response" to (response.response?.let {
                    mapOf<String, Any?>(
                        "error" to it.error,
                        "error_text" to it.errorText,
                        "profile" to (it.profile?.let { p ->
                            mapOf<String, Any?>(
                                "id" to p.id,
                                "status" to p.status,
                                "is_test" to p.isTest,
                                "subscription" to (p.subscription?.let { s ->
                                    val fields: Any? = s.fields
                                    mapOf<String, Any?>(
                                        "subscription_id" to s.subscriptionId,
                                        "hash_id" to s.hashId,
                                        "provider" to s.provider,
                                        "status" to s.status,
                                        "fields" to codecSafe(fields),
                                        "cats" to (s.cats?.map { c ->
                                            mapOf<String, Any?>(
                                                "name" to c.name,
                                                "title" to c.title,
                                                "steady" to c.steady,
                                                "active" to c.active
                                            )
                                        })
                                    )
                                })
                            )
                        })
                    )
                })
            )
        ) as? Map<String, Any?>
    }

    /**
     * Recursively converts arbitrary values into types supported by Flutter's StandardMessageCodec.
     */
    private fun codecSafe(value: Any?): Any? {
        return when (value) {
            null -> null
            is Boolean -> value
            is Int -> value
            is Long -> value
            is Double -> value
            is Float -> value.toDouble()
            is String -> value
            is ByteArray -> value
            is IntArray -> value.toList()
            is LongArray -> value.toList()
            is FloatArray -> value.toList().map { it.toDouble() }
            is DoubleArray -> value.toList()
            is ProfileData -> codecSafe(
                mapOf(
                    "id" to value.id,
                    "status" to value.status,
                    "acid" to value.acid,
                    "is_test" to value.isTest,
                    "subscription" to value.subscription?.let { subscription ->
                        mapOf(
                            "subscriptionId" to subscription.subscriptionId,
                            "hashId" to subscription.hashId,
                            "provider" to subscription.provider,
                            "status" to subscription.status,
                            "fields" to subscription.fields,
                            "cats" to subscription.cats
                        )
                    }
                )
            )

            is Map<*, *> -> value.entries.associate { entry ->
                (entry.key?.toString() ?: "") to codecSafe(entry.value)
            }

            is List<*> -> value.map { codecSafe(it) }
            else -> value.toString()
        }
    }

    /**
     * Creates an SDK category model from a Flutter map.
     */
    private fun mapToCategoryData(map: Map<String, Any?>): CategoryData {
        return CategoryData(
            name = map["name"] as? String,
            title = map["title"] as? String,
            steady = map["steady"] as? Boolean,
            active = map["active"] as? Boolean
        )
    }

    /**
     * Safely converts a map to String keys/values, filtering out null entries.
     */
    private fun safeStringMap(source: Map<*, *>?): Map<String, String> {
        if (source == null) return emptyMap()
        return source.entries
            .filter { it.value != null }
            .associate { (k, v) ->
                (k?.toString() ?: "") to (v as Any).toString()
            }
    }
}
