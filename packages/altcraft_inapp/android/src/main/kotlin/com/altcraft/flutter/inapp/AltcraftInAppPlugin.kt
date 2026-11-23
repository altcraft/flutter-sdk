@file:Suppress("UNCHECKED_CAST")

package com.altcraft.flutter.inapp

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewPropertyAnimator
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.AccelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.view.animation.Interpolator
import android.view.animation.LinearInterpolator
import com.altcraft.sdk.data.models.CoreModels.ProfileModel.CategoryData
import com.altcraft.flutter.core.AltcraftInitRegistry
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.inapp.inApp
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin entry point for the Altcraft In-App module.
 *
 * Registers the In-App method channel.
 */
class AltcraftInAppPlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var bridge: InAppBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "com.altcraft/inapp")
        val instance = InAppBridge(binding.applicationContext, channel)
        bridge = instance
        methodChannel = channel
        channel.setMethodCallHandler(instance)

        // Contribute the In-App configuration to the shared SDK builder used
        // by the core plugin during initialization.
        AltcraftInitRegistry.register(InAppInitContributor())
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        bridge = null
        try {
            AltcraftSDK.inApp.jsonContent.unsubscribe()
        } catch (_: Exception) {
        }
    }
}

/**
 * Bridges Flutter platform-channel calls to the native Altcraft In-App SDK.
 *
 * Handles In-App subscriptions, screen tracking, triggers, and placement
 * requests.
 */
