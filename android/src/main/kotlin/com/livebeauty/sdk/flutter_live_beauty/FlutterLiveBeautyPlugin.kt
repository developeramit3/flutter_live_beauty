package com.livebeauty.sdk.flutter_live_beauty

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.livebeauty.sdk.flutter_live_beauty.camera.Camera2Engine
import com.livebeauty.sdk.flutter_live_beauty.camera.CameraPosition
import com.livebeauty.sdk.flutter_live_beauty.mediapipe.MediaPipeFaceDetector
import com.livebeauty.sdk.flutter_live_beauty.renderer.GpuBeautyRenderer
import com.livebeauty.sdk.flutter_live_beauty.streaming.StreamingFramePipeline
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry

/**
 * Android implementation of FlutterLiveBeautyPlugin.
 * Manages Camera2, MediaPipe Face Landmarker, OpenGL ES 3.0 Beauty Renderer, Streaming Pipeline,
 * and Android runtime permission requests.
 */
class FlutterLiveBeautyPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var statsChannel: EventChannel
    private lateinit var framesChannel: EventChannel

    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var textureRegistry: TextureRegistry? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    private var cameraEngine: Camera2Engine? = null
    private var beautyRenderer: GpuBeautyRenderer? = null
    private var faceDetector: MediaPipeFaceDetector? = null
    private val streamingPipeline = StreamingFramePipeline()

    private var statsSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var statsRunnable: Runnable? = null

    private var pendingPermissionResult: Result? = null
    private val CAMERA_PERMISSION_REQUEST_CODE = 5001

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        textureRegistry = flutterPluginBinding.textureRegistry

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.livebeauty.sdk/methods")
        channel.setMethodCallHandler(this)

        statsChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.livebeauty.sdk/stats")
        statsChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                statsSink = events
                startStatsReporting()
            }

            override fun onCancel(arguments: Any?) {
                statsSink = null
                stopStatsReporting()
            }
        })

        framesChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.livebeauty.sdk/frames")
        framesChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                streamingPipeline.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                streamingPipeline.setEventSink(null)
            }
        })
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE} (SDK ${android.os.Build.VERSION.SDK_INT})")
            }
            "hasCameraPermission" -> {
                result.success(checkCameraPermission())
            }
            "requestCameraPermission" -> {
                handleRequestCameraPermission(result)
            }
            "initializeCamera" -> {
                handleInitializeCamera(call, result)
            }
            "disposeCamera" -> {
                handleDisposeCamera(result)
            }
            "switchCamera" -> {
                handleSwitchCamera(result)
            }
            "setZoom" -> {
                val zoom = (call.argument<Double>("zoom") ?: 1.0).toFloat()
                cameraEngine?.setZoom(zoom)
                result.success(null)
            }
            "setFlash" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                cameraEngine?.setFlash(enable)
                result.success(null)
            }
            "setBeautyEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                beautyRenderer?.isBeautyEnabled = enabled
                result.success(null)
            }
            "setFeatureIntensity" -> {
                handleSetFeatureIntensity(call, result)
            }
            "updateBeautyConfig" -> {
                handleUpdateBeautyConfig(call, result)
            }
            "setFilter" -> {
                handleSetFilter(call, result)
            }
            "setPerformanceProfile" -> {
                handleSetPerformanceProfile(call, result)
            }
            "startStreamingOutput" -> {
                streamingPipeline.start()
                result.success(null)
            }
            "stopStreamingOutput" -> {
                streamingPipeline.stop()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkCameraPermission(): Boolean {
        val ctx = context ?: return false
        return ContextCompat.checkSelfPermission(ctx, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun handleRequestCameraPermission(result: Result) {
        if (checkCameraPermission()) {
            result.success(true)
            return
        }

        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Cannot request camera permission without foreground Activity", null)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
            return true
        }
        return false
    }

    private fun handleInitializeCamera(call: MethodCall, result: Result) {
        val ctx = context ?: run {
            result.error("INIT_ERROR", "Context not available", null)
            return
        }

        if (!checkCameraPermission()) {
            result.error(
                "PERMISSION_DENIED",
                "Camera permission has not been granted. Request permission first.",
                null
            )
            return
        }

        val registry = textureRegistry ?: run {
            result.error("INIT_ERROR", "TextureRegistry not available", null)
            return
        }

        val positionStr = call.argument<String>("position") ?: "front"
        val position = if (positionStr == "rear") CameraPosition.REAR else CameraPosition.FRONT
        val widthArg = call.argument<Int>("width") ?: 1280
        val heightArg = call.argument<Int>("height") ?: 720

        // In mobile portrait, the hardware sensor captures landscape:
        val sensorWidth = Math.max(widthArg, heightArg)
        val sensorHeight = Math.min(widthArg, heightArg)

        // The rendered display preview is portrait:
        val renderWidth = Math.min(widthArg, heightArg)
        val renderHeight = Math.max(widthArg, heightArg)

        try {
            val entry = registry.createSurfaceTexture()
            textureEntry = entry

            val renderer = GpuBeautyRenderer(entry).apply {
                initialize(renderWidth, renderHeight, sensorWidth, sensorHeight)
                onFrameRendered = { timestampNs, textureId, w, h ->
                    streamingPipeline.onNewProcessedFrame(timestampNs, textureId, w, h)
                }
            }
            beautyRenderer = renderer

            val detector = MediaPipeFaceDetector(ctx).apply {
                initialize(maxNumFaces = 1)
            }
            faceDetector = detector

            val camera = Camera2Engine(ctx).apply {
                openCamera(position, sensorWidth, sensorHeight, renderer.cameraSurfaceTexture!!) {
                    // Camera opened successfully
                }
            }
            cameraEngine = camera

            // Apply initial config if provided
            val configMap = call.argument<Map<String, Any>>("config")
            if (configMap != null) {
                applyConfigMap(configMap)
            }

            result.success(
                mapOf(
                    "textureId" to entry.id(),
                    "previewWidth" to renderWidth,
                    "previewHeight" to renderHeight
                )
            )
        } catch (e: Exception) {
            result.error("CAMERA_INIT_FAILED", e.message, null)
        }
    }

    private fun handleSwitchCamera(result: Result) {
        val camera = cameraEngine ?: run {
            result.error("NOT_INITIALIZED", "Camera not initialized", null)
            return
        }
        camera.switchCamera { newPos ->
            result.success(if (newPos == CameraPosition.REAR) "rear" else "front")
        }
    }

    private fun handleSetFeatureIntensity(call: MethodCall, result: Result) {
        val feature = call.argument<String>("feature") ?: ""
        val intensity = (call.argument<Int>("intensity") ?: 0) / 100.0f
        val renderer = beautyRenderer ?: run {
            result.success(null)
            return
        }

        when (feature) {
            "skinSmoothing" -> renderer.smoothIntensity = intensity
            "skinWhitening" -> renderer.whiteningIntensity = intensity
            "skinGlow" -> renderer.glowIntensity = intensity
            "skinTone" -> renderer.toneBalance = intensity
            "faceSlimming" -> renderer.faceSlimming = intensity
            "smallFace" -> renderer.smallFace = intensity
            "jawlineAdjustment" -> renderer.jawline = intensity
            "chinAdjustment" -> renderer.chinAdjustment = intensity
            "noseSlimming" -> renderer.noseSlimming = intensity
            "eyeEnlargement" -> renderer.eyeEnlargement = intensity
            "lipstick" -> renderer.lipstickIntensity = intensity
            "blush" -> renderer.blushIntensity = intensity
            "highlighter" -> renderer.highlighterIntensity = intensity
        }
        result.success(null)
    }

    private fun handleUpdateBeautyConfig(call: MethodCall, result: Result) {
        val configMap = call.arguments as? Map<String, Any>
        if (configMap != null) {
            applyConfigMap(configMap)
        }
        result.success(null)
    }

    private fun applyConfigMap(map: Map<String, Any>) {
        val renderer = beautyRenderer ?: return
        renderer.isBeautyEnabled = map["enabled"] as? Boolean ?: true

        val intensities = map["featureIntensities"] as? Map<*, *>
        if (intensities != null) {
            for ((key, value) in intensities) {
                val factor = ((value as? Number)?.toFloat() ?: 0.0f) / 100.0f
                when (key.toString()) {
                    "skinSmoothing" -> renderer.smoothIntensity = factor
                    "skinWhitening" -> renderer.whiteningIntensity = factor
                    "skinGlow" -> renderer.glowIntensity = factor
                    "skinTone" -> renderer.toneBalance = factor
                    "faceSlimming" -> renderer.faceSlimming = factor
                    "smallFace" -> renderer.smallFace = factor
                    "jawlineAdjustment" -> renderer.jawline = factor
                    "chinAdjustment" -> renderer.chinAdjustment = factor
                    "noseSlimming" -> renderer.noseSlimming = factor
                    "eyeEnlargement" -> renderer.eyeEnlargement = factor
                    "lipstick" -> renderer.lipstickIntensity = factor
                    "blush" -> renderer.blushIntensity = factor
                    "highlighter" -> renderer.highlighterIntensity = factor
                }
            }
        }

        val filterId = map["activeFilter"] as? String
        if (filterId != null) {
            renderer.filterType = mapFilterIdToType(filterId)
            val strength = ((map["filterIntensity"] as? Number)?.toFloat() ?: 80.0f) / 100.0f
            renderer.filterIntensity = strength
        }
    }

    private fun handleSetFilter(call: MethodCall, result: Result) {
        val filterId = call.argument<String>("filterId") ?: "original"
        val intensity = (call.argument<Int>("intensity") ?: 80) / 100.0f
        beautyRenderer?.apply {
            filterType = mapFilterIdToType(filterId)
            filterIntensity = intensity
        }
        result.success(null)
    }

    private fun mapFilterIdToType(id: String): Int {
        return when (id) {
            "original" -> 0
            "natural" -> 1
            "warm" -> 2
            "cool" -> 3
            "vintage" -> 4
            "pink" -> 5
            "fresh" -> 6
            "glamour" -> 7
            "soft" -> 8
            "bright" -> 9
            "cinematic" -> 10
            "retro" -> 11
            "black_and_white" -> 12
            "golden" -> 13
            "dreamy" -> 14
            else -> 0
        }
    }

    private fun handleSetPerformanceProfile(call: MethodCall, result: Result) {
        val profile = call.argument<String>("profile") ?: "balanced"
        when (profile) {
            "low" -> faceDetector?.setMaxFaces(1)
            "balanced" -> faceDetector?.setMaxFaces(2)
            "high" -> faceDetector?.setMaxFaces(4)
        }
        result.success(null)
    }

    private fun startStatsReporting() {
        stopStatsReporting()
        statsRunnable = object : Runnable {
            override fun run() {
                val renderer = beautyRenderer
                val detector = faceDetector
                if (renderer != null && statsSink != null) {
                    val stats = mapOf(
                        "renderFps" to renderer.renderFps,
                        "inferenceFps" to 30.0,
                        "renderLatencyMs" to renderer.renderLatencyMs,
                        "inferenceLatencyMs" to (detector?.lastInferenceLatencyMs ?: 0.0),
                        "droppedFrames" to streamingPipeline.droppedFramesCount,
                        "detectedFacesCount" to (detector?.activeFaces?.size ?: 0),
                        "frameWidth" to renderer.width,
                        "frameHeight" to renderer.height
                    )
                    statsSink?.success(stats)
                }
                mainHandler.postDelayed(this, 500)
            }
        }
        mainHandler.post(statsRunnable!!)
    }

    private fun stopStatsReporting() {
        statsRunnable?.let { mainHandler.removeCallbacks(it) }
        statsRunnable = null
    }

    private fun handleDisposeCamera(result: Result) {
        stopStatsReporting()
        streamingPipeline.release()
        cameraEngine?.release()
        cameraEngine = null
        beautyRenderer?.release()
        beautyRenderer = null
        faceDetector?.close()
        faceDetector = null
        textureEntry?.release()
        textureEntry = null
        result.success(null)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        statsChannel.setStreamHandler(null)
        framesChannel.setStreamHandler(null)
        handleDisposeCamera(object : Result {
            override fun success(result: Any?) {}
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
            override fun notImplemented() {}
        })
    }
}
