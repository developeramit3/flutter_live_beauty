import Flutter
import UIKit

public class FlutterLiveBeautyPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var methodChannel: FlutterMethodChannel?
    private var statsChannel: FlutterEventChannel?
    private var framesChannel: FlutterEventChannel?

    private var textureRegistry: FlutterTextureRegistry?
    private var textureId: Int64 = -1

    private var camera: AVFoundationCamera?
    private var renderer: MetalBeautyRenderer?
    private var detector: MediaPipeFaceDetectorIOS?
    private let streamingPipeline = IOSStreamingPipeline()

    private var statsSink: FlutterEventSink?
    private var statsTimer: Timer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterLiveBeautyPlugin()
        instance.textureRegistry = registrar.textures()

        let channel = FlutterMethodChannel(name: "com.livebeauty.sdk/methods", binaryMessenger: registrar.messenger())
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        let stats = FlutterEventChannel(name: "com.livebeauty.sdk/stats", binaryMessenger: registrar.messenger())
        instance.statsChannel = stats
        stats.setStreamHandler(instance)

        let frames = FlutterEventChannel(name: "com.livebeauty.sdk/frames", binaryMessenger: registrar.messenger())
        instance.framesChannel = frames
        frames.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "hasCameraPermission":
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            result(status == .authorized)

        case "requestCameraPermission":
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized {
                result(true)
            } else if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        result(granted)
                    }
                }
            } else {
                result(false)
            }

        case "initializeCamera":
            handleInitializeCamera(call, result: result)

        case "disposeCamera":
            handleDisposeCamera(result: result)

        case "switchCamera":
            camera?.switchCamera { newPos in
                result(newPos == .rear ? "rear" : "front")
            }

        case "setZoom":
            if let args = call.arguments as? [String: Any],
               let zoom = args["zoom"] as? NSNumber {
                camera?.setZoom(CGFloat(truncating: zoom))
            }
            result(nil)

        case "setFlash":
            if let args = call.arguments as? [String: Any],
               let enable = args["enable"] as? Bool {
                camera?.setFlash(enable)
            }
            result(nil)

        case "setBeautyEnabled":
            if let args = call.arguments as? [String: Any],
               let enabled = args["enabled"] as? Bool {
                renderer?.isBeautyEnabled = enabled
            }
            result(nil)

        case "setFeatureIntensity":
            handleSetFeatureIntensity(call)
            result(nil)

        case "updateBeautyConfig":
            if let config = call.arguments as? [String: Any] {
                applyConfigMap(config)
            }
            result(nil)

        case "setFilter":
            if let args = call.arguments as? [String: Any],
               let filterId = args["filterId"] as? String {
                let intensity = (args["intensity"] as? NSNumber)?.floatValue ?? 80.0
                renderer?.filterType = mapFilterId(filterId)
                renderer?.filterIntensity = intensity / 100.0
            }
            result(nil)

        case "startStreamingOutput":
            streamingPipeline.start()
            result(nil)

        case "stopStreamingOutput":
            streamingPipeline.stop()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitializeCamera(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let registry = textureRegistry else {
            result(FlutterError(code: "NO_REGISTRY", message: "TextureRegistry unavailable", details: nil))
            return
        }

        let args = call.arguments as? [String: Any] ?? [:]
        let posStr = args["position"] as? String ?? "front"
        let pos: BeautyCameraPositionIOS = (posStr == "rear") ? .rear : .front
        let width = args["width"] as? Int ?? 1280
        let height = args["height"] as? Int ?? 720

        let metalRenderer = MetalBeautyRenderer()
        self.renderer = metalRenderer

        let tId = registry.register(metalRenderer)
        self.textureId = tId

        metalRenderer.onTextureFrameAvailable = { [weak self] in
            guard let self = self, self.textureId >= 0 else { return }
            registry.textureFrameAvailable(self.textureId)
        }

        metalRenderer.onFrameRendered = { [weak self] pixelBuffer, timestamp in
            self?.streamingPipeline.onNewFrame(pixelBuffer: pixelBuffer, timestamp: timestamp)
            self?.detector?.processPixelBufferAsync(pixelBuffer, timestamp: timestamp)
        }

        let cam = AVFoundationCamera()
        self.camera = cam
        cam.frameReceiver = metalRenderer

        let det = MediaPipeFaceDetectorIOS()
        self.detector = det

        cam.openCamera(position: pos, width: width, height: height) { success in
            if success {
                result([
                    "textureId": tId,
                    "previewWidth": width,
                    "previewHeight": height
                ])
            } else {
                result(FlutterError(code: "CAM_ERROR", message: "Failed to open camera", details: nil))
            }
        }
    }

    private func handleSetFeatureIntensity(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any],
              let feature = args["feature"] as? String,
              let intensity = args["intensity"] as? NSNumber else { return }
        let factor = intensity.floatValue / 100.0
        guard let rend = renderer else { return }

        switch feature {
        case "skinSmoothing": rend.smoothIntensity = factor
        case "skinWhitening": rend.whiteningIntensity = factor
        case "skinGlow": rend.glowIntensity = factor
        case "faceSlimming": rend.faceSlimming = factor
        case "eyeEnlargement": rend.eyeEnlargement = factor
        default: break
        }
    }

    private func applyConfigMap(_ map: [String: Any]) {
        guard let rend = renderer else { return }
        if let enabled = map["enabled"] as? Bool {
            rend.isBeautyEnabled = enabled
        }
        if let intensities = map["featureIntensities"] as? [String: NSNumber] {
            for (key, val) in intensities {
                let factor = val.floatValue / 100.0
                switch key {
                case "skinSmoothing": rend.smoothIntensity = factor
                case "skinWhitening": rend.whiteningIntensity = factor
                case "skinGlow": rend.glowIntensity = factor
                case "faceSlimming": rend.faceSlimming = factor
                case "eyeEnlargement": rend.eyeEnlargement = factor
                default: break
                }
            }
        }
    }

    private func mapFilterId(_ id: String) -> Int {
        switch id {
        case "original": return 0
        case "natural": return 1
        case "warm": return 2
        case "cool": return 3
        case "glamour": return 7
        case "black_and_white": return 12
        default: return 0
        }
    }

    private func handleDisposeCamera(result: FlutterResult) {
        statsTimer?.invalidate()
        statsTimer = nil
        camera?.stopCamera()
        camera = nil
        if textureId >= 0 {
            textureRegistry?.unregisterTexture(textureId)
            textureId = -1
        }
        renderer = nil
        detector = nil
        result(nil)
    }

    // FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if arguments as? String == "frames" {
            streamingPipeline.setEventSink(events)
        } else {
            statsSink = events
            startStatsTimer()
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        statsTimer?.invalidate()
        statsTimer = nil
        statsSink = nil
        streamingPipeline.setEventSink(nil)
        return nil
    }

    private func startStatsTimer() {
        statsTimer?.invalidate()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let rend = self.renderer, let sink = self.statsSink else { return }
            let stats: [String: Any] = [
                "renderFps": rend.renderFps,
                "inferenceFps": 30.0,
                "renderLatencyMs": rend.renderLatencyMs,
                "inferenceLatencyMs": self.detector?.lastInferenceLatencyMs ?? 0.0,
                "droppedFrames": self.streamingPipeline.droppedFramesCount,
                "detectedFacesCount": self.detector?.activeFaces.count ?? 0,
                "frameWidth": self.camera?.previewWidth ?? 1280,
                "frameHeight": self.camera?.previewHeight ?? 720
            ]
            sink(stats)
        }
    }
}
