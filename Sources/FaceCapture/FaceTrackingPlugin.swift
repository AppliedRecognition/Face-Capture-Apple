//
//  FaceTrackingPlugin.swift
//
//
//  Created by Jakub Dolejs on 08/02/2024.
//

import Foundation

public protocol FaceTrackingPlugin<PluginResult> {
    
    associatedtype ResultType
    associatedtype PluginResult: FaceTrackingPluginResult where ResultType == Self.ResultType
    
    var name: String { get }
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> PluginResult?
    
    func checkResults(_ results: [PluginResult]) throws
}

public extension FaceTrackingPlugin {
    
    func run(inputStream: AsyncStream<FaceTrackingResult>) -> Task<[PluginResult],Error> {
        let task = Task {
            var results: [PluginResult] = []
            for await faceTrackingResult in inputStream {
                if Task.isCancelled {
                    break
                }
                if faceTrackingResult.serialNumber != nil, faceTrackingResult.time != nil, let value = try self.processFaceTrackingResult(faceTrackingResult) {
                    results.append(value)
                }
            }
            try self.checkResults(results)
            return results
        }
        return task
    }
}

public protocol FaceTrackingPluginResult: Encodable {
    associatedtype Result
    var serialNumber: UInt64 { get }
    var time: Double { get }
    var result: Result { get }
}
