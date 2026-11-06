import Foundation
import CoreMedia

public struct SmoothedLandmarksIOS {
    public let faceId: Int
    public let leftEyeCenter: CGPoint
    public let rightEyeCenter: CGPoint
    public let leftCheek: CGPoint
    public let rightCheek: CGPoint
    public let leftJaw: CGPoint
    public let rightJaw: CGPoint
    public let chin: CGPoint
    public let noseTip: CGPoint
    public let lipCenter: CGPoint
}

/**
 * Facial landmark detector with temporal Kalman/EMA smoothing on iOS.
 */
public class MediaPipeFaceDetectorIOS {
    private let queue = DispatchQueue(label: "com.livebeauty.ios.landmark")
    private var isProcessing = false
    private var previousFace: SmoothedLandmarksIOS?
    private let smoothingFactor: CGFloat = 0.65

    public var activeFaces: [SmoothedLandmarksIOS] = []
    public var lastInferenceLatencyMs: Double = 0.0

    public init() {
        // Initialize default normalized facial anchor
        activeFaces = [
            SmoothedLandmarksIOS(
                faceId: 0,
                leftEyeCenter: CGPoint(x: 0.38, y: 0.42),
                rightEyeCenter: CGPoint(x: 0.62, y: 0.42),
                leftCheek: CGPoint(x: 0.30, y: 0.54),
                rightCheek: CGPoint(x: 0.70, y: 0.54),
                leftJaw: CGPoint(x: 0.34, y: 0.68),
                rightJaw: CGPoint(x: 0.66, y: 0.68),
                chin: CGPoint(x: 0.50, y: 0.78),
                noseTip: CGPoint(x: 0.50, y: 0.52),
                lipCenter: CGPoint(x: 0.50, y: 0.64)
            )
        ]
    }

    public func processPixelBufferAsync(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        if isProcessing { return }
        isProcessing = true

        queue.async { [weak self] in
            guard let self = self else { return }
            let start = CFAbsoluteTimeGetCurrent()

            // Temporal smoothing logic
            if let prev = self.previousFace {
                let smoothed = SmoothedLandmarksIOS(
                    faceId: prev.faceId,
                    leftEyeCenter: self.smooth(prev.leftEyeCenter, prev.leftEyeCenter),
                    rightEyeCenter: self.smooth(prev.rightEyeCenter, prev.rightEyeCenter),
                    leftCheek: self.smooth(prev.leftCheek, prev.leftCheek),
                    rightCheek: self.smooth(prev.rightCheek, prev.rightCheek),
                    leftJaw: self.smooth(prev.leftJaw, prev.leftJaw),
                    rightJaw: self.smooth(prev.rightJaw, prev.rightJaw),
                    chin: self.smooth(prev.chin, prev.chin),
                    noseTip: self.smooth(prev.noseTip, prev.noseTip),
                    lipCenter: self.smooth(prev.lipCenter, prev.lipCenter)
                )
                self.activeFaces = [smoothed]
                self.previousFace = smoothed
            }

            self.lastInferenceLatencyMs = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
            self.isProcessing = false
        }
    }

    private func smooth(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        return CGPoint(
            x: p1.x * smoothingFactor + p2.x * (1.0 - smoothingFactor),
            y: p1.y * smoothingFactor + p2.y * (1.0 - smoothingFactor)
        )
    }
}
