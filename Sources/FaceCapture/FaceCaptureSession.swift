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
import AsyncAlgorithms

public class FaceCaptureSession: ObservableObject {
    
//    @Published private(set) public var faceTrackingResult: FaceTrackingResult
    public var faceTrackingResult: AnyPublisher<FaceTrackingResult,Never> {
        self.faceTrackingResultSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    private var faceTrackingResultSubject: PassthroughSubject<FaceTrackingResult,Never> = PassthroughSubject()
    @Published public var result: FaceCaptureSessionResult?
    public var isStarted: Binding<Bool> {
        Binding {
            self.sessionTask != nil && !self.sessionTask!.isCancelled
        } set: { val in
            if val && (self.sessionTask == nil || self.sessionTask!.isCancelled) {
                self.start()
            } else if !val && self.sessionTask != nil && !self.sessionTask!.isCancelled {
                self.cancel()
            }
        }
    }
    private var input: AsyncStream<FaceCaptureSessionImageInput>.Continuation?
    private var sessionTask: Task<Void,Error>?
    private var moduleTasks: [Task<Void,Error>] = []
    private var faceTracking: SessionFaceTracking
    private var continuations: Array<AsyncStream<FaceTrackingResult>.Continuation> = []
    private var faceTrackingModules: Array<any FaceTrackingModule> = []
    lazy var settings: FaceCaptureSessionSettings = self.faceTracking.settings
    
    public convenience init() {
        self.init(faceDetection: AppleFaceDetection(), settings: FaceCaptureSessionSettings())
    }
    
    public convenience init(settings: FaceCaptureSessionSettings) {
        self.init(faceDetection: AppleFaceDetection(), settings: settings)
    }
    
    public init(faceDetection: FaceDetection, settings: FaceCaptureSessionSettings) {
        self.faceTracking = SessionFaceTracking(faceDetection: faceDetection, settings: settings)
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
    }
    
    public func start() {
        if let task = self.sessionTask, !task.isCancelled {
            return
        }
        let input = AsyncStream<FaceCaptureSessionImageInput>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.input = continuation
        }
//        self.faceTrackingResult = .created(self.faceTracking.requestedBearing)
        self.faceTrackingResultSubject.send(.created(self.faceTracking.requestedBearing))
        self.faceTracking.reset()
        self.result = nil
        self.moduleTasks = faceTrackingModules.map { $0.run(inputStream: self.addFaceTrackingStream()) }
        self.sessionTask = Task {
            var faceCaptures: [FaceCapture] = []
            let moduleTask = Task {
                let results = self.faceTrackingModules.async.map { ($0.name, try await $0.results) }
                var metadata: [String:[UInt64:any Codable]] = [:]
                for try await result in results {
                    metadata[result.0] = result.1
                }
                return metadata
            }
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
                    if let serialNumber = faceTrackingResult.serialNumber {
                        NSLog("Tracked face in image \(serialNumber)")
                    }
                    self.faceTrackingResultSubject.send(faceTrackingResult)
//                    await MainActor.run {
//                        if let serialNumber = faceTrackingResult.serialNumber {
//                            NSLog("Sending tracking result for image \(serialNumber)")
//                        }
//                        self.faceTrackingResult = faceTrackingResult
//                    }
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
                let metadata = try await moduleTask.value
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
                let metadata = try? await moduleTask.value
                if Task.isCancelled {
                    self.finishSession()
                    return
                }
                self.finishSession()
                result = .failure(faceCaptures: faceCaptures, metadata: metadata ?? [:], error: error)
            }
            await MainActor.run {
                self.result = result
            }
        }
    }
    
    public func cancel() {
        Task {
            await MainActor.run {
                self.result = nil
            }
            self.finishSession()
        }
    }
    
    public func addInputFrame(_ inputFrame: FaceCaptureSessionImageInput) {
        self.input?.yield(inputFrame)
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
        while !self.moduleTasks.isEmpty {
            self.moduleTasks.removeFirst().cancel()
        }
    }
}

protocol FaceTrackingModule where Result: Codable {
    associatedtype Result
    var name: String { get }
    var channel: AsyncThrowingChannel<(UInt64,Result), Error> { get }
    var results: [UInt64:Result] { get async throws }
    func run(inputStream: AsyncStream<FaceTrackingResult>) -> Task<(),Error>
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> Result
}

extension FaceTrackingModule {
    var results: [UInt64:Result] {
        get async throws {
            try await self.channel.reduce(into: [UInt64:Result]()) { current, next in
                current[next.0] = next.1
            }
        }
    }
    
    func run(inputStream: AsyncStream<FaceTrackingResult>) -> Task<(),Error> {
        Task {
            for await faceTrackingResult in inputStream {
                if Task.isCancelled {
                    break
                }
                if let frame = faceTrackingResult.serialNumber {
                    do {
                        let value = try self.processFaceTrackingResult(faceTrackingResult)
                        await self.channel.send((frame, value))
                    } catch {
                        self.channel.fail(error)
                        return
                    }
                }
            }
            self.channel.finish()
        }
    }
}

class FaceCoveringClassifierModule: FaceTrackingModule {
    typealias Result = Float
    let name: String = "Face covering"
    let channel = AsyncThrowingChannel<(UInt64,Result), Error>()
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> Result {
        0.5
    }
}
