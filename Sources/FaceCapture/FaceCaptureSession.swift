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

public class FaceCaptureSession: ObservableObject, Hashable {
    
    public var faceTrackingResult: AnyPublisher<FaceTrackingResult,Never> {
        self.faceTrackingResultSubject.share().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    @Published private(set) public var result: FaceCaptureSessionResult?
    
    private var faceTrackingResultSubject: PassthroughSubject<FaceTrackingResult,Never> = PassthroughSubject()
    private var input: AsyncStream<FaceCaptureSessionImageInput>.Continuation?
    private var sessionTask: Task<Void,Error>?
    private var pluginTasks: [String:Task<TaskResults,Error>] = [:]
    private var faceTracking: SessionFaceTracking
    private var faceTrackingPluginContinuations: Array<AsyncStream<FaceTrackingResult>.Continuation> = []
    private let faceTrackingPlugins: Array<any FaceTrackingPlugin>
    private let faceTrackingResultTransformers: Array<FaceTrackingResultTransformer>
    private let id: UUID
    weak var delegate: FaceCaptureSessionDelegate?
    public lazy var settings: FaceCaptureSessionSettings = self.faceTracking.settings
    
    init(
        faceDetection: FaceDetection=AppleFaceDetection(),
        settings: FaceCaptureSessionSettings=FaceCaptureSessionSettings(),
        delegate: FaceCaptureSessionDelegate?=nil,
        faceTrackingPlugins: [any FaceTrackingPlugin]=[],
        faceTrackingResultTransformers: [FaceTrackingResultTransformer]=[]
    ) {
        self.id = UUID()
        self.faceTracking = SessionFaceTracking(faceDetection: faceDetection, settings: settings)
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
        self.delegate = delegate
        self.faceTrackingPlugins = faceTrackingPlugins
        self.faceTrackingResultTransformers = faceTrackingResultTransformers
        let input = AsyncStream<FaceCaptureSessionImageInput>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.input = continuation
        }
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
        self.faceTracking.reset()
        self.result = nil
        self.pluginTasks = Dictionary(faceTrackingPlugins.map { $0.run(inputStream: self.addFaceTrackingStream()) }) { $1 }
        self.sessionTask = Task {
            var faceCaptures: [FaceCapture] = []
            let result: FaceCaptureSessionResult
            do {
                for await inp in input {
                    guard !Task.isCancelled else {
                        self.finishSession()
                        return
                    }
                    if inp.time > self.settings.maxDuration {
                        throw "Session expired"
                    }
                    let faceTrackingResult = try await self.faceTracking.trackFace(in: inp)
//                    if let serialNumber = faceTrackingResult.serialNumber {
//                        NSLog("Tracked face in image \(serialNumber)")
//                    }
                    self.faceTrackingResultSubject.send(faceTrackingResult)
//                    NSLog("Tracked face in frame %ld at %.02f: \(faceTrackingResult)", inp.serialNumber, inp.time)
                    if let capture = faceTrackingResult.faceCapture {
                        faceCaptures.append(capture)
                        if faceCaptures.count >= self.settings.faceCaptureCount {
                            break
                        }
                    }
                    self.faceTrackingPluginContinuations.forEach {
                        $0.yield(faceTrackingResult)
                    }
                }
                self.finishPluginTasks()
                if Task.isCancelled || faceCaptures.count < self.settings.faceCaptureCount {
                    self.finishSession()
                    return
                }
                let metadata = try await self.metadata
                if Task.isCancelled {
                    self.finishSession()
                    return
                }
                self.finishSession()
                result = .success(faceCaptures: faceCaptures, metadata: metadata)
            } catch {
                self.finishPluginTasks()
                if Task.isCancelled {
                    self.finishSession()
                    return
                }
                if Task.isCancelled {
                    self.finishSession()
                    return
                }
                let metadata = try? await self.metadata
                self.finishSession()
                result = .failure(faceCaptures: faceCaptures, metadata: metadata ?? [:], error: error)
            }
            await MainActor.run {
                self.result = result
                self.delegate?.faceCaptureSession(self, didFinishWithResult: result)
            }
        }
    }
    
    public func cancel() {
        Task {
            await MainActor.run {
                self.result = nil
                self.delegate?.didCancelFaceCaptureSession(self)
            }
            self.finishSession()
        }
    }
    
    public func submitImageInput(_ imageInput: FaceCaptureSessionImageInput) {
        self.input?.yield(imageInput)
    }
    
    public static func == (lhs: FaceCaptureSession, rhs: FaceCaptureSession) -> Bool {
        lhs.id == rhs.id
    }
    
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
    
    public func transformFaceResult(_ faceTrackingResult: FaceTrackingResult) -> FaceTrackingResult {
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
