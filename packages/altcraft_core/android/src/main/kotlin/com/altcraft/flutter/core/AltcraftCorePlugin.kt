package com.altcraft.flutter.core

import android.content.Context
import android.os.Looper
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.config.AltcraftConfiguration
import com.altcraft.sdk.data.models.CoreModels.ProfileModel.CategoryData
import com.altcraft.sdk.data.models.CoreModels.ProfileModel.ProfileData
import com.altcraft.sdk.data.models.CoreModels.ProfileModel.SubscriptionData
import com.altcraft.sdk.data.models.CoreModels.PropertyModel.AppInfo
import com.altcraft.sdk.data.models.CoreModels.SDKEventModel
import com.altcraft.sdk.events.Events
import com.altcraft.sdk.platform.authenticate.external.jwt.JWTInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Flutter plugin entry point for the Altcraft core module.
 *
 * Registers the core method channel and the shared native SDK events channel.
 */
class AltcraftCorePlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var bridge: CoreBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "com.altcraft/core")
        val instance = CoreBridge(binding.applicationContext, channel)
        bridge = instance
        methodChannel = channel
        channel.setMethodCallHandler(instance)

        eventChannel = EventChannel(binding.binaryMessenger, "com.altcraft/events")
        eventChannel?.setStreamHandler(instance.eventStreamHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        bridge?.dispose()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        bridge = null
    }
}

/**
 * Bridges Flutter platform-channel calls to the native Altcraft core SDK.
 *
 * Handles core initialization, native SDK events, JWT authentication, and
 * data management.
 */
