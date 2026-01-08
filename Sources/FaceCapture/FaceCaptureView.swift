//
//  FaceCaptureView.swift
//
//
//  Created by Jakub Dolejs on 19/02/2024.
//

import SwiftUI
import Combine
import AVFoundation
import VerIDCommonTypes

public struct FaceCaptureView: View {
    
    public let configuration: FaceCaptureViewConfiguration
    public let session: FaceCaptureSession
    @Binding public var result: FaceCaptureSessionResult?
    
    public var body: some View {
        SessionView(session: self.session, configuration: self.configuration, result: self.$result)
    }
    
    public init(session: FaceCaptureSession, result: Binding<FaceCaptureSessionResult?> = .constant(FaceCaptureSessionResult.cancelled), configuration: FaceCaptureViewConfiguration = .default) {
        self.session = session
        self.configuration = configuration
        self._result = result
    }
}

@available(iOS 14, *)
public struct FaceCaptureNavigationView: View {
    
    @ObservedObject private(set) public var session: FaceCaptureSession
    let onResult: OnFaceCaptureSessionResult?
    public let useBackCamera: Bool
    @State var textPrompt: String = ""
    @State var result: FaceCaptureSessionResult?
    
    public var body: some View {
        SessionView(session: self.session, configuration: FaceCaptureViewConfiguration(useBackCamera: useBackCamera, textPrompt: self.$textPrompt, showTextPrompts: false, showCancelButton: false), result: self.$result)
            .onChange(of: self.session.result) { result in
                if let result = result {
                    self.onResult?(result)
                }
            }
            .navigationTitle(self.textPrompt)
            .navigationBarTitleDisplayMode(.inline)
    }
    
    public init(session: FaceCaptureSession, useBackCamera: Bool = false, onResult: OnFaceCaptureSessionResult? = nil) {
        self.session = session
        self.onResult = onResult
        self.useBackCamera = useBackCamera
    }
}

struct SessionView: View {
    
    @ObservedObject var session: FaceCaptureSession
    @Environment(\.presentationMode) var presentationMode
    
    let cameraControl: CameraControl
    let showCancelButton: Bool
    let showTextPrompts: Bool
    
    @Binding var result: FaceCaptureSessionResult?
    @Binding var textPromptProvider: TextPromptProvider
    @Binding var promptText: String
    
    @State private var orientation: CGImagePropertyOrientation = UIDevice.current.orientation.cgImagePropertyOrientation
    @State private var videoOrientation: AVCaptureVideoOrientation?
    @State private var faceTrackingResult: FaceTrackingResult = .created(.straight)
    @State private var lineWidth: CGFloat = 10
    @State private var headAngle: (start: EulerAngle<Float>, end: EulerAngle<Float>) = (start: .init(), end: .init())
    @State private var headColor: UIColor = .gray
    @State private var isShowing3DHead: Bool = false {
        didSet {
            if self.isShowing3DHead {
                self.last3DHeadAppearanceTime = CACurrentMediaTime()
            }
        }
    }
    @State private var last3DHeadAppearanceTime: Double? = nil
    @State private var prompt: String = ""
    @State private var secondsRemainingToStart: Int = 0
    @State private var cancellables: Set<AnyCancellable> = []
    
    private var angleBearingEvaluation: AngleBearingEvaluation!
    private let useBackCamera: Bool
    private var headAppearanceInterval: TimeInterval = 3.0
    private var headAppearanceDuration: TimeInterval = 1.8
    
