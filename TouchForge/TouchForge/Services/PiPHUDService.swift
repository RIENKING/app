import Foundation
import AVKit
import AVFoundation
import UIKit
import SwiftUI

/// Official Apple Picture-in-Picture (AVKit) floating HUD renderer.
/// Uses AVSampleBufferDisplayLayer to render a live status & crosshair reference card
/// that iOS officially permits to float above other apps in PiP mode.
@MainActor
final class PiPHUDService: NSObject, ObservableObject {
    @Published private(set) var isPiPSupported: Bool = AVPictureInPictureController.isPictureInPictureSupported()
    @Published private(set) var isPiPActive: Bool = false
    @Published private(set) var statusMessage: String = "Ready"

    let displayLayer = AVSampleBufferDisplayLayer()
    private var pipController: AVPictureInPictureController?
    private var renderTimer: Timer?
    private var currentProfileName: String = "TouchForge"
    private var currentCrosshair: CrosshairConfig = CrosshairConfig()
    private var currentMacroStatus: String = "Idle"

    override init() {
        super.init()
        configureAudioSession()
        configurePiP()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func configurePiP() {
        guard isPiPSupported else {
            statusMessage = "PiP not supported on this device"
            return
        }
        displayLayer.videoGravity = .resizeAspect
        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        self.pipController = controller
    }

    func updateHUD(profileName: String, crosshair: CrosshairConfig, macroStatus: String) {
        self.currentProfileName = profileName
        self.currentCrosshair = crosshair
        self.currentMacroStatus = macroStatus
        enqueueFrame()
    }

    func togglePiP() {
        guard let pipController else { return }
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            enqueueFrame()
            startFrameTimer()
            pipController.startPictureInPicture()
        }
    }

    private func startFrameTimer() {
        renderTimer?.invalidate()
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.enqueueFrame()
            }
        }
    }

    private func stopFrameTimer() {
        renderTimer?.invalidate()
        renderTimer = nil
    }

    private func enqueueFrame() {
        guard let pixelBuffer = renderHUDPixelBuffer(width: 480, height: 270) else { return }
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDesc
        )
        guard let formatDesc else { return }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 2),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDesc,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )

        if let sampleBuffer {
            if displayLayer.status == .failed {
                displayLayer.flush()
            }
            displayLayer.enqueue(sampleBuffer)
        }
    }

    private func renderHUDPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        // Dark tactical HUD background
        context.setFillColor(UIColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1.0).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Subtle border
        context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(3)
        context.stroke(CGRect(x: 4, y: 4, width: width - 8, height: height - 8))

        // Draw crosshair preview at center
        let cx = CGFloat(width) / 2.0
        let cy = CGFloat(height) / 2.0
        let arm = CGFloat(min(max(currentCrosshair.size, 18), 54))
        let gap = CGFloat(currentCrosshair.centerGap)
        let color = UIColor(
            red: currentCrosshair.color.red,
            green: currentCrosshair.color.green,
            blue: currentCrosshair.color.blue,
            alpha: currentCrosshair.opacity
        )
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(CGFloat(currentCrosshair.thickness))
        context.move(to: CGPoint(x: cx - arm, y: cy))
        context.addLine(to: CGPoint(x: cx - gap, y: cy))
        context.move(to: CGPoint(x: cx + gap, y: cy))
        context.addLine(to: CGPoint(x: cx + arm, y: cy))
        context.move(to: CGPoint(x: cx, y: cy - arm))
        context.addLine(to: CGPoint(x: cx, y: cy - gap))
        context.move(to: CGPoint(x: cx, y: cy + gap))
        context.addLine(to: CGPoint(x: cx, y: cy + arm))
        context.strokePath()

        if currentCrosshair.showCenterDot {
            context.setFillColor(color.cgColor)
            let d = CGFloat(currentCrosshair.dotSize)
            context.fillEllipse(in: CGRect(x: cx - d / 2, y: cy - d / 2, width: d, height: d))
        }

        // Draw HUD labels via UIGraphicsPushContext
        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 15, weight: .medium),
            .foregroundColor: UIColor.systemTeal
        ]
        NSString(string: "TouchForge HUD • \(currentProfileName)").draw(at: CGPoint(x: 18, y: 14), withAttributes: titleAttrs)
        NSString(string: "Macro: \(currentMacroStatus)").draw(at: CGPoint(x: 18, y: CGFloat(height) - 34), withAttributes: subAttrs)
        UIGraphicsPopContext()

        return buffer
    }
}

extension PiPHUDService: AVPictureInPictureControllerDelegate {
    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            self.isPiPActive = true
            self.statusMessage = "Floating PiP HUD Active"
        }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            self.isPiPActive = false
            self.statusMessage = "Ready"
            self.stopFrameTimer()
        }
    }
}

extension PiPHUDService: AVPictureInPictureSampleBufferPlaybackDelegate {
    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}
    nonisolated func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }
    nonisolated func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        false
    }
    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

/// Host view that embeds the AVSampleBufferDisplayLayer inside SwiftUI so AVPictureInPictureController can launch cleanly.
struct PiPHUDHostView: UIViewRepresentable {
    let displayLayer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> UIView {
        let view = PiPLayerContainerView()
        view.attach(displayLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private final class PiPLayerContainerView: UIView {
        private weak var attachedLayer: AVSampleBufferDisplayLayer?

        func attach(_ layer: AVSampleBufferDisplayLayer) {
            self.attachedLayer = layer
            layer.frame = bounds
            self.layer.addSublayer(layer)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            attachedLayer?.frame = bounds
        }
    }
}
