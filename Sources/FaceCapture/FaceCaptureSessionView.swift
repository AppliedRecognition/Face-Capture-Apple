//
//  FaceCaptureSessionView.swift
//
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import Combine
import AVFoundation

public struct FaceCaptureSessionView: View {
    
    @ObservedObject public var session: FaceCaptureSession
    @State private var promptText: String = "Preparing face detection" {
        didSet {
            self.onTextPromptChange?(self.promptText)
        }
    }
    @State private var orientation: CGImagePropertyOrientation
    @State private var videoOrientation: AVCaptureVideoOrientation?
    let cameraControl: CameraControl
    private let usingFrontCamera: Bool
    @State private var cameraTask: Task<(),Error>?
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
    @State private var last3DHeadAppearanceTime: Double?
    private var angleBearingEvaluation: AngleBearingEvaluation
    private var textPromptProvider: (FaceTrackingResult) -> String = { faceTrackingResult in
        switch faceTrackingResult {
        case .created:
            return "Preparing face detection"
        case .faceFixed, .faceAligned, .paused:
            return "Great, hold it"
        case .faceMisaligned:
            return "Follow the arrow"
        default:
            return "Align your face with the oval"
        }
    }
    private var headAppearanceInterval: TimeInterval = 3.0
    private var headAppearanceDuration: TimeInterval = 1.8
    private let onTextPromptChange: ((String) -> Void)?
    private let onResult: ((FaceCaptureSessionResult) -> Void)?
    public let showTextPrompts: Bool
    
    public init(session: FaceCaptureSession, useBackCamera: Bool=false, showTextPrompts: Bool=true, textPromptProvider: ((FaceTrackingResult) -> String)?=nil, onTextPromptChange: ((String) -> Void)?=nil, onResult: ((FaceCaptureSessionResult) -> Void)?=nil) {
        self.session = session
        self.usingFrontCamera = !useBackCamera
        self.showTextPrompts = showTextPrompts
        if let promptProvider = textPromptProvider {
            self.textPromptProvider = promptProvider
        }
        self.onTextPromptChange = onTextPromptChange
        self.onResult = onResult
        self.cameraControl = CameraControl(useFrontCamera: !useBackCamera)
        self.angleBearingEvaluation = AngleBearingEvaluation(sessionSettings: session.settings)
        self.orientation = UIDevice.current.orientation.cgImagePropertyOrientation
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
    
    public var body: some View {
        GeometryReader { geometryReader in
            ZStack {
                CameraPreviewView(cameraControl: self.cameraControl, videoOrientation: self.$videoOrientation)
                    .transformEffect(self.cameraPreviewTransformFromResult(self.faceTrackingResult, viewSize: geometryReader.size))
                    .clipShape(FaceOval(faceTrackingResult: self.faceTrackingResult))
                    .onReceive(self.session.faceTrackingResult) { faceTrackingResult in
                        self.faceTrackingResult = faceTrackingResult.scaledToFitViewSize(geometryReader.size, mirrored: self.usingFrontCamera)
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
                        self.promptText = self.textPromptProvider(faceTrackingResult)
                    }
                    .onReceive(self.session.$result) { result in
                        if let result = result, let onResult = self.onResult {
                            onResult(result)
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
                        .transformEffect(self.usingFrontCamera ? CGAffineTransform.horizontalMirror(in: trackedFaceSessionProperties.expectedFaceBounds.width) : .identity)
                }
                FaceArrow(faceTrackingResult: self.faceTrackingResult, angleBearingEvaluation: self.angleBearingEvaluation)
                    .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .transformEffect(self.usingFrontCamera ? CGAffineTransform.horizontalMirror(in: geometryReader.size.width) : .identity)
                    .shadow(radius: 10)
//                DetectedFaceOval(faceTrackingResult: self.faceTrackingResult)
//                    .stroke(Color.primary, style: StrokeStyle(lineWidth: self.lineWidth))
                if self.showTextPrompts {
                    VStack(alignment: .center) {
                        Text(self.promptText)
                            .padding(.top, 32)
                        Spacer()
                    }
                }
            }
        }
    }
}

class CameraPreviewUIView: UIView {
    
    init(cameraControl: CameraControl) {
        super.init(frame: .zero)
        self.videoPreviewLayer.session = cameraControl.captureSession
        self.videoPreviewLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return self.layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return self.videoPreviewLayer.session
        }
        set {
            self.videoPreviewLayer.session = newValue
        }
    }
    
    var videoOrientation: AVCaptureVideoOrientation? {
        get {
            if let conn = self.videoPreviewLayer.connection, conn.isVideoOrientationSupported {
                return conn.videoOrientation
            } else {
                return nil
            }
        }
        set {
            if let orientation = newValue, let conn = self.videoPreviewLayer.connection, conn.isVideoMirroringSupported {
                conn.videoOrientation = orientation
            }
        }
    }
    
    // MARK: UIView
    
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

struct CameraPreviewView: UIViewRepresentable {
    
    let cameraControl: CameraControl
    @Binding var videoOrientation: AVCaptureVideoOrientation?
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView(cameraControl: self.cameraControl)
        if let orientation = self.videoOrientation {
            view.videoOrientation = orientation
        }
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if let orientation = self.videoOrientation {
            uiView.videoOrientation = orientation
        }
    }
}

struct FaceOval: Shape {
    
