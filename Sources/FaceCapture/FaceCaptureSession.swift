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
        self.faceTrackingResultSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    @Published private(set) public var result: FaceCaptureSessionResult?
    
    private var faceTrackingResultSubject: PassthroughSubject<FaceTrackingResult,Never> = PassthroughSubject()
    private var input: AsyncStream<FaceCaptureSessionImageInput>.Continuation?
    private var sessionTask: Task<Void,Error>?
    private var moduleTasks: [String:Task<[UInt64:Encodable],Error>] = [:]
    private var pluginTasks: [String:Task<any FaceTrackingPluginResult,Error>] = [:]
    private var plugins: [any FaceTrackingPlugin] = []
    private var faceTracking: SessionFaceTracking
    private var continuations: Array<AsyncStream<FaceTrackingResult>.Continuation> = []
    private var faceTrackingModules: Array<FaceTrackingModule> = []
    private let id: UUID
    weak var delegate: FaceCaptureSessionDelegate?
    public lazy var settings: FaceCaptureSessionSettings = self.faceTracking.settings
    
    public convenience init() {
        self.init(faceDetection: AppleFaceDetection(), settings: FaceCaptureSessionSettings())
    }
    
    public convenience init(settings: FaceCaptureSessionSettings) {
        self.init(faceDetection: AppleFaceDetection(), settings: settings)
    }
    
    public init(faceDetection: FaceDetection, settings: FaceCaptureSessionSettings, delegate: FaceCaptureSessionDelegate?=nil) {
        self.id = UUID()
        self.faceTracking = SessionFaceTracking(faceDetection: faceDetection, settings: settings)
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
        self.delegate = delegate
//        if let livenessDetectionPlugin = try? LivenessDetectionPlugin() {
//            self.plugins.append(livenessDetectionPlugin)
//        }
        if let livenessDetection = try? LivenessDetectionModule() {
            self.faceTrackingModules.append(livenessDetection)
        }
        let input = AsyncStream<FaceCaptureSessionImageInput>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.input = continuation
        }
//        self.faceTrackingResult = .created(self.faceTracking.requestedBearing)
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
        self.faceTracking.reset()
        self.result = nil
        self.moduleTasks = Dictionary(faceTrackingModules.map { $0.run(inputStream: self.addFaceTrackingStream()) }) { $1 }
//        let pluginTuples: (String,Task<any FaceTrackingPluginResult,Error>) = self.plugins.map { plugin in
//            let task = self.runTaskForPlugin(plugin)
//            return (plugin.name, task)
//        }
//        self.pluginTasks = Dictionary(pluginTuples) { $1 }
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
                    let faceTrackingResult = try self.faceTracking.trackFace(in: inp)
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
                    self.continuations.forEach {
                        $0.yield(faceTrackingResult)
                    }
                }
                self.finishModuleTasks()
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
                self.finishModuleTasks()
                if Task.isCancelled {
                    self.finishSession()
                    return
                }
//                let metadata = try? await moduleTask.value
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
    
    private func runTaskForPlugin<T: FaceTrackingPluginResult>(_ plugin: some FaceTrackingPlugin<T>) -> Task<[T],Error> {
        return plugin.run(inputStream: self.addFaceTrackingStream())
    }
    
    private var metadata: [String: [UInt64:Encodable]] {
        get async throws {
            var metadata: [String: [UInt64:any Encodable]] = [:]
            for (name, task) in self.moduleTasks {
                metadata[name] = try await task.value
            }
            return metadata
        }
    }
    
    private func addFaceTrackingStream() -> AsyncStream<FaceTrackingResult> {
        return AsyncStream<FaceTrackingResult>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuations.append(continuation)
        }
    }
    
    private func finishModuleTasks() {
        while !self.continuations.isEmpty {
            self.continuations.removeFirst().finish()
        }
    }
    
    private func finishSession() {
        self.finishModuleTasks()
        self.input?.finish()
        self.input = nil
        self.sessionTask?.cancel()
        self.sessionTask = nil
        self.moduleTasks.forEach { key, val in
            val.cancel()
        }
        self.moduleTasks.removeAll(keepingCapacity: false)
    }
}

public protocol FaceCaptureSessionDelegate: AnyObject {
    
    func faceCaptureSession(_ faceCaptureSession: FaceCaptureSession, didFinishWithResult result: FaceCaptureSessionResult)
    
    func didCancelFaceCaptureSession(_ faceCaptureSession: FaceCaptureSession)
}