class InAppBridge(
    private val context: Context,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "inAppSubscribe" -> handleInAppSubscribe(call, result)
                "inAppUnsubscribe" -> handleInAppUnsubscribe(call, result)
                "setScreen" -> handleSetScreen(call, result)
                "trigger" -> handleTrigger(call, result)
                "getPlacements" -> handleGetPlacements(result)
                "setAnimations" -> handleSetAnimations(call, result)
                "jsonContentSubscribe" -> handleJsonContentSubscribe(result)
                "jsonContentUnsubscribe" -> handleJsonContentUnsubscribe(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- inAppSubscribe ----

    private fun handleInAppSubscribe(call: MethodCall, result: MethodChannel.Result) {
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

            AltcraftSDK.inApp.subscription.subscribe(
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
            Log.e("altcraft_inapp_bridge", "inAppSubscribe failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- inAppUnsubscribe ----

    private fun handleInAppUnsubscribe(call: MethodCall, result: MethodChannel.Result) {
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

            AltcraftSDK.inApp.subscription.unsubscribe(
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
            Log.e("altcraft_inapp_bridge", "inAppUnsubscribe failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- setScreen ----

    private fun handleSetScreen(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val screen = args["screen"] as? String ?: run {
                result.error("ERR", "screen is missing", null)
                return
            }
            AltcraftSDK.inApp.setScreen(context, screen)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_inapp_bridge", "setScreen failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- trigger ----

    private fun handleTrigger(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val name = args["name"] as? String ?: run {
                result.error("ERR", "name is missing", null)
                return
            }
            AltcraftSDK.inApp.trigger(context, name)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_inapp_bridge", "trigger failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- getPlacements ----

    private fun handleGetPlacements(result: MethodChannel.Result) {
        try {
            AltcraftSDK.inApp.getPlacements(context)
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_inapp_bridge", "getPlacements failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- JSON content ----

    /**
     * Subscribes to JSON content of JSON-content in-app campaigns.
     *
     * The native SDK keeps a single subscriber. Content may be delivered from
     * an SDK coroutine, so the channel call is posted to the main thread.
     */
    private fun handleJsonContentSubscribe(result: MethodChannel.Result) {
        try {
            val mainHandler = Handler(Looper.getMainLooper())
            AltcraftSDK.inApp.jsonContent.subscribe { json ->
                mainHandler.post {
                    try {
                        channel.invokeMethod("onJsonContent", json)
                    } catch (_: Exception) {
                    }
                }
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_inapp_bridge", "jsonContentSubscribe failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    /**
     * Removes the JSON content subscriber.
     */
    private fun handleJsonContentUnsubscribe(result: MethodChannel.Result) {
        try {
            AltcraftSDK.inApp.jsonContent.unsubscribe()
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_inapp_bridge", "jsonContentUnsubscribe failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- setAnimations ----

    /**
     * Replaces the in-app view animation listener with one built from the
     * received animation specs.
     *
     * Specs are matched by campaign identifier; a spec without an identifier
     * acts as the fallback for any campaign. Specs without a match leave the
     * view untouched.
     */
    private fun handleSetAnimations(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<String, Any> ?: run {
                result.error("ERR", "args is null", null)
                return
            }
            val raw = args["animations"] as? List<Map<String, Any?>> ?: emptyList()
            val specs = raw.map { mapToAnimationSpec(it) }
            val density = context.resources.displayMetrics.density

            AltcraftSDK.inApp.animation {
                val spec = specs.firstOrNull {
                    it.companyId != null && it.companyId == companyId
                } ?: specs.firstOrNull { it.companyId == null } ?: return@animation
                if (!spec.hasAnimatedProperties) {
                    return@animation
                }

                prepare {
                    spec.prepare(this, density)
                }

                animate {
                    spec.animate(this, density)
                }
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e("altcraft_inapp_bridge", "setAnimations failed: ${e.message}")
            result.error("SDK_ERROR", e.message, null)
        }
    }

    // ---- Helpers ----

    /**
     * Parsed animation spec received from Flutter.
     *
     * Neutral values are `alpha` 1, `translate` 0, `scale` 1 and `rotation` 0.
     * A missing value (`null`) keeps the neutral state. Translation values are
     * stored in density-independent pixels.
     */
    private data class AnimationSpec(
        val companyId: Int?,
        val durationMs: Long = DEFAULT_DURATION_MS,
        val delayMs: Long = 0L,
        val easing: String = "easeInOut",
        val alphaFrom: Float? = null,
        val alphaTo: Float? = null,
        val translateXFrom: Float? = null,
        val translateXTo: Float? = null,
        val translateYFrom: Float? = null,
        val translateYTo: Float? = null,
        val scaleXFrom: Float? = null,
        val scaleXTo: Float? = null,
        val scaleYFrom: Float? = null,
        val scaleYTo: Float? = null,
        val rotationFrom: Float? = null,
        val rotationTo: Float? = null
    ) {
        /**
         * Whether the spec changes opacity or the transform properties.
         */
        val hasAnimatedProperties: Boolean
            get() = alphaFrom != null || alphaTo != null || hasTransform

        /**
         * Whether the spec animates any transform channel.
         */
        private val hasTransform: Boolean
            get() = translateXFrom != null || translateXTo != null ||
                    translateYFrom != null || translateYTo != null ||
                    scaleXFrom != null || scaleXTo != null ||
                    scaleYFrom != null || scaleYTo != null ||
                    rotationFrom != null || rotationTo != null

        /**
         * Applies the starting state without running an animation.
         */
        fun prepare(view: View, density: Float) {
            if (alphaFrom != null || alphaTo != null) {
                view.alpha = alphaFrom ?: 1f
            }
            if (hasTransform) {
                view.translationX = toPx(translateXFrom ?: 0f, density)
                view.translationY = toPx(translateYFrom ?: 0f, density)
                view.scaleX = scaleXFrom ?: 1f
                view.scaleY = scaleYFrom ?: 1f
                view.rotation = rotationFrom ?: 0f
            }
        }

        /**
         * Applies the target state to a property animator.
         */
        fun animate(animator: ViewPropertyAnimator, density: Float) {
            animator.duration = durationMs
            animator.startDelay = delayMs
            animator.interpolator = interpolator()
            if (alphaFrom != null || alphaTo != null) {
                animator.alpha(alphaTo ?: 1f)
            }
            if (hasTransform) {
                animator.translationX(toPx(translateXTo ?: 0f, density))
                animator.translationY(toPx(translateYTo ?: 0f, density))
                animator.scaleX(scaleXTo ?: 1f)
                animator.scaleY(scaleYTo ?: 1f)
                animator.rotation(rotationTo ?: 0f)
            }
        }

        /**
         * Maps the easing identifier to an Android interpolator.
         */
        fun interpolator(): Interpolator = when (easing) {
            "linear" -> LinearInterpolator()
            "easeIn" -> AccelerateInterpolator()
            "easeInOut" -> AccelerateDecelerateInterpolator()
            else -> DecelerateInterpolator()
        }

        companion object {
            /**
             * Default animation duration in milliseconds.
             */
            const val DEFAULT_DURATION_MS: Long = 350L
        }
    }

    /**
     * Creates an animation spec from a Flutter map.
     */
    private fun mapToAnimationSpec(map: Map<String, Any?>): AnimationSpec {
        return AnimationSpec(
            companyId = (map["companyId"] as? Number)?.toInt(),
            durationMs = (map["durationMs"] as? Number)?.toLong()
                ?: AnimationSpec.DEFAULT_DURATION_MS,
            delayMs = (map["delayMs"] as? Number)?.toLong() ?: 0L,
            easing = map["easing"] as? String ?: "easeInOut",
            alphaFrom = (map["alphaFrom"] as? Number)?.toFloat(),
            alphaTo = (map["alphaTo"] as? Number)?.toFloat(),
            translateXFrom = (map["translateXFrom"] as? Number)?.toFloat(),
            translateXTo = (map["translateXTo"] as? Number)?.toFloat(),
            translateYFrom = (map["translateYFrom"] as? Number)?.toFloat(),
            translateYTo = (map["translateYTo"] as? Number)?.toFloat(),
            scaleXFrom = (map["scaleXFrom"] as? Number)?.toFloat(),
            scaleXTo = (map["scaleXTo"] as? Number)?.toFloat(),
            scaleYFrom = (map["scaleYFrom"] as? Number)?.toFloat(),
            scaleYTo = (map["scaleYTo"] as? Number)?.toFloat(),
            rotationFrom = (map["rotationFrom"] as? Number)?.toFloat(),
            rotationTo = (map["rotationTo"] as? Number)?.toFloat()
        )
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
}

/**
 * Converts density-independent pixels to pixels.
 */
private fun toPx(value: Float, density: Float): Float = value * density
