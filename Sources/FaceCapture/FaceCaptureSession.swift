//
//  FaceCaptureSession.swift
//
//
//  Created by Jakub Dolejs on 29/01/2024.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation
import VerIDCommonTypes

/// Face capture session
/// - Since: 1.0.0
public class FaceCaptureSession: ObservableObject, Hashable, Identifiable {
    
    /// Face tracking result publisher
    /// - Since: 1.0.0
    public var faceTrackingResult: AnyPublisher<FaceTrackingResult,Never> {
        self.faceTrackingResultSubject.share().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    /// Face capture session result
    /// - Since: 1.0.0
    @Published internal(set) public var result: FaceCaptureSessionResult?
    
    private var faceTrackingResultSubject: PassthroughSubject<FaceTrackingResult,Never> = PassthroughSubject()
    private var input: AsyncStream<FaceCaptureSessionImageInput>.Continuation?
    private var sessionInput: AsyncStream<FaceCaptureSessionImageInput>?
    private var sessionTask: Task<Void,Error>?
    private var started = false
    private let startLock = NSLock()
    private var pluginTasks: [String:Task<TaskResults,Error>] = [:]
    private var faceTracking: SessionFaceTracking
    private var faceTrackingPluginContinuations: Array<AsyncStream<FaceTrackingResult>.Continuation> = []
    private let faceTrackingPlugins: Array<any FaceTrackingPlugin>
    private let faceTrackingResultTransformers: Array<FaceTrackingResultTransformer>
    public let id: UUID
    /// Session settings
    /// - Since: 1.0.0
    public lazy var settings: FaceCaptureSessionSettings = self.faceTracking.settings
    
    public static func supportsDepthCaptureOnDeviceAt(_ position: AVCaptureDevice.Position) -> Bool {
        if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera], mediaType: .video, position: position).devices.first, device.formats.contains(where: { $0.supportedDepthDataFormats.contains(where: { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat32 })}) {
            return true
        } else {
            return false
        }
    }
    
    public init(
        settings: FaceCaptureSessionSettings = FaceCaptureSessionSettings(),
        faceDetection: FaceDetection = AppleFaceDetection(),
        faceTrackingPlugins: [any FaceTrackingPlugin] = [],
        faceTrackingResultTransformers: [FaceTrackingResultTransformer] = []
    ) {
        self.id = UUID()
        self.faceTracking = SessionFaceTracking(faceDetection: faceDetection, settings: settings)
        self.faceTrackingPlugins = faceTrackingPlugins
        self.faceTrackingResultTransformers = faceTrackingResultTransformers
        let input = AsyncStream<FaceCaptureSessionImageInput>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.input = continuation
        }
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
        self.faceTracking.reset()
        self.faceTracking.delegate = DefaultFaceTrackingResultTransformDelegate(faceTrackingResultTransformers)
        self.result = nil
        self.pluginTasks = Dictionary(faceTrackingPlugins.map { $0.run(inputStream: self.addFaceTrackingStream()) }) { $1 }
        self.sessionInput = input
    }

    /// Start the session
    /// - Since: 3.0.0
    public func start() {
        startLock.lock()
        guard !started else { startLock.unlock(); return }
        started = true
        startLock.unlock()
        guard let input = self.sessionInput else { return }
        self.sessionTask = Task(priority: .utility) {
            var capturedFaces: [CapturedFace] = []
            let result: FaceCaptureSessionResult
            do {
                for await inp in input {
                    guard !Task.isCancelled else {
                        self.finishSession()
                        return
                    }
                    if inp.time > self.settings.maxDuration {
                        throw FaceCaptureError.sessionTimedOut
                    }
                    let faceTrackingResult = try await self.faceTracking.trackFace(in: inp)
                    self.faceTrackingResultSubject.send(faceTrackingResult)
                    self.faceTrackingPluginContinuations.forEach {
                        $0.yield(faceTrackingResult)
                    }
                    if let capture = faceTrackingResult.capturedFace {
                        capturedFaces.append(capture)
                        if capturedFaces.count >= self.settings.faceCaptureCount {
                            break
                        }
                    }
                }
                self.finishPluginTasks()
                if Task.isCancelled || capturedFaces.count < self.settings.faceCaptureCount {
                    self.finishSession()
                    return
                }
                let metadata = try await self.metadata
                if Task.isCancelled {
                    self.finishSession()
                    return
                }
                self.finishSession()
                result = .success(capturedFaces: capturedFaces, metadata: metadata)
            } catch {
                self.finishPluginTasks()
                if Task.isCancelled {
                    self.finishSession()
                    return
                }
                let metadata = try? await self.metadata
                self.finishSession()
                result = .failure(capturedFaces: capturedFaces, metadata: metadata ?? [:], error: error)
            }
            await MainActor.run {
                self.result = result
            }
        }
    }
    
    /// Cancel the session
    /// - Since: 1.0.0
    public func cancel() {
        Task {
            await MainActor.run {
                if self.result == nil {
                    self.result = .cancelled
                }
            }
            self.finishSession()
        }
    }
    
    /// Submit image input to the session
    ///
    /// Once a session is created it expects to have input images sumitted to it. This is handled by session views like ``FaceCaptureSessionView``.
    ///
    /// - Parameter imageInput: Image input
    /// - Since: 1.0.0
    public func submitImageInput(_ imageInput: FaceCaptureSessionImageInput) {
        self.input?.yield(imageInput)
    }
    
    /// Equatable implementation
    public static func == (lhs: FaceCaptureSession, rhs: FaceCaptureSession) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    private var metadata: [String: TaskResults] {
        get async throws {
            var metadata: [String: TaskResults] = [:]
            for (name, task) in self.pluginTasks {
                metadata[name] = try await task.value
            }
            return metadata
        }
    }
    
    private func addFaceTrackingStream() -> AsyncStream<FaceTrackingResult> {
        return AsyncStream<FaceTrackingResult>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.faceTrackingPluginContinuations.append(continuation)
        }
    }
    
    private func finishPluginTasks() {
        self.faceTrackingPluginContinuations.forEach { $0.finish() }
        self.faceTrackingPluginContinuations.removeAll()
    }
    
    private func finishSession() {
        self.finishPluginTasks()
        self.input?.finish()
        self.input = nil
        self.sessionTask?.cancel()
        self.sessionTask = nil
        self.pluginTasks.forEach { key, val in
            val.cancel()
        }
        self.pluginTasks.removeAll(keepingCapacity: false)
    }
}

public protocol FaceCaptureSessionDelegate: AnyObject {

    func faceCaptureSession(_ faceCaptureSession: FaceCaptureSession, didFinishWithResult result: FaceCaptureSessionResult)

    func didCancelFaceCaptureSession(_ faceCaptureSession: FaceCaptureSession)
}