    let faceTrackingResult: FaceTrackingResult
    
    func path(in rect: CGRect) -> Path {
        if let faceBounds = faceTrackingResult.expectedFaceBounds {
            return Path(ellipseIn: faceBounds)
        } else {
            return Path()
        }
    }
}

struct DetectedFaceOval: Shape {
    
    let faceTrackingResult: FaceTrackingResult
    
    func path(in rect: CGRect) -> Path {
        if case .faceFound(let properties) = faceTrackingResult {
            return Path(ellipseIn: properties.smoothedFace.bounds)
        } else if let expectedFaceBounds = faceTrackingResult.expectedFaceBounds {
            return Path(ellipseIn: expectedFaceBounds)
        } else {
            return Path()
        }
    }
}

struct FaceArrow: Shape {
    
    let faceTrackingResult: FaceTrackingResult
    let angleBearingEvaluation: AngleBearingEvaluation
    
    func path(in rect: CGRect) -> Path {
        if case .faceMisaligned(let properties) = self.faceTrackingResult {
            let offsetAngle = self.angleBearingEvaluation.offsetFromAngle(properties.smoothedFace.angle, toBearing: properties.requestedBearing)
            let angle: CGFloat = atan2(CGFloat(0.0-offsetAngle.pitch), CGFloat(offsetAngle.yaw))
            let distance: CGFloat = CGFloat(hypot(offsetAngle.yaw, 0-offsetAngle.pitch) * 2)
//            let scale = rect.width / CGFloat(properties.input.image.width)
//            let faceBounds = properties.expectedFaceBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            let faceBounds = properties.expectedFaceBounds
            
            let arrowLength = faceBounds.width / 5
            let stemLength = min(max(arrowLength * distance, arrowLength * 0.75), arrowLength * 1.7)
            let arrowAngle = CGFloat(Measurement(value: 40, unit: UnitAngle.degrees).converted(to: .radians).value)
            let arrowTip = CGPoint(x: faceBounds.midX + cos(angle) * arrowLength / 2, y: faceBounds.midY + sin(angle) * arrowLength / 2)
            let arrowPoint1 = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi - arrowAngle) * arrowLength * 0.6, y: arrowTip.y + sin(angle + CGFloat.pi - arrowAngle) * arrowLength * 0.6)
            let arrowPoint2 = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi + arrowAngle) * arrowLength * 0.6, y: arrowTip.y + sin(angle + CGFloat.pi + arrowAngle) * arrowLength * 0.6)
            let arrowStart = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi) * stemLength, y: arrowTip.y + sin(angle + CGFloat.pi) * stemLength)
            
            return Path { path in
                path.move(to: arrowPoint1)
                path.addLine(to: arrowTip)
                path.addLine(to: arrowPoint2)
                path.move(to: arrowTip)
                path.addLine(to: arrowStart)
            }
        } else {
            return Path()
        }
    }
}

extension CGRect {
    
    var aspectRatio: CGFloat {
        self.width / self.height
    }
}


struct TaskModifier: ViewModifier {
    
    let action: @Sendable () async -> Void
    @State var task: Task<Void, Never>? = nil
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                self.task?.cancel()
                self.task = Task {
                    Task(operation: self.action)
                }
            }
            .onDisappear {
                self.task?.cancel()
            }
    }
}

extension View {
    @available(iOS, deprecated: 15.0)
    func task(_ action: @escaping @Sendable () async -> Void) -> some View {
        self.modifier(TaskModifier(action: action))
    }
}