    var body: some View {
        GeometryReader { geometryReader in
            ZStack {
                CameraPreviewView(cameraControl: self.cameraControl, videoOrientation: self.$videoOrientation)
                    .transformEffect(self.cameraPreviewTransformFromResult(self.faceTrackingResult, viewSize: geometryReader.size))
                    .clipShape(FaceOval(faceTrackingResult: self.faceTrackingResult))
                    .onReceive(self.session.faceTrackingResult) { faceTrackingResult in
                        self.faceTrackingResult = faceTrackingResult.scaledToFitViewSize(geometryReader.size, mirrored: !self.useBackCamera)
                        if let faceWidth = faceTrackingResult.smoothedFace?.bounds.width {
                            self.lineWidth = faceWidth / 60
                        }
                        if case .faceMisaligned(let props) = faceTrackingResult {
                            let now = CACurrentMediaTime()
                            if self.last3DHeadAppearanceTime == nil {
                                self.last3DHeadAppearanceTime = now
                            }
                            let targetAngle = self.angleBearingEvaluation.angle(forBearing: faceTrackingResult.requestedBearing)
                            self.headAngle = (start: props.smoothedFace.angle, end: targetAngle)
                            let timeSinceLastHeadAppearance = now - self.last3DHeadAppearanceTime!
                            if timeSinceLastHeadAppearance > self.headAppearanceInterval {
                                self.isShowing3DHead = true
                            } else if timeSinceLastHeadAppearance > self.headAppearanceDuration {
                                self.isShowing3DHead = false
                            }
                        }
                        self.prompt = self.textPromptProvider(faceTrackingResult)
                        self.promptText = self.prompt
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        self.orientation = UIDevice.current.orientation.cgImagePropertyOrientation
                        self.videoOrientation = UIDevice.current.orientation.videoOrientation
                    }
                    .task(priority: .high) {
                        defer {
                            Task { await self.cameraControl.stop() }
                        }
                        do {
                            let cameraStream = try await self.cameraControl.start()
                            var serialNumber: UInt64 = 0
                            let startTime = CACurrentMediaTime()
                            for await sample in cameraStream {
                                if Task.isCancelled {
                                    break
                                }
                                let viewSize = geometryReader.size
                                self.session.submitImageInput(FaceCaptureSessionImageInput(serialNumber: serialNumber, time: CACurrentMediaTime()-startTime, image: sample, viewSize: viewSize))
                                serialNumber += 1
                            }
                        } catch {
                            self.session.result = .failure(capturedFaces: [], metadata: [:], error: error)
                        }
                    }
                    .onAppear {
                        self.videoOrientation = UIDevice.current.orientation.videoOrientation
                        
                        if self.session.settings.countdownSeconds > 1 {
                            (0...self.session.settings.countdownSeconds).publisher.flatMap(maxPublishers: .max(1)) {
                                Just(self.session.settings.countdownSeconds-$0).delay(for: .seconds(1), scheduler: RunLoop.main)
                            }.sink {
                                self.secondsRemainingToStart = $0
                            }.store(in: &self.cancellables)
                        }
                    }
                    .onDisappear {
                        self.cancellables.forEach { $0.cancel() }
                    }
                    .onReceive(Just(geometryReader.size)) { size in
                        switch self.faceTrackingResult {
                        case .created, .waiting:
                            let expectedFaceBounds = self.session.settings.expectedFaceBoundsInSize(size)
                            let faceTrackingResult = FaceTrackingResult.waiting(WaitingSessionProperties(requestedBearing: .straight, expectedFaceBounds: expectedFaceBounds))
                            self.faceTrackingResult = faceTrackingResult.scaledToFitViewSize(geometryReader.size, mirrored: !self.useBackCamera)
                            self.prompt = self.textPromptProvider(faceTrackingResult)
                            self.promptText = self.prompt
                        default:
                            _ = 0
                        }
                    }
                if case .faceMisaligned(let trackedFaceSessionProperties) = faceTrackingResult, self.isShowing3DHead {
                    HeadView3D(headColor: self.$headColor, headAngle: self.$headAngle)
                        .frame(width: trackedFaceSessionProperties.expectedFaceBounds.width, height: trackedFaceSessionProperties.expectedFaceBounds.height)
                        .clipShape(Ellipse())
                        .transformEffect(self.useBackCamera ? .identity : CGAffineTransform.horizontalMirror(in: trackedFaceSessionProperties.expectedFaceBounds.width))
                }
                if case .starting = self.faceTrackingResult, self.secondsRemainingToStart > 0 {
                    Text("\(self.secondsRemainingToStart)").font(.system(size: (self.faceTrackingResult.expectedFaceBounds?.height ?? 96) * 0.5, weight: .medium)).foregroundColor(.white).shadow(radius: 10)
                }
                FaceArrow(faceTrackingResult: self.faceTrackingResult, angleBearingEvaluation: self.angleBearingEvaluation)
                    .stroke(Color(.displayP3, white: 1), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .enableHighDynamicRange()
                    .transformEffect(self.useBackCamera ? .identity : CGAffineTransform.horizontalMirror(in: geometryReader.size.width))
                    .shadow(radius: 10)
                if self.showTextPrompts {
                    VStack(alignment: .center) {
                        Text(verbatim: self.prompt)
                            .padding(.top, 32)
                        Spacer()
                    }
                }
                if self.showCancelButton {
                    VStack(alignment: .center) {
                        Spacer()
                        Button {
                            self.session.cancel()
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel", bundle: .module)
                        }
                            .padding(.bottom, 48)
                    }
                }
            }
        }
        .onReceive(self.session.$result) { result in
            self.result = result
            if result != nil && self.showCancelButton {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    init(session: FaceCaptureSession, configuration: FaceCaptureViewConfiguration, result: Binding<FaceCaptureSessionResult?>) {
        self.session = session
        self._result = result
        self._textPromptProvider = configuration.textPromptProvider
        if let textPrompt = configuration.textPrompt {
            self._promptText = textPrompt
        } else {
            self._promptText = Binding(get: { "" }, set: { _ in })
        }
        self.cameraControl = CameraControl(cameraPosition: configuration.useBackCamera ? .back : .front)
        self.angleBearingEvaluation = AngleBearingEvaluation(sessionSettings: session.settings)
        self.useBackCamera = configuration.useBackCamera
        self.showCancelButton = configuration.showCancelButton
        self.showTextPrompts = configuration.showTextPrompts
        self.secondsRemainingToStart = session.settings.countdownSeconds
    }
    
    private func cameraPreviewTransformFromResult(_ result: FaceTrackingResult, viewSize: CGSize) -> CGAffineTransform {
        guard viewSize != .zero else {
            return .identity
        }
        guard let expectedFaceBounds = result.expectedFaceBounds, let faceBounds = result.smoothedFace?.bounds else {
            return .identity
        }
        switch result {
        case .starting, .started, .faceFound:
            let scale = expectedFaceBounds.width / faceBounds.width
            let faceFitsInView = faceBounds.minX > 0 && faceBounds.maxX < viewSize.width && faceBounds.minY > 0 && faceBounds.maxY < viewSize.height
            if scale < 1 && faceFitsInView {
                let cx = viewSize.width * 0.5
                let cy = viewSize.height * 0.5
                return CGAffineTransform(translationX: cx, y: cy)
                    .scaledBy(x: scale, y: scale)
                    .translatedBy(x: -cx, y: -cy)
            } else {
                return .identity
            }
        case .faceAligned, .faceFixed, .faceMisaligned, .faceCaptured:
            return CGAffineTransform.rect(faceBounds, to: expectedFaceBounds)
        default:
            return .identity
        }
    }
}

extension CMSampleBuffer: @unchecked Sendable {}

fileprivate extension View {
    
    
    func enableHighDynamicRange() -> some View {
        if #available(iOS 17, *) {
            return self.allowedDynamicRange(.high)
        }
        return self
    }
}
