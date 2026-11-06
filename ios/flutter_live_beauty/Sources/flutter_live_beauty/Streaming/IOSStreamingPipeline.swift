import CoreMedia
import CoreVideo
import Flutter
import Foundation

/**
 * Streaming frame pipeline for iOS.
 * Dispatches processed CVPixelBuffers to Flutter EventChannel and streaming adapters.
 */
public class IOSStreamingPipeline {
    private var eventSink: FlutterEventSink?
    public var isStreaming: Bool = false
    public var droppedFramesCount: Int = 0
    private var isDispatching = false
    private let lock = NSLock()

    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }

    public func start() {
        isStreaming = true
        droppedFramesCount = 0
    }

    public func stop() {
        isStreaming = false
    }

    public func onNewFrame(pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        guard isStreaming else { return }

        lock.lock()
        if isDispatching {
            droppedFramesCount += 1
            lock.unlock()
            return
        }
        isDispatching = true
        lock.unlock()

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let timestampNs = Int(CMTimeGetSeconds(timestamp) * 1_000_000_000.0)

        let frameMap: [String: Any] = [
            "width": width,
            "height": height,
            "rotation": 0,
            "timestampNs": timestampNs,
            "format": "bgra32",
            "stride": CVPixelBufferGetBytesPerRow(pixelBuffer)
        ]

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.eventSink?(frameMap)
            self.lock.lock()
            self.isDispatching = false
            self.lock.unlock()
        }
    }
}
