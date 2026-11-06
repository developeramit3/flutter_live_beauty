package com.livebeauty.sdk.flutter_live_beauty.camera

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.SurfaceTexture
import android.hardware.camera2.*
import android.hardware.camera2.params.StreamConfigurationMap
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Size
import android.view.Surface
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import kotlin.math.abs

enum class CameraPosition {
    FRONT, REAR
}

/**
 * Native Camera2 capture engine.
 * Delivers preview frames directly into an OpenGL external OES SurfaceTexture.
 */
class Camera2Engine(private val context: Context) {

    companion object {
        private const val TAG = "Camera2Engine"
    }

    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var captureRequestBuilder: CaptureRequest.Builder? = null

    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    private val cameraOpenCloseLock = Semaphore(1)

    var currentPosition: CameraPosition = CameraPosition.FRONT
        private set

    var previewWidth: Int = 1280
        private set
    var previewHeight: Int = 720
        private set

    private var targetSurfaceTexture: SurfaceTexture? = null
    private var previewSurface: Surface? = null
    private var currentZoom: Float = 1.0f
    private var isFlashOn: Boolean = false

    fun startBackgroundThread() {
        if (backgroundThread == null) {
            backgroundThread = HandlerThread("LiveBeautyCameraThread").apply {
                start()
                backgroundHandler = Handler(looper)
            }
        }
    }

    fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (_: InterruptedException) {}
    }

    @SuppressLint("MissingPermission")
    fun openCamera(
        position: CameraPosition,
        width: Int,
        height: Int,
        surfaceTexture: SurfaceTexture,
        onOpened: (() -> Unit)? = null
    ) {
        startBackgroundThread()
        this.currentPosition = position
        this.targetSurfaceTexture = surfaceTexture

        val cameraId = getCameraId(position) ?: run {
            Log.e(TAG, "No camera matching position $position")
            return
        }

        try {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            if (map != null) {
                val optimalSize = chooseOptimalSize(map, width, height)
                this.previewWidth = optimalSize.width
                this.previewHeight = optimalSize.height
                Log.d(TAG, "Requested preview size: ${width}x${height}, selected optimal: ${previewWidth}x${previewHeight}")
            } else {
                this.previewWidth = width
                this.previewHeight = height
            }

            if (!cameraOpenCloseLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                throw RuntimeException("Time out waiting to lock camera opening.")
            }

            cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraOpenCloseLock.release()
                    cameraDevice = camera
                    Log.d(TAG, "Camera device opened: ${camera.id}")
                    startCaptureSession(surfaceTexture)
                    onOpened?.invoke()
                }

                override fun onDisconnected(camera: CameraDevice) {
                    cameraOpenCloseLock.release()
                    Log.w(TAG, "Camera device disconnected: ${camera.id}")
                    camera.close()
                    cameraDevice = null
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    cameraOpenCloseLock.release()
                    Log.e(TAG, "Camera device open error: $error on camera ${camera.id}")
                    camera.close()
                    cameraDevice = null
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            cameraOpenCloseLock.release()
            Log.e(TAG, "Failed to open camera", e)
        }
    }

    private fun chooseOptimalSize(map: StreamConfigurationMap, reqWidth: Int, reqHeight: Int): Size {
        val choices = map.getOutputSizes(SurfaceTexture::class.java)
        if (choices.isNullOrEmpty()) {
            return Size(reqWidth, reqHeight)
        }

        val targetW = Math.max(reqWidth, reqHeight)
        val targetH = Math.min(reqWidth, reqHeight)

        // Check for exact match
        for (size in choices) {
            if (size.width == targetW && size.height == targetH) {
                return size
            }
        }

        val targetAspect = targetW.toDouble() / targetH.toDouble()
        var bestSize = choices[0]
        var minDiff = Double.MAX_VALUE

        for (size in choices) {
            val aspect = size.width.toDouble() / size.height.toDouble()
            val aspectDiff = abs(aspect - targetAspect)
            if (aspectDiff < 0.05) {
                val resDiff = abs(size.width - targetW)
                if (resDiff < minDiff) {
                    minDiff = resDiff.toDouble()
                    bestSize = size
                }
            }
        }
        return bestSize
    }

    private fun startCaptureSession(surfaceTexture: SurfaceTexture) {
        val camera = cameraDevice ?: return
        try {
            surfaceTexture.setDefaultBufferSize(previewWidth, previewHeight)

            previewSurface?.release()
            val surface = Surface(surfaceTexture)
            previewSurface = surface

            captureRequestBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                addTarget(surface)
                set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
                set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO)
            }

            camera.createCaptureSession(
                listOf(surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        captureSession = session
                        Log.d(TAG, "Camera capture session configured successfully")
                        try {
                            captureRequestBuilder?.let { builder ->
                                session.setRepeatingRequest(builder.build(), null, backgroundHandler)
                                Log.d(TAG, "Repeating preview request started successfully")
                            }
                        } catch (e: CameraAccessException) {
                            Log.e(TAG, "Failed to start preview repeating request", e)
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "Session configuration failed")
                    }
                },
                backgroundHandler
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure capture session", e)
        }
    }

    fun switchCamera(onComplete: ((CameraPosition) -> Unit)? = null) {
        val newPos = if (currentPosition == CameraPosition.FRONT) CameraPosition.REAR else CameraPosition.FRONT
        val st = targetSurfaceTexture ?: return
        closeCamera()
        openCamera(newPos, previewWidth, previewHeight, st) {
            onComplete?.invoke(newPos)
        }
    }

    fun setZoom(zoom: Float) {
        this.currentZoom = zoom
        val builder = captureRequestBuilder ?: return
        val session = captureSession ?: return
        val characteristics = cameraManager.getCameraCharacteristics(getCameraId(currentPosition) ?: return)
        val maxZoom = characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1.0f
        val activeRect = characteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE) ?: return

        val clampedZoom = zoom.coerceIn(1.0f, maxZoom)
        val cropW = (activeRect.width() / clampedZoom).toInt()
        val cropH = (activeRect.height() / clampedZoom).toInt()
        val cropX = (activeRect.width() - cropW) / 2
        val cropY = (activeRect.height() - cropH) / 2
        val cropRect = android.graphics.Rect(cropX, cropY, cropX + cropW, cropY + cropH)

        builder.set(CaptureRequest.SCALER_CROP_REGION, cropRect)
        try {
            session.setRepeatingRequest(builder.build(), null, backgroundHandler)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to apply zoom", e)
        }
    }

    fun setFlash(enable: Boolean) {
        this.isFlashOn = enable
        val builder = captureRequestBuilder ?: return
        val session = captureSession ?: return

        if (currentPosition == CameraPosition.REAR) {
            builder.set(
                CaptureRequest.FLASH_MODE,
                if (enable) CaptureRequest.FLASH_MODE_TORCH else CaptureRequest.FLASH_MODE_OFF
            )
            try {
                session.setRepeatingRequest(builder.build(), null, backgroundHandler)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to apply flash", e)
            }
        }
    }

    fun closeCamera() {
        try {
            cameraOpenCloseLock.acquire()
            captureSession?.close()
            captureSession = null
            cameraDevice?.close()
            cameraDevice = null
            previewSurface?.release()
            previewSurface = null
        } catch (_: Exception) {
        } finally {
            cameraOpenCloseLock.release()
        }
    }

    fun release() {
        closeCamera()
        stopBackgroundThread()
    }

    private fun getCameraId(position: CameraPosition): String? {
        val targetFacing = if (position == CameraPosition.FRONT) {
            CameraCharacteristics.LENS_FACING_FRONT
        } else {
            CameraCharacteristics.LENS_FACING_BACK
        }
        for (id in cameraManager.cameraIdList) {
            val facing = cameraManager.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING)
            if (facing == targetFacing) return id
        }
        return cameraManager.cameraIdList.firstOrNull()
    }
}
