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
    
    public let settings: FaceCaptureSessionSettings
    public let sessionModuleFactories: FaceCaptureSessionModuleFactories
    public let configuration: FaceCaptureViewConfiguration
    @State private var session: FaceCaptureSession?
    @Binding public var isCapturing: Bool
    @Binding public var result: FaceCaptureSessionResult?
    
    public var body: some View {
        Group {
            if self.isCapturing, let session = self.session {
                SessionView(session: session, configuration: self.configuration, isCapturing: self.$isCapturing, result: self.$result)
            } else {
                EmptyView()
            }
        }
        .onReceive(Just(self.isCapturing)) { capturing in
            if capturing && self.session == nil {
                self.session = FaceCaptureSession(settings: self.settings, sessionModuleFactories: self.sessionModuleFactories)
            } else if !capturing, let session = self.session {
                session.cancel()
                self.session = nil
            }
        }
    }
    
    public init(configuration: FaceCaptureViewConfiguration, isCapturing: Binding<Bool>, result: Binding<FaceCaptureSessionResult?>, settings: FaceCaptureSessionSettings = .init(), sessionModuleFactories: FaceCaptureSessionModuleFactories = .default) {
        self.settings = settings
        self.sessionModuleFactories = sessionModuleFactories
        self.configuration = configuration
        self._isCapturing = isCapturing
        self._result = result
    }
}

@available(iOS 14, *)
public struct FaceCaptureNavigationView: View {
    
    @ObservedObject private(set) public var session: FaceCaptureSession
    let onResult: OnFaceCaptureSessionResult?
    public let useBackCamera: Bool
    @State public var isCapturing: Bool = false
    @State var textPrompt: String = ""
    @State var result: FaceCaptureSessionResult?
    
    public var body: some View {
        SessionView(session: self.session, configuration: FaceCaptureViewConfiguration(useBackCamera: useBackCamera, textPrompt: self.$textPrompt, showTextPrompts: false, showCancelButton: false), isCapturing: self.$isCapturing, result: self.$result)
            .onChange(of: self.session.result) { result in
                if let result = result {
                    self.onResult?(result)
                }
            }
            .onAppear {
                self.isCapturing = true
            }
            .onDisappear {
                if self.result == nil {
                    self.isCapturing = false
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
    let cameraControl: CameraControl
    let showCancelButton: Bool
    
    @Binding var isCapturing: Bool
    @Binding var result: FaceCaptureSessionResult?
    @Binding var textPromptProvider: TextPromptProvider
    let showTextPrompts: Bool
    @Binding var promptText: String
    
    @State private var orientation: CGImagePropertyOrientation
    @State private var videoOrientation: AVCaptureVideoOrientation?
    @State private var cameraTask: Task<(),Error>? = nil
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
    
    private var angleBearingEvaluation: AngleBearingEvaluation
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
                    .onReceive(self.session.$result) { result in
                        self.result = result
                        if result != nil && self.isCapturing {
                            self.isCapturing = false
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        self.orientation = UIDevice.current.orientation.cgImagePropertyOrientation
                        self.videoOrientation = UIDevice.current.orientation.videoOrientation
                    }
                    .onAppear {
                        self.cameraTask = Task(priority: .high) {
                            let stream = try await self.cameraControl.start()
                            await MainActor.run {
                                self.videoOrientation = UIDevice.current.orientation.videoOrientation
                            }
                            var serialNumber: UInt64 = 0
                            let startTime = CACurrentMediaTime()
                            for await sample in stream {
                                if Task.isCancelled {
                                    break
                                }
                                let viewSize = geometryReader.size
                                if var image = try? sample.convertToImage(), viewSize != .zero {
                                    do {
                                        try await image.applyOrientation(self.orientation)
                                    } catch {}
                                    let rect = AVMakeRect(aspectRatio: viewSize, insideRect: CGRect(origin: .zero, size: image.size))
                                    image.cropToRect(rect)
                                    await self.session.submitImageInput(FaceCaptureSessionImageInput(serialNumber: serialNumber, time: CACurrentMediaTime()-startTime, image: image))
                                    serialNumber += 1
                                }
                            }
                            self.cameraTask = nil
                        }
                    }
                    .onDisappear {
                        if let cameraTask = self.cameraTask {
                            cameraTask.cancel()
                            self.cameraTask = nil
                            Task {
                                await self.cameraControl.stop()
                            }
                        }
                    }
                if case .faceMisaligned(let trackedFaceSessionProperties) = faceTrackingResult, self.isShowing3DHead {
                    HeadView3D(headColor: self.$headColor, headAngle: self.$headAngle)
                        .frame(width: trackedFaceSessionProperties.expectedFaceBounds.width, height: trackedFaceSessionProperties.expectedFaceBounds.height)
                        .clipShape(Ellipse())
                        .transformEffect(self.useBackCamera ? .identity : CGAffineTransform.horizontalMirror(in: trackedFaceSessionProperties.expectedFaceBounds.width))
                }
                FaceArrow(faceTrackingResult: self.faceTrackingResult, angleBearingEvaluation: self.angleBearingEvaluation)
                    .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
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
                        } label: {
                            Text("Cancel")
                        }
                            .padding(.bottom, 48)
                    }
                }
            }
        }
        .onReceive(self.session.$result) { result in
            self.result = result
        }
        .onReceive(self.session.$isCapturing) { running in
            self.isCapturing = running
        }
    }
    
    init(session: FaceCaptureSession, configuration: FaceCaptureViewConfiguration, isCapturing: Binding<Bool>, result: Binding<FaceCaptureSessionResult?>) {
        self.session = session
        self.cameraControl = CameraControl(cameraPosition: configuration.useBackCamera ? .back : .front)
        self.angleBearingEvaluation = AngleBearingEvaluation(sessionSettings: session.settings)
        self.orientation = UIDevice.current.orientation.cgImagePropertyOrientation
        self.useBackCamera = configuration.useBackCamera
        self.showCancelButton = configuration.showCancelButton
        self._textPromptProvider = configuration.textPromptProvider
        if let textPrompt = configuration.textPrompt {
            self._promptText = textPrompt
        } else {
            self._promptText = Binding(get: { "" }, set: { _ in })
        }
        self.showTextPrompts = configuration.showTextPrompts
        self._isCapturing = isCapturing
        self._result = result
    }
    
    private func cameraPreviewTransformFromResult(_ result: FaceTrackingResult, viewSize: CGSize) -> CGAffineTransform {
        switch result {
        case .faceAligned, .faceFixed, .faceMisaligned:
            guard viewSize != .zero, let imageWidth = result.input?.image.width else {
                return .identity
            }
            guard let expectedFaceBounds = result.expectedFaceBounds, let faceBounds = result.smoothedFace?.bounds else {
                return .identity
            }
            return CGAffineTransform.rect(faceBounds, to: expectedFaceBounds)
        default:
            return .identity
        }
    }
}