class CoreBridge(
    private val context: Context,
    private val methodChannel: MethodChannel?,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val pluginJob = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.IO + pluginJob)

    /** Timeout for a JWT token request forwarded to Dart. */
    private val JWT_REQUEST_TIMEOUT_SECONDS = 10L

    /**
     * Bridges the native JWT provider to Dart: the SDK requests a token
     * synchronously, the bridge forwards the request to Dart over the
     * method channel and blocks until Dart replies (bounded by a timeout).
     */
    private val jwtProvider = object : JWTInterface {
        override fun getJWT(): String? {
            if (Looper.myLooper() == Looper.getMainLooper()) return null
            val latch = CountDownLatch(1)
            var token: String? = null
            scope.launch(Dispatchers.Main) {
                try {
                    methodChannel?.invokeMethod(
                        "getJwt", null, object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                token = result as? String
                                latch.countDown()
                            }

                            override fun error(
                                code: String,
                                message: String?,
                                details: Any?
                            ) {
                                latch.countDown()
                            }

                            override fun notImplemented() {
                                latch.countDown()
                            }
                        }
                    )
                } catch (_: Exception) {
                    latch.countDown()
                }
            }
            latch.await(JWT_REQUEST_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            return token
        }
    }

    /**
     * Full cleanup called when the plugin is detached from the Flutter engine.
     */
    fun dispose() {
        Events.Subscription.unsubscribe()
        AltcraftSDK.auth.setJWTProvider(null)
        pluginJob.cancel()
        eventSink = null
    }

    /**
     * Event stream handler exposed to the Flutter plugin registration code.
     */
    val eventStreamHandler: EventChannel.StreamHandler
        get() = this

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Events.Subscription.subscribe { event ->
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

    override fun onCancel(arguments: Any?) {
        Events.Subscription.unsubscribe()
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> handleInitialize(call, result)
                "clear" -> handleClear(result)
                "unlockInitialOperationsInThisSession" -> handleUnlockInitial(result)
                "setUserDefaultsValue" -> handleSetUserDefaults(call, result)
                "setAppGroup" -> result.success(null)
                "unsubscribeFromEvents" -> handleUnsubscribeFromEvents(result)
                "authenticate" -> handleAuthenticate(result)
                "logOut" -> handleLogOut(result)
                "isAuthenticated" -> handleIsAuthenticated(result)
                "setJwtProvider" -> handleSetJwtProvider(result)
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

        val enableLogging = config["enableLogging"] as? Boolean
        val rToken = config["rToken"] as? String

        val builder = AltcraftConfiguration.Builder(
            apiUrl = apiUrl,
            rToken = rToken,
            appInfo = appInfo,
            enableLogging = enableLogging
        )

        // Module plugins (push, in-app) contribute their configurations here,
        // so the core plugin stays independent of concrete modules.
        AltcraftInitRegistry.applyAll(builder, moduleConfigsFrom(config))
        val altcraftConfig = builder.build()

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

    /**
     * Extracts module configurations from the Flutter initialization payload.
     *
     * The map is generic: keys are module identifiers and values are
     * module-specific option maps produced by Dart builder extensions.
     */
    private fun moduleConfigsFrom(
        config: Map<String, Any>
    ): Map<String, Map<String, Any?>> {
        val raw = config["moduleConfigs"] as? Map<*, *> ?: return emptyMap()
        return raw.entries.associate { (key, value) ->
            key.toString() to (
                (value as? Map<*, *>)?.entries?.associate { (optionKey, optionValue) ->
                    optionKey.toString() to optionValue
                } ?: emptyMap()
            )
        }
    }

    // ---- clear ----

    private fun handleClear(result: MethodChannel.Result) {
        try {
            AltcraftSDK.clear(context) {
                try {
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- unlockInitialOperationsInThisSession ----

    private fun handleUnlockInitial(result: MethodChannel.Result) {
        try {
            AltcraftSDK.unlockInitialOperationsInThisSession()
            result.success(null)
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- setUserDefaultsValue ----
    // Note: suiteName is iOS-only (App Group). On Android, values are always
    // stored in the plugin's private SharedPreferences ("altcraft_sdk").

    private fun handleSetUserDefaults(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val key = args["key"] as? String ?: run {
                result.error("ERR", "key is missing", null)
                return
            }
            val value = args["value"] as? String
            val prefs = context.getSharedPreferences("altcraft_sdk", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            if (value == null) {
                editor.remove(key)
            } else {
                editor.putString(key, value)
            }
            editor.apply()
            result.success(null)
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- unsubscribeFromEvents ----

    private fun handleUnsubscribeFromEvents(result: MethodChannel.Result) {
        try {
            Events.Subscription.unsubscribe()
            eventSink = null
            result.success(null)
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- Authentication ----

    private fun handleSetJwtProvider(result: MethodChannel.Result) {
        try {
            AltcraftSDK.auth.setJWTProvider(jwtProvider)
            result.success(null)
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    private fun handleAuthenticate(result: MethodChannel.Result) {
        try {
            AltcraftSDK.auth.authenticate(context)
            result.success(null)
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    private fun handleLogOut(result: MethodChannel.Result) {
        try {
            AltcraftSDK.auth.logOut(context)
            result.success(null)
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    private fun handleIsAuthenticated(result: MethodChannel.Result) {
        scope.launch {
            try {
                val authenticated = AltcraftSDK.auth.isAuthenticated(context)
                withContext(Dispatchers.Main) { result.success(authenticated) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }
        }
    }

    // ---- Helpers ----

    /**
     * Converts an SDK event into a codec-safe map that can be sent to Flutter.
     */
    private fun eventToMap(event: SDKEventModel.Event): Map<String, Any?> {
        val type = when (event) {
            is SDKEventModel.RetryError -> "retryError"
            is SDKEventModel.Error -> "error"
            else -> "event"
        }

        val timestamp = formatDateToTimestampString(event.date)

        return codecSafe(
            mapOf(
                "function" to event.function,
                "code" to (event.eventValue?.get("http_code") as? Int),
                "message" to (event.eventMessage ?: ""),
                "type" to type,
                "value" to event.eventValue,
                "timestamp" to timestamp
            )
        ) as Map<String, Any?>
    }

    /**
     * Formats a date in the device local time zone.
     */
    private fun formatDateToTimestampString(date: Date): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)
        formatter.timeZone = TimeZone.getDefault()
        return formatter.format(date)
    }

    /**
     * Recursively converts arbitrary values into types supported by Flutter's
     * StandardMessageCodec.
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
            is ProfileData -> profileToMap(value)
            is SubscriptionData -> subscriptionToMap(value)
            is CategoryData -> categoryToMap(value)
            is JsonElement -> jsonToCodecSafe(value)
            else -> value.toString()
        }
    }

    /**
     * Converts a native profile model into a codec-safe map.
     */
    private fun profileToMap(profile: ProfileData): Map<String, Any?> = mapOf(
        "id" to profile.id,
        "status" to profile.status,
        "acid" to profile.acid,
        "isTest" to profile.isTest,
        "subscription" to profile.subscription?.let { subscriptionToMap(it) }
    )

    /**
     * Converts a native subscription model into a codec-safe map.
     */
    private fun subscriptionToMap(subscription: SubscriptionData): Map<String, Any?> = mapOf(
        "subscriptionId" to subscription.subscriptionId,
        "hashId" to subscription.hashId,
        "provider" to subscription.provider,
        "status" to subscription.status,
        "fields" to subscription.fields?.mapValues { jsonToCodecSafe(it.value) },
        "cats" to subscription.cats?.map { categoryToMap(it) }
    )

    /**
     * Converts a native subscription category into a codec-safe map.
     */
    private fun categoryToMap(category: CategoryData): Map<String, Any?> = mapOf(
        "name" to category.name,
        "title" to category.title,
        "steady" to category.steady,
        "active" to category.active
    )

    /**
     * Converts a kotlinx JSON element into a codec-safe value.
     */
    private fun jsonToCodecSafe(element: JsonElement): Any? {
        return when (element) {
            is JsonNull -> null
            is JsonPrimitive -> when {
                element.isString -> element.content
                element.content == "true" -> true
                element.content == "false" -> false
                else -> element.content.toLongOrNull()
                    ?: element.content.toDoubleOrNull()
                    ?: element.content
            }

            is JsonArray -> element.map { jsonToCodecSafe(it) }
            is JsonObject -> element.mapValues { jsonToCodecSafe(it.value) }
        }
    }
}
