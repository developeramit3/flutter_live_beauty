import CoreVideo
import Flutter
import Foundation
import Metal

/**
 * Metal-accelerated beauty processing renderer for iOS.
 * Implements FlutterTexture for zero-copy texture display on Flutter UI.
 */
public class MetalBeautyRenderer: NSObject, FlutterTexture, CameraFrameReceiver {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var textureCache: CVMetalTextureCache?

    private var currentPixelBuffer: CVPixelBuffer?
    private let pixelBufferLock = NSLock()

    public var isBeautyEnabled: Bool = true
    public var smoothIntensity: Float = 0.35
    public var whiteningIntensity: Float = 0.20
    public var glowIntensity: Float = 0.0
    public var faceSlimming: Float = 0.0
    public var eyeEnlargement: Float = 0.0
    public var filterType: Int = 0
    public var filterIntensity: Float = 0.8

    public var renderLatencyMs: Double = 0.0
    public var renderFps: Double = 30.0
    private var frameCount: Int = 0
    private var lastFpsTime: CFAbsoluteTime = 0.0

    public var onFrameRendered: ((CVPixelBuffer, CMTime) -> Void)?
    public var onTextureFrameAvailable: (() -> Void)?

    public override init() {
        guard let mtlDevice = MTLCreateSystemDefaultDevice(),
              let queue = mtlDevice.makeCommandQueue() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = mtlDevice
        self.commandQueue = queue
        super.init()

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, mtlDevice, nil, &textureCache)
    }

    // CameraFrameReceiver
    public func onCameraPixelBufferReceived(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        let start = CFAbsoluteTimeGetCurrent()

        pixelBufferLock.lock()
        currentPixelBuffer = pixelBuffer
        pixelBufferLock.unlock()

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
        renderLatencyMs = elapsed

        frameCount += 1
        let now = CFAbsoluteTimeGetCurrent()
        if lastFpsTime == 0.0 { lastFpsTime = now }
        let diff = now - lastFpsTime
        if diff >= 1.0 {
            renderFps = Double(frameCount) / diff
            frameCount = 0
            lastFpsTime = now
        }

        onTextureFrameAvailable?()
        onFrameRendered?(pixelBuffer, timestamp)
    }

    // FlutterTexture protocol implementation
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        pixelBufferLock.lock()
        defer { pixelBufferLock.unlock() }

        guard let buffer = currentPixelBuffer else { return nil }
        return Unmanaged.passRetained(buffer)
    }
}
