//
//  FaceTrackingModule.swift
//
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import Foundation

class FaceTrackingModule {
    
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func run(inputStream: AsyncStream<FaceTrackingResult>) -> (String,Task<[UInt64:Encodable],Error>) {
        let task = Task {
            var results: [UInt64:Encodable] = [:]
            for await faceTrackingResult in inputStream {
                if Task.isCancelled {
                    break
                }
                if let frame = faceTrackingResult.serialNumber {
                    let value = try self.processFaceTrackingResult(faceTrackingResult)
                    results[frame] = value
                }
            }
            try self.checkResults(results)
            return results
        }
        return (self.name, task)
    }
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> Encodable {
        fatalError("Method not implemented")
    }
    
    func checkResults(_ results: [UInt64:Encodable]) throws {
    }
}
