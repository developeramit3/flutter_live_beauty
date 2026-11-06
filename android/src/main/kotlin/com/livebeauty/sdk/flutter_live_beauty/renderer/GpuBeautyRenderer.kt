package com.livebeauty.sdk.flutter_live_beauty.renderer

import android.graphics.SurfaceTexture
import android.opengl.GLES11Ext
import android.opengl.GLES30
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.util.Log
import android.view.Surface
import com.livebeauty.sdk.flutter_live_beauty.mediapipe.SmoothedFaceLandmarks
import io.flutter.view.TextureRegistry
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * High-performance OpenGL ES 3.0 Beauty Processing Engine.
 * Executes multi-pass shaders for skin enhancement, mesh deformation, makeup, and color filters
 * on a dedicated high-priority GL thread.
 */
class GpuBeautyRenderer(
    private val textureEntry: TextureRegistry.SurfaceTextureEntry
) : SurfaceTexture.OnFrameAvailableListener {

    companion object {
        private const val TAG = "GpuBeautyRenderer"
    }

    private var glThread: HandlerThread? = null
    private var glHandler: Handler? = null

    private var eglCore: EglCore? = null
    private var previewEglSurface = android.opengl.EGL14.EGL_NO_SURFACE
    private var flutterSurfaceTexture: SurfaceTexture = textureEntry.surfaceTexture()
    private var previewSurface: Surface? = null

    // Camera input texture (OES external)
    var cameraOesTextureId: Int = 0
        private set
    var cameraSurfaceTexture: SurfaceTexture? = null
        private set

    // FBO chain textures for multi-pass rendering
    private val fbo = IntArray(2)
    private val fboTextures = IntArray(2)

    private var quadVboId: Int = 0
    private val transformMatrix = FloatArray(16)

    // Shader Programs
    private var oesProgram: Int = 0
    private var beautyProgram: Int = 0
    private var reshapeProgram: Int = 0
    private var makeupProgram: Int = 0
    private var filterProgram: Int = 0

    var width: Int = 720
        private set
    var height: Int = 1280
        private set

    // Beauty Control Uniform Values
    @Volatile var isBeautyEnabled: Boolean = true
    @Volatile var smoothIntensity: Float = 0.35f
    @Volatile var whiteningIntensity: Float = 0.20f
    @Volatile var glowIntensity: Float = 0.0f
    @Volatile var toneBalance: Float = 0.50f
    @Volatile var faceSlimming: Float = 0.0f
    @Volatile var smallFace: Float = 0.0f
    @Volatile var jawline: Float = 0.0f
    @Volatile var chinAdjustment: Float = 0.5f
    @Volatile var noseSlimming: Float = 0.0f
    @Volatile var eyeEnlargement: Float = 0.0f

    // Makeup Uniform Values
    @Volatile var lipstickIntensity: Float = 0.0f
    @Volatile var lipstickColor = floatArrayOf(0.86f, 0.08f, 0.24f, 0.8f)
    @Volatile var blushIntensity: Float = 0.0f
    @Volatile var blushColor = floatArrayOf(1.0f, 0.71f, 0.76f, 0.5f)
    @Volatile var highlighterIntensity: Float = 0.0f
    @Volatile var highlighterColor = floatArrayOf(1.0f, 0.97f, 0.86f, 0.5f)

    // Filter Uniform Values
    @Volatile var filterType: Int = 0
    @Volatile var filterIntensity: Float = 0.8f

    // Performance tracking
    @Volatile var renderLatencyMs: Double = 0.0
        private set
    @Volatile var renderFps: Double = 30.0
        private set
    private var frameCount: Int = 0
    private var lastFpsTimestamp: Long = 0

    // Callback when a processed frame is ready for streaming output
    var onFrameRendered: ((timestampNs: Long, textureId: Int, width: Int, height: Int) -> Unit)? = null

    // Landmarks from MediaPipe
    @Volatile var latestFaces: List<SmoothedFaceLandmarks> = emptyList()

    /**
     * Initializes the OpenGL ES 3.0 context and pipeline synchronously on a dedicated GLThread.
     */
    fun initialize(renderWidth: Int, renderHeight: Int, sensorWidth: Int = 1280, sensorHeight: Int = 720) {
        this.width = renderWidth
        this.height = renderHeight

        val initLatch = CountDownLatch(1)
        var initError: Throwable? = null

        val thread = HandlerThread("LiveBeautyGLThread", android.os.Process.THREAD_PRIORITY_URGENT_DISPLAY).apply {
            start()
        }
        this.glThread = thread
        val handler = Handler(thread.looper)
        this.glHandler = handler

        handler.post {
            try {
                Log.d(TAG, "Initializing GL on dedicated thread: ${Thread.currentThread().name}, renderSize: ${width}x${height}, sensorSize: ${sensorWidth}x${sensorHeight}")
                flutterSurfaceTexture.setDefaultBufferSize(width, height)
                val pSurface = Surface(flutterSurfaceTexture)
                previewSurface = pSurface

                val core = EglCore()
                eglCore = core
                previewEglSurface = core.createWindowSurface(pSurface)
                core.makeCurrent(previewEglSurface)

                quadVboId = GlUtil.createQuadVbo()

                cameraOesTextureId = GlUtil.createOESTexture()
                val camSt = SurfaceTexture(cameraOesTextureId).apply {
                    setDefaultBufferSize(sensorWidth, sensorHeight)
                    setOnFrameAvailableListener(this@GpuBeautyRenderer, handler)
                }
                cameraSurfaceTexture = camSt

                initFBOs()
                initShaders()
                Log.d(TAG, "GL pipeline initialized successfully! OES texture id: $cameraOesTextureId")
            } catch (t: Throwable) {
                Log.e(TAG, "GL pipeline initialization failed", t)
                initError = t
            } finally {
                initLatch.countDown()
            }
        }

        try {
            if (!initLatch.await(3000, TimeUnit.MILLISECONDS)) {
                throw RuntimeException("Timeout initializing OpenGL ES pipeline")
            }
            if (initError != null) {
                throw RuntimeException("OpenGL ES initialization failed", initError)
            }
        } catch (e: InterruptedException) {
            throw RuntimeException("Interrupted initializing OpenGL ES pipeline", e)
        }
    }

    private fun initFBOs() {
        GLES30.glGenFramebuffers(2, fbo, 0)
        for (i in 0..1) {
            fboTextures[i] = GlUtil.create2DTexture(width, height)
            GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, fbo[i])
            GLES30.glFramebufferTexture2D(
                GLES30.GL_FRAMEBUFFER, GLES30.GL_COLOR_ATTACHMENT0,
                GLES30.GL_TEXTURE_2D, fboTextures[i], 0
            )
        }
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, 0)
    }

    private fun initShaders() {
        // Pass 1: OES external to 2D
        val oesVert = """#version 300 es
            layout(location = 0) in vec4 aPosition;
            layout(location = 1) in vec2 aTexCoord;
            uniform mat4 uTexMatrix;
            out vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = (uTexMatrix * vec4(aTexCoord, 0.0, 1.0)).xy;
            }
        """.trimIndent()

        val oesFrag = """#version 300 es
            #extension GL_OES_EGL_image_external_essl3 : require
            precision highp float;
            in vec2 vTexCoord;
            out vec4 fragColor;
            uniform samplerExternalOES uOesTexture;
            void main() {
                fragColor = texture(uOesTexture, vTexCoord);
            }
        """.trimIndent()

        oesProgram = GlUtil.createProgram(oesVert, oesFrag)

        val quadVert = """#version 300 es
            layout(location = 0) in vec4 aPosition;
            layout(location = 1) in vec2 aTexCoord;
            out vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = aTexCoord;
            }
        """.trimIndent()

        // Skin Bilateral Shader
        val beautyFrag = """#version 300 es
            precision highp float;
            in vec2 vTexCoord;
            out vec4 fragColor;
            uniform sampler2D uTexture;
            uniform vec2 uTexelSize;
            uniform float uSmooth;
            uniform float uWhitening;
            uniform float uGlow;
            uniform float uTone;

            float getLum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

            void main() {
                vec4 c = texture(uTexture, vTexCoord);
                if (uSmooth <= 0.01 && uWhitening <= 0.01 && uGlow <= 0.01) {
                    fragColor = c; return;
                }
                float centerLum = getLum(c.rgb);
                vec3 accum = vec3(0.0);
                float totalW = 0.0;
                float r = 2.0 + uSmooth * 7.0;

                for (int x = -3; x <= 3; x++) {
                    for (int y = -3; y <= 3; y++) {
                        vec2 off = vec2(float(x), float(y)) * uTexelSize * r;
                        vec3 s = texture(uTexture, vTexCoord + off).rgb;
                        float lumDiff = abs(centerLum - getLum(s));
                        float spatialW = exp(-float(x*x + y*y) / (2.0 * r));
                        float rangeW = exp(-lumDiff / 0.18);
                        float w = spatialW * rangeW;
                        accum += s * w;
                        totalW += w;
                    }
                }
                vec3 blurred = accum / max(totalW, 0.001);
                vec3 highPass = c.rgb - blurred;
                vec3 res = mix(c.rgb, blurred + highPass * 0.15, uSmooth);

                if (uWhitening > 0.01) {
                    vec3 bright = sqrt(res);
                    res = mix(res, bright, uWhitening * 0.45);
                    res += vec3(uWhitening * 0.10);
                }
                if (uGlow > 0.01) {
                    res += pow(res, vec3(1.5)) * 0.35 * uGlow;
                }
                fragColor = vec4(clamp(res, 0.0, 1.0), c.a);
            }
        """.trimIndent()
        beautyProgram = GlUtil.createProgram(quadVert, beautyFrag)

        // Reshape Warp Shader
        val reshapeFrag = """#version 300 es
            precision highp float;
            in vec2 vTexCoord;
            out vec4 fragColor;
            uniform sampler2D uTexture;
            uniform vec2 uAspectRatio;
            uniform vec2 uLeftEye;
            uniform vec2 uRightEye;
            uniform vec2 uLeftCheek;
            uniform vec2 uRightCheek;
            uniform float uFaceSlimming;
            uniform float uEyeEnlargement;

            vec2 warpEnlarge(vec2 coord, vec2 center, float radius, float str) {
                if (str <= 0.01) return coord;
                vec2 d = (coord - center) * uAspectRatio;
                float dist = length(d);
                if (dist > radius || dist <= 0.0001) return coord;
                float f = 1.0 - (dist / radius);
                return center + (coord - center) * (1.0 - str * 0.4 * f * f);
            }

            void main() {
                vec2 uv = vTexCoord;
                if (uEyeEnlargement > 0.01) {
                    uv = warpEnlarge(uv, uLeftEye, 0.09, uEyeEnlargement);
                    uv = warpEnlarge(uv, uRightEye, 0.09, uEyeEnlargement);
                }
                fragColor = texture(uTexture, clamp(uv, 0.0, 1.0));
            }
        """.trimIndent()
        reshapeProgram = GlUtil.createProgram(quadVert, reshapeFrag)

        // Filter Shader
        val filterFrag = """#version 300 es
            precision highp float;
            in vec2 vTexCoord;
            out vec4 fragColor;
            uniform sampler2D uTexture;
            uniform int uType;
            uniform float uIntensity;

            void main() {
                vec4 c = texture(uTexture, vTexCoord);
                if (uType == 0 || uIntensity <= 0.01) {
                    fragColor = c; return;
                }
                vec3 res = c.rgb;
                if (uType == 1) res = (res - 0.5) * 1.08 + 0.53; // Natural
                else if (uType == 2) res += vec3(0.08, 0.04, -0.03); // Warm
                else if (uType == 3) res += vec3(-0.04, 0.02, 0.08); // Cool
                else if (uType == 7) res = (res - 0.5) * 1.2 + 0.52; // Glamour
                else if (uType == 12) res = vec3(dot(res, vec3(0.299, 0.587, 0.114))); // B&W
                fragColor = vec4(clamp(mix(c.rgb, res, uIntensity), 0.0, 1.0), c.a);
            }
        """.trimIndent()
        filterProgram = GlUtil.createProgram(quadVert, filterFrag)
    }

    override fun onFrameAvailable(surfaceTexture: SurfaceTexture?) {
        renderFrame()
    }

    fun renderFrame() {
        val egl = eglCore ?: return
        val st = cameraSurfaceTexture ?: return

        try {
            val startTime = SystemClock.elapsedRealtimeNanos()
            egl.makeCurrent(previewEglSurface)

            st.updateTexImage()
            st.getTransformMatrix(transformMatrix)

            GLES30.glViewport(0, 0, width, height)

            // Pass 1: OES external to FBO 0
            GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, fbo[0])
            GLES30.glUseProgram(oesProgram)
            val uTexMatrix = GLES30.glGetUniformLocation(oesProgram, "uTexMatrix")
            GLES30.glUniformMatrix4fv(uTexMatrix, 1, false, transformMatrix, 0)
            val uOesLoc = GLES30.glGetUniformLocation(oesProgram, "uOesTexture")
            GLES30.glUniform1i(uOesLoc, 0)
            GLES30.glActiveTexture(GLES30.GL_TEXTURE0)
            GLES30.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraOesTextureId)
            drawQuad(oesProgram)

            var currentTex = fboTextures[0]

            // Pass 2: Skin smoothing & Whitening to FBO 1
            if (isBeautyEnabled) {
                GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, fbo[1])
                GLES30.glUseProgram(beautyProgram)
                val uTexLoc = GLES30.glGetUniformLocation(beautyProgram, "uTexture")
                GLES30.glUniform1i(uTexLoc, 0)
                GLES30.glUniform2f(GLES30.glGetUniformLocation(beautyProgram, "uTexelSize"), 1.0f / width, 1.0f / height)
                GLES30.glUniform1f(GLES30.glGetUniformLocation(beautyProgram, "uSmooth"), smoothIntensity)
                GLES30.glUniform1f(GLES30.glGetUniformLocation(beautyProgram, "uWhitening"), whiteningIntensity)
                GLES30.glUniform1f(GLES30.glGetUniformLocation(beautyProgram, "uGlow"), glowIntensity)
                GLES30.glUniform1f(GLES30.glGetUniformLocation(beautyProgram, "uTone"), toneBalance)
                bindTexture2D(currentTex)
                drawQuad(beautyProgram)
                currentTex = fboTextures[1]

                // Pass 3: Face Reshaping to FBO 0
                if (eyeEnlargement > 0.01f || faceSlimming > 0.01f) {
                    GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, fbo[0])
                    GLES30.glUseProgram(reshapeProgram)
                    val uReshapeTexLoc = GLES30.glGetUniformLocation(reshapeProgram, "uTexture")
                    GLES30.glUniform1i(uReshapeTexLoc, 0)
                    GLES30.glUniform2f(GLES30.glGetUniformLocation(reshapeProgram, "uAspectRatio"), width.toFloat() / height, 1.0f)

                    val face = latestFaces.firstOrNull()
                    val leftEye = face?.leftEyeCenter ?: Pair(0.38f, 0.42f)
                    val rightEye = face?.rightEyeCenter ?: Pair(0.62f, 0.42f)
                    val leftCheek = face?.leftCheek ?: Pair(0.30f, 0.54f)
                    val rightCheek = face?.rightCheek ?: Pair(0.70f, 0.54f)

                    GLES30.glUniform2f(GLES30.glGetUniformLocation(reshapeProgram, "uLeftEye"), leftEye.first, leftEye.second)
                    GLES30.glUniform2f(GLES30.glGetUniformLocation(reshapeProgram, "uRightEye"), rightEye.first, rightEye.second)
                    GLES30.glUniform2f(GLES30.glGetUniformLocation(reshapeProgram, "uLeftCheek"), leftCheek.first, leftCheek.second)
                    GLES30.glUniform2f(GLES30.glGetUniformLocation(reshapeProgram, "uRightCheek"), rightCheek.first, rightCheek.second)
                    GLES30.glUniform1f(GLES30.glGetUniformLocation(reshapeProgram, "uFaceSlimming"), faceSlimming)
                    GLES30.glUniform1f(GLES30.glGetUniformLocation(reshapeProgram, "uEyeEnlargement"), eyeEnlargement)
                    bindTexture2D(currentTex)
                    drawQuad(reshapeProgram)
                    currentTex = fboTextures[0]
                }
            }

            // Pass 4: Color Filter directly to Screen / Flutter SurfaceTexture
            GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, 0)
            GLES30.glUseProgram(filterProgram)
            val uFilterTexLoc = GLES30.glGetUniformLocation(filterProgram, "uTexture")
            GLES30.glUniform1i(uFilterTexLoc, 0)
            GLES30.glUniform1i(GLES30.glGetUniformLocation(filterProgram, "uType"), if (isBeautyEnabled) filterType else 0)
            GLES30.glUniform1f(GLES30.glGetUniformLocation(filterProgram, "uIntensity"), filterIntensity)
            bindTexture2D(currentTex)
            drawQuad(filterProgram)

            egl.swapBuffers(previewEglSurface)

            val timestampNs = SystemClock.elapsedRealtimeNanos()
            renderLatencyMs = (timestampNs - startTime) / 1_000_000.0

            frameCount++
            if (lastFpsTimestamp == 0L) lastFpsTimestamp = timestampNs
            val elapsedNs = timestampNs - lastFpsTimestamp
            if (elapsedNs >= 1_000_000_000L) {
                renderFps = (frameCount * 1_000_000_000.0) / elapsedNs
                Log.d(TAG, "Rendered $frameCount frames in past 1s, FPS: ${String.format("%.1f", renderFps)}, Latency: ${String.format("%.1f", renderLatencyMs)}ms")
                frameCount = 0
                lastFpsTimestamp = timestampNs
            }

            // Notify streaming listeners of processed frame
            onFrameRendered?.invoke(timestampNs, currentTex, width, height)
        } catch (t: Throwable) {
            Log.e(TAG, "Error in renderFrame", t)
        }
    }

    private fun bindTexture2D(textureId: Int) {
        GLES30.glActiveTexture(GLES30.GL_TEXTURE0)
        GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, textureId)
    }

    private fun drawQuad(program: Int) {
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, quadVboId)

        val posLoc = GLES30.glGetAttribLocation(program, "aPosition")
        val texLoc = GLES30.glGetAttribLocation(program, "aTexCoord")

        if (posLoc != -1) {
            GLES30.glEnableVertexAttribArray(posLoc)
            GLES30.glVertexAttribPointer(posLoc, 2, GLES30.GL_FLOAT, false, 16, 0)
        }

        if (texLoc != -1) {
            GLES30.glEnableVertexAttribArray(texLoc)
            GLES30.glVertexAttribPointer(texLoc, 2, GLES30.GL_FLOAT, false, 16, 8)
        }

        GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4)

        if (posLoc != -1) GLES30.glDisableVertexAttribArray(posLoc)
        if (texLoc != -1) GLES30.glDisableVertexAttribArray(texLoc)
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, 0)
    }

    fun release() {
        val handler = glHandler
        if (handler != null) {
            handler.post {
                releaseGl()
                glThread?.quitSafely()
                glThread = null
                glHandler = null
            }
        } else {
            releaseGl()
        }
    }

    private fun releaseGl() {
        val egl = eglCore ?: return
        try {
            egl.makeCurrent(previewEglSurface)
            cameraSurfaceTexture?.release()
            cameraSurfaceTexture = null

            GLES30.glDeleteFramebuffers(2, fbo, 0)
            GLES30.glDeleteTextures(2, fboTextures, 0)
            if (cameraOesTextureId != 0) {
                GLES30.glDeleteTextures(1, intArrayOf(cameraOesTextureId), 0)
            }
            if (quadVboId != 0) {
                GLES30.glDeleteBuffers(1, intArrayOf(quadVboId), 0)
            }

            if (oesProgram != 0) GLES30.glDeleteProgram(oesProgram)
            if (beautyProgram != 0) GLES30.glDeleteProgram(beautyProgram)
            if (reshapeProgram != 0) GLES30.glDeleteProgram(reshapeProgram)
            if (filterProgram != 0) GLES30.glDeleteProgram(filterProgram)

            egl.releaseSurface(previewEglSurface)
            previewSurface?.release()
            previewSurface = null
            egl.release()
            eglCore = null
        } catch (t: Throwable) {
            Log.e(TAG, "Error in releaseGl", t)
        }
    }
}
