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
import LivenessDetection

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
    @Published private(set) public var result: FaceCaptureSessionResult?
    
    private var faceTrackingResultSubject: PassthroughSubject<FaceTrackingResult,Never> = PassthroughSubject()
    private var input: AsyncStream<FaceCaptureSessionImageInput>.Continuation?
    private var sessionTask: Task<Void,Error>?
    private var pluginTasks: [String:Task<TaskResults,Error>] = [:]
    private var faceTracking: SessionFaceTracking
    private var faceTrackingPluginContinuations: Array<AsyncStream<FaceTrackingResult>.Continuation> = []
    private let faceTrackingPlugins: Array<any FaceTrackingPlugin>
    private let faceTrackingResultTransformers: Array<FaceTrackingResultTransformer>
    public let id: UUID
    /// Session settings
    /// - Since: 1.0.0
    public lazy var settings: FaceCaptureSessionSettings = self.faceTracking.settings
    
    public init(
        settings: FaceCaptureSessionSettings = FaceCaptureSessionSettings(),
        sessionModuleFactories: FaceCaptureSessionModuleFactories = .default
    ) {
        self.id = UUID()
        self.faceTracking = SessionFaceTracking(faceDetection: sessionModuleFactories.createFaceDetection(), settings: settings)
        self.faceTrackingResultTransformers = sessionModuleFactories.createFaceTrackingResultTransformers()
        self.faceTrackingPlugins = sessionModuleFactories.createFaceTrackingPlugins()
        let input = AsyncStream<FaceCaptureSessionImageInput>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.input = continuation
        }
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
        self.faceTracking.reset()
        self.result = nil
        self.pluginTasks = Dictionary(faceTrackingPlugins.map { $0.run(inputStream: self.addFaceTrackingStream()) }) { $1 }
        self.sessionTask = Task {
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
                    if let capture = faceTrackingResult.capturedFace {
                        capturedFaces.append(capture)
                        if capturedFaces.count >= self.settings.faceCaptureCount {
                            break
                        }
                    }
                    self.faceTrackingPluginContinuations.forEach {
                        $0.yield(faceTrackingResult)
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
        Task {
            if await !FaceCapture.default.isLoaded {
                do {
                    try await FaceCapture.default.load()
                } catch {
                    self.finishSession()
                    self.result = .failure(capturedFaces: [], metadata: [:], error: "Face capture library not loaded")
                }
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
        while !self.faceTrackingPluginContinuations.isEmpty {
            self.faceTrackingPluginContinuations.removeFirst().finish()
        }
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

extension FaceCaptureSession: SessionFaceTrackingDelegate {
    
    func transformFaceResult(_ faceTrackingResult: FaceTrackingResult) -> FaceTrackingResult {
        if self.faceTrackingResultTransformers.isEmpty {
            if case .faceAligned(let trackedFaceSessionProperties) = faceTrackingResult {
                return .faceCaptured(trackedFaceSessionProperties)
            } else {
                return faceTrackingResult
            }
        } else {
            var result = faceTrackingResult
            for transformer in self.faceTrackingResultTransformers {
                result = transformer.transformFaceResult(result)
            }
            return result
        }
    }
}

public struct FaceCaptureSessionModuleFactories {
    
    public let createFaceDetection: () -> FaceDetection
    public let createFaceTrackingPlugins: () -> [any FaceTrackingPlugin]
    public let createFaceTrackingResultTransformers: () -> [FaceTrackingResultTransformer]
    
    public static let `default`: FaceCaptureSessionModuleFactories = {
        return .init(createFaceDetection: {
            AppleFaceDetection()
        }, createFaceTrackingPlugins: {
            return [FPSMeasurementPlugin()]
        }, createFaceTrackingResultTransformers: { [] })
    }()
    
    public static func livenessDetection(detectors: [SpoofDetector]) -> FaceCaptureSessionModuleFactories {
        return .init(createFaceDetection: {
            AppleFaceDetection()
        }, createFaceTrackingPlugins: {
            var plugins: [any FaceTrackingPlugin] = []
            if let livenessDetection = try? LivenessDetectionPlugin(spoofDetectors: detectors) {
                plugins.append(livenessDetection)
            }
            plugins.append(FPSMeasurementPlugin())
            return plugins
        }, createFaceTrackingResultTransformers: { [] })
    }
}
