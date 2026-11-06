package com.livebeauty.sdk.flutter_live_beauty.streaming

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Native streaming frame pipeline.
 * Dispatches processed video frames to Flutter event channels and custom streaming SDK adapters.
 * Implements strict zero-copy / single-frame buffer policy to prevent queue buildup.
 */
class StreamingFramePipeline {
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    var isStreaming: Boolean = false
        private set

    @Volatile
    var droppedFramesCount: Int = 0
        private set

    private val isDispatching = AtomicBoolean(false)

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun start() {
        isStreaming = true
        droppedFramesCount = 0
    }

    fun stop() {
        isStreaming = false
    }

    /**
     * Dispatches processed frame metadata and texture ID.
     * Stale frames are immediately dropped if previous frame delivery is still in flight.
     */
    fun onNewProcessedFrame(
        timestampNs: Long,
        textureId: Int,
        width: Int,
        height: Int,
        rotation: Int = 0
    ) {
        if (!isStreaming) return

        if (!isDispatching.compareAndSet(false, true)) {
            // Drop stale frame to keep processing latency < 33ms
            droppedFramesCount++
            return
        }

        val frameMap = mapOf(
            "width" to width,
            "height" to height,
            "rotation" to rotation,
            "timestampNs" to timestampNs,
            "format" to "gpuTexture",
            "textureId" to textureId,
            "stride" to (width * 4)
        )

        mainHandler.post {
            try {
                eventSink?.success(frameMap)
            } catch (_: Exception) {
            } finally {
                isDispatching.set(false)
            }
        }
    }

    fun release() {
        stop()
        eventSink = null
    }
}
