@file:Suppress("UNCHECKED_CAST")

package com.altcraft.flutter

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.config.AltcraftConfiguration
import com.altcraft.sdk.data.DataClasses
import com.altcraft.sdk.sdk_events.Events

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import androidx.core.content.edit

/**
 * Flutter plugin entry point that connects Dart code with the native Altcraft SDK.
 *
 * Registers method and event channels, creates the native bridge, and forwards
 * Android activity lifecycle callbacks when the plugin is attached to an Activity.
 */
class AltcraftSdkPlugin : FlutterPlugin, ActivityAware {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var bridge: SdkBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val instance = SdkBridge(binding.applicationContext)
        bridge = instance
        methodChannel = MethodChannel(binding.binaryMessenger, "com.altcraft/sdk")
        methodChannel?.setMethodCallHandler(instance)

        eventChannel = EventChannel(binding.binaryMessenger, "com.altcraft/events")
        eventChannel?.setStreamHandler(instance.eventStreamHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        bridge = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        bridge?.onActivityAttached(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // Activity reattached automatically after this
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        bridge?.onActivityAttached(binding)
    }

    override fun onDetachedFromActivity() {
        bridge?.onActivityDetached()
    }
}

/**
 * Bridges Flutter platform-channel calls to the native Altcraft SDK.
 *
 * Handles method calls from Dart, publishes SDK events to Flutter through an
 * EventChannel, manages notification permission callbacks, and converts native
 * SDK models into values supported by Flutter's StandardMessageCodec.
 */
class SdkBridge(
    private val context: Context,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.IO)
    private var activity: Activity? = null
    private val notificationPermissionRequestCode = 1001
    private var permissionResultCallback: ((Boolean) -> Unit)? = null
    private var permissionListener: PluginRegistry.RequestPermissionsResultListener? = null

    /**
     * Stores the current Activity and registers a permission result listener.
     *
     * @param binding Flutter activity binding provided by the plugin lifecycle.
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
     * Event stream handler exposed to the Flutter plugin registration code.
     */
    val eventStreamHandler: EventChannel.StreamHandler
        get() = this

