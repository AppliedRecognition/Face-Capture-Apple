//
//  FaceTrackingPlugin.swift
//
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import Foundation

public protocol FaceTrackingPlugin {
    associatedtype Element: Encodable
    var name: String { get }
    func run(inputStream: AsyncStream<FaceTrackingResult>) -> (String,Task<TaskResults,Error>)
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) async throws -> Element
    func processFinalResults(_ faceTrackingResults: [FaceTrackingPluginResult<Element>]) async throws
    func createSummaryFromResults(_ results: [FaceTrackingPluginResult<Element>]) async -> String
}

public extension FaceTrackingPlugin {
    func run(inputStream: AsyncStream<FaceTrackingResult>) -> (String,Task<TaskResults,Error>) {
        let task = Task {
            var results: [FaceTrackingPluginResult<Element>] = []
            for await faceTrackingResult in inputStream {
                if Task.isCancelled {
                    break
                }
                if let frame = faceTrackingResult.serialNumber, let time = faceTrackingResult.time {
                    let value = try await self.processFaceTrackingResult(faceTrackingResult)
                    let result = FaceTrackingPluginResult(serialNumber: frame, time: time, result: value)
                    results.append(result)
                }
            }
            try await self.processFinalResults(results)
            let summary = await self.createSummaryFromResults(results)
            return TaskResults(summary: summary, results: results)
        }
        return (self.name, task)
    }
    
    func processFinalResults(_ faceTrackingResults: [FaceTrackingPluginResult<Element>]) async throws {
        
    }
}

public protocol FaceTrackingPluginResultProtocol: Encodable {
    associatedtype Element: Encodable
    var serialNumber: UInt64 { get }
    var time: Double { get }
    var result: Element { get set }
}

public struct FaceTrackingPluginResult<T: Encodable>: FaceTrackingPluginResultProtocol {
    public typealias Element = T
    public let serialNumber: UInt64
    public let time: Double
    public var result: T
}

public struct TaskResults {
    public let summary: String
    public let results: [any FaceTrackingPluginResultProtocol]
}
