import AVFoundation
import CoreMedia
import Foundation

public enum BeautyCameraPositionIOS {
    case front
    case rear
}

public protocol CameraFrameReceiver: AnyObject {
    func onCameraPixelBufferReceived(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime)
}

/**
 * High-performance AVFoundation Camera Capture Session.
 * Direct CVPixelBuffer output to Metal texture cache and beauty processing pipeline.
 */
public class AVFoundationCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.livebeauty.camera.session")

    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?

    public private(set) var currentPosition: BeautyCameraPositionIOS = .front
    public private(set) var previewWidth: Int = 1280
    public private(set) var previewHeight: Int = 720

    public weak var frameReceiver: CameraFrameReceiver?

    public func openCamera(
        position: BeautyCameraPositionIOS,
        width: Int,
        height: Int,
        completion: @escaping (Bool) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentPosition = position
            self.previewWidth = width
            self.previewHeight = height

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = (height >= 1080) ? .hd1920x1080 : .hd1280x720

            let device = self.getCaptureDevice(for: position)
            guard let device = device,
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }

            self.currentDevice = device
            if let oldInput = self.currentInput {
                self.captureSession.removeInput(oldInput)
            }
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.currentInput = input
            }

            if self.captureSession.outputs.isEmpty && self.captureSession.canAddOutput(self.videoOutput) {
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                ]
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.captureSession.addOutput(self.videoOutput)
            }

            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = (position == .front)
                }
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            DispatchQueue.main.async {
                completion(true)
            }
        }
    }

    public func switchCamera(completion: @escaping (BeautyCameraPositionIOS) -> Void) {
        let newPos: BeautyCameraPositionIOS = (currentPosition == .front) ? .rear : .front
        openCamera(position: newPos, width: previewWidth, height: previewHeight) { [weak self] success in
            guard let self = self else { return }
            completion(self.currentPosition)
        }
    }

    public func setZoom(_ zoom: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let device = self?.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
                device.videoZoomFactor = max(1.0, min(zoom, maxZoom))
                device.unlockForConfiguration()
            } catch {}
        }
    }

    public func setFlash(_ enable: Bool) {
        sessionQueue.async { [weak self] in
            guard let device = self?.currentDevice, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = enable ? .on : .off
                device.unlockForConfiguration()
            } catch {}
        }
    }

    public func stopCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func getCaptureDevice(for position: BeautyCameraPositionIOS) -> AVCaptureDevice? {
        let devicePosition: AVCaptureDevice.Position = (position == .front) ? .front : .back
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: devicePosition
        )
        return discovery.devices.first
    }

    // AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        frameReceiver?.onCameraPixelBufferReceived(pixelBuffer, timestamp: timestamp)
    }
}