    init {
        Events.subscribe { event ->
            try {
                val map = eventToMap(event)
                scope.launch {
                    withContext(Dispatchers.Main) {
                        try {
                            eventSink?.success(map)
                        } catch (_: Exception) {
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> handleInitialize(call, result)
                "getPushToken" -> handleGetPushToken(result)
                "setPushToken" -> handleSetPushToken(call, result)
                "clear" -> handleClear(result)
                "mobileEvent" -> handleMobileEvent(call, result)
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
                "updateProfileFields" -> handleUpdateProfileFields(call, result)
                "forcedTokenUpdate" -> handleForcedTokenUpdate(result)
                "deleteDeviceToken" -> handleDeleteDeviceToken(call, result)
                "changePushProviderPriorityList" -> handleChangePriority(call, result)
                "isAltcraftPush" -> handleIsAltcraftPush(call, result)
                "takePush" -> handleTakePush(call, result)
                "deliveryEvent" -> handleDeliveryEvent(call, result)
                "openEvent" -> handleOpenEvent(call, result)
                "requestNotificationPermission" -> handleRequestPermission(result)
                "unlockInitialOperationsInThisSession" -> handleUnlockInitial(result)
                "setAppGroup" -> result.success(null)
                "setUserDefaultsValue" -> handleSetUserDefaults(call, result)
                "unsubscribeFromEvents" -> handleUnsubscribeFromEvents(result)
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
            DataClasses.AppInfo(
                appID = it["appID"] as? String ?: "",
                appIID = it["appIID"] as? String ?: "",
                appVer = it["appVer"] as? String ?: "1.0.0"
            )
        }

        val providerList =
            (config["providerPriorityList"] as? List<*>)?.map { it.toString() }
        val enableLogging = config["enableLogging"] as? Boolean
        val rToken = config["rToken"] as? String
        val icon = (config["android_icon"] as? Number)?.toInt()
        val pushReceiverModules =
            (config["android_pushReceiverModules"] as? List<*>)?.map { it.toString() }
        val pushChannelName = config["android_pushChannelName"] as? String
        val pushChannelDescription = config["android_pushChannelDescription"] as? String

        val altcraftConfig = AltcraftConfiguration.Builder(
            apiUrl = apiUrl,
            icon = icon,
            rToken = rToken,
            appInfo = appInfo,
            providerPriorityList = providerList,
            pushReceiverModules = pushReceiverModules,
            pushChannelName = pushChannelName,
            pushChannelDescription = pushChannelDescription,
            enableLogging = enableLogging
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

    // ---- getPushToken ----

    private fun handleGetPushToken(result: MethodChannel.Result) {
        scope.launch {
            try {
                val tokenData = AltcraftSDK.pushTokenFunctions.getPushToken(context)
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
            AltcraftSDK.pushTokenFunctions.setPushToken(context, provider, token)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "setPushToken failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- clear ----

    private fun handleClear(result: MethodChannel.Result) {
        try {
            AltcraftSDK.clear(context) {
                try {
                    result.success(null)
                } catch (e: Exception) {
                    Log.e("altcraft_lib_android_bridge", "clear callback failed: ${e.message}")
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "clear failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- mobileEvent ----

    private fun handleMobileEvent(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val sid = args["sid"] as? String ?: run {
                result.error("ERR", "sid is missing", null)
                return
            }
            val eventName = args["eventName"] as? String ?: run {
                result.error("ERR", "eventName is missing", null)
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
                DataClasses.UTM(
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

            AltcraftSDK.mobileEventFunctions.mobileEvent(
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
            Log.e("altcraft_lib_android_bridge", "mobileEvent failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- pushSubscribe ----

    private fun handlePushSubscribe(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: return
            val sync = (args["sync"] as? Boolean) != false
            val replace = args["replace"] as? Boolean
            val skipTriggers = args["skipTriggers"] as? Boolean
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val customFields = args["customFields"] as? Map<String, Any?>
            val cats = (args["cats"] as? List<Map<String, Any?>>)?.map { mapToCategoryData(it) }

            AltcraftSDK.pushSubscriptionFunctions.pushSubscribe(
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
            Log.e("altcraft_lib_android_bridge", "pushSubscribe failed: ${e.message}")
        }
    }

    // ---- pushSuspend ----

    private fun handlePushSuspend(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: return
            val sync = (args["sync"] as? Boolean) != false
            val replace = args["replace"] as? Boolean
            val skipTriggers = args["skipTriggers"] as? Boolean
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val customFields = args["customFields"] as? Map<String, Any?>
            val cats = (args["cats"] as? List<Map<String, Any?>>)?.map { mapToCategoryData(it) }

            AltcraftSDK.pushSubscriptionFunctions.pushSuspend(
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
            Log.e("altcraft_lib_android_bridge", "pushSuspend failed: ${e.message}")
        }
    }

    // ---- pushUnSubscribe ----

    private fun handlePushUnSubscribe(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: return
            val sync = (args["sync"] as? Boolean) != false
            val replace = args["replace"] as? Boolean
            val skipTriggers = args["skipTriggers"] as? Boolean
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val customFields = args["customFields"] as? Map<String, Any?>
            val cats = (args["cats"] as? List<Map<String, Any?>>)?.map { mapToCategoryData(it) }

            AltcraftSDK.pushSubscriptionFunctions.pushUnSubscribe(
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
            Log.e("altcraft_lib_android_bridge", "pushUnSubscribe failed: ${e.message}")
        }
    }

    // ---- unSuspendPushSubscription ----

    private fun handleUnSuspend(result: MethodChannel.Result) {
        scope.launch {
            try {
                val response =
                    AltcraftSDK.pushSubscriptionFunctions.unSuspendPushSubscription(context)
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
                    AltcraftSDK.pushSubscriptionFunctions.getStatusOfLatestSubscription(context)
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
                    AltcraftSDK.pushSubscriptionFunctions.getStatusOfLatestSubscriptionForProvider(
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
                    AltcraftSDK.pushSubscriptionFunctions.getStatusForCurrentSubscription(context)
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

    // ---- updateProfileFields ----

    private fun handleUpdateProfileFields(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: return
            val profileFields = args["profileFields"] as? Map<String, Any?>
            val skipTriggers = args["skipTriggers"] as? Boolean
            AltcraftSDK.profileFunctions.updateProfileFields(context, profileFields, skipTriggers)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "updateProfileFields failed: ${e.message}")
        }
    }

    // ---- forcedTokenUpdate ----

    private fun handleForcedTokenUpdate(result: MethodChannel.Result) {
        try {
            AltcraftSDK.pushTokenFunctions.forcedTokenUpdate(context) {
                try {
                    result.success(null)
                } catch (e: Exception) {
                    Log.e("altcraft_lib_android_bridge", "forcedTokenUpdate callback failed: ${e.message}")
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "forcedTokenUpdate failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- deleteDeviceToken ----

    private fun handleDeleteDeviceToken(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val provider = args["provider"] as? String ?: run {
                result.error("ERR", "provider is missing", null)
                return
            }
            AltcraftSDK.pushTokenFunctions.deleteDeviceToken(context, provider) {
                try {
                    result.success(null)
                } catch (e: Exception) {
                    Log.e("altcraft_lib_android_bridge", "deleteDeviceToken callback failed: ${e.message}")
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "deleteDeviceToken failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
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
                AltcraftSDK.pushTokenFunctions.changePushProviderPriorityList(context, priorityList)
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
            val message = (call.arguments as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                ?.mapValues { entry -> entry.value.toString() } ?: emptyMap<String, String>()
            val isAlt = AltcraftSDK.PushReceiver.isAltcraftPush(message)
            result.success(isAlt)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "isAltcraftPush failed: ${e.message}")
            result.success(false)
        }
    }

    // ---- takePush ----

    private fun handleTakePush(call: MethodCall, result: MethodChannel.Result) {
        try {
            val message = (call.arguments as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                ?.mapValues { entry -> entry.value.toString() } ?: emptyMap<String, String>()
            AltcraftSDK.PushReceiver.takePush(context, message)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "takePush failed: ${e.message}")
        }
    }

    // ---- deliveryEvent ----

    private fun handleDeliveryEvent(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: return
            val message = (args["message"] as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                ?.mapValues { entry -> entry.value.toString() }
            val messageUID = args["messageUID"] as? String
            AltcraftSDK.pushEventFunctions.deliveryEvent(context, message, messageUID)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "deliveryEvent failed: ${e.message}")
        }
    }

    // ---- openEvent ----

    private fun handleOpenEvent(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: return
            val message = (args["message"] as? Map<*, *>)?.mapKeys { entry -> entry.key.toString() }
                ?.mapValues { entry -> entry.value.toString() }
            val messageUID = args["messageUID"] as? String
            AltcraftSDK.pushEventFunctions.openEvent(context, message, messageUID)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "openEvent failed: ${e.message}")
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

            if (act is ComponentActivity) {
                AltcraftSDK.requestNotificationPermission(context, act)
                result.success(null)
            } else {
                ActivityCompat.requestPermissions(
                    act,
                    arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                    notificationPermissionRequestCode
                )
                permissionResultCallback = { granted -> result.success(granted) }
            }
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "requestNotificationPermission failed: ${e.message}")
            result.success(false)
        }
    }

    // ---- unlockInitialOperationsInThisSession ----

    private fun handleUnlockInitial(result: MethodChannel.Result) {
        try {
            AltcraftSDK.unlockInitialOperationsInThisSession()
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "unlockInitialOperationsInThisSession failed: ${e.message}")
        }
    }

    // ---- setUserDefaultsValue ----

    private fun handleSetUserDefaults(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: return
            val key = args["key"] as? String ?: return
            val value = args["value"] as? String
            val prefs = context.getSharedPreferences("altcraft_sdk", Context.MODE_PRIVATE)
            if (value == null) {
                prefs.edit { remove(key) }
            } else {
                prefs.edit { putString(key, value) }
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "setUserDefaultsValue failed: ${e.message}")
        }
    }

    // ---- unsubscribeFromEvents ----

    private fun handleUnsubscribeFromEvents(result: MethodChannel.Result) {
        try {
            Events.unsubscribe()
            eventSink = null
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_lib_android_bridge", "unsubscribeFromEvents failed: ${e.message}")
        }
    }

    // ---- Helpers ----

    /**
     * Converts an SDK event into a codec-safe map that can be sent to Flutter.
     *
     * @param event SDK event received from the native library.
     * @return Codec-safe event representation.
     */
    private fun eventToMap(event: DataClasses.Event): Map<String, Any?> {
        val type = when (event) {
            is DataClasses.RetryError -> "retryError"
            is DataClasses.Error -> "error"
            else -> "event"
        }

        val timestamp = formatDateToTimestampString(event.date)

        return codecSafe(
            mapOf(
                "function" to event.function,
                "code" to event.eventCode,
                "message" to (event.eventMessage ?: ""),
                "type" to type,
                "value" to event.eventValue,
                "timestamp" to timestamp
            )
        ) as Map<String, Any?>
    }

    /**
     * Formats a date in the device local time zone.
     *
     * @param date Date to format.
     * @return Timestamp string in `yyyy-MM-dd HH:mm:ss.SSS` format.
     */
    private fun formatDateToTimestampString(date: Date): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)
        formatter.timeZone = TimeZone.getDefault()
        return formatter.format(date)
    }

    /**
     * Converts a native subscription status response into a codec-safe map.
     *
     * The response may contain SDK model objects and nested values that are not
     * directly supported by Flutter platform channels, so nested fields are passed
     * through [codecSafe] before being returned.
     *
     * @param response Native SDK response with an HTTP code.
     * @return Codec-safe response map, or `null` when the response is `null`.
     */
    @Suppress("MISSING_DEPENDENCY_CLASS_IN_EXPRESSION_TYPE")
    private fun responseToMap(response: DataClasses.ResponseWithHttpCode?): Map<String, Any?>? {
        if (response == null) return null
        return codecSafe(
            mapOf(
                "httpCode" to response.httpCode,
                "response" to (response.response?.let {
                    mapOf<String, Any?>(
                        "error" to it.error,
                        "errorText" to it.errorText,
                        "profile" to (it.profile?.let { p ->
                            mapOf<String, Any?>(
                                "id" to p.id,
                                "status" to p.status,
                                "isTest" to p.isTest,
                                "subscription" to (p.subscription?.let { s ->
                                    val fields: Any? = s.fields
                                    mapOf<String, Any?>(
                                        "subscriptionId" to s.subscriptionId,
                                        "hashId" to s.hashId,
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
     *
     * Primitive values, byte arrays, lists, and maps are preserved where possible.
     * Unsupported object types are converted to their string representation.
     *
     * @param value Value to convert.
     * @return Codec-safe representation of the input value.
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
            is Map<*, *> -> value.entries.associate { entry ->
                (entry.key?.toString() ?: "") to codecSafe(entry.value)
            }

            is List<*> -> value.map { codecSafe(it) }
            else -> value.toString()
        }
    }

    /**
     * Creates an SDK category model from a Flutter map.
     *
     * @param map Category data received from Dart.
     * @return SDK category data model.
     */
    private fun mapToCategoryData(map: Map<String, Any?>): DataClasses.CategoryData {
        return DataClasses.CategoryData(
            name = map["name"] as? String,
            title = map["title"] as? String,
            steady = map["steady"] as? Boolean,
            active = map["active"] as? Boolean
        )
    }

    /**
     * Creates an SDK subscription model from a Flutter map.
     *
     * Supports email, SMS, and push subscription payloads. Returns `null` when
     * the channel is unknown or required fields for the selected channel are missing.
     *
     * @param map Subscription data received from Dart.
     * @return SDK subscription model, or `null` if the map cannot be parsed.
     */
    private fun mapToSubscription(map: Map<String, Any?>): DataClasses.Subscription? {
        val channel = map["channel"] as? String ?: return null
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
                DataClasses.EmailSubscription(
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
                DataClasses.SmsSubscription(
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
                DataClasses.PushSubscription(
                    resourceId = resourceId,
                    provider = provider,
                    subscriptionId = subscriptionId,
                    status = status,
                    priority = priority,
                    customFields = customFields,
                    cats = cats
                )
            }

            else -> null
        }
    }
}
