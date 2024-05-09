//
//  VideoRecordingPlugin.swift
//  
//
//  Created by Jakub Dolejs on 15/03/2024.
//

import Foundation
import AVFoundation

class VideoRecordingPlugin: FaceTrackingPlugin {
    typealias Element = URL
    let name: String = "Video recording"
    let videoURL: URL
    let videoWriter: AVAssetWriter
    var videoInput: AVAssetWriterInput?
    lazy var queue: DispatchQueue = DispatchQueue(label: "com.appliedrec.video-writer")
    
    init() throws {
        self.videoURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        self.videoWriter = try AVAssetWriter(outputURL: self.videoURL, fileType: .mp4)
    }
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> URL {
        guard let image = faceTrackingResult.input?.image else {
            return self.videoURL
        }
        if self.videoInput == nil {
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: image.size.width,
                AVVideoHeightKey: image.size.height
            ]
            self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            guard self.videoWriter.canAdd(self.videoInput!) else {
                return self.videoURL
            }
            self.videoWriter.add(self.videoInput!)
            self.videoWriter.startWriting()
            self.videoWriter.startSession(atSourceTime: .zero)
        }
        guard let input = self.videoInput else {
            return self.videoURL
        }
        let cgImage = try image.convertToCGImage()
        if let data = cgImage.dataProvider?.data, let mutableData = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, data), let dataPtr = CFDataGetMutableBytePtr(mutableData), let time = faceTrackingResult.time {
            var pixelBuffer: CVPixelBuffer? = nil
            guard CVPixelBufferCreateWithBytes(kCFAllocatorDefault, image.width, image.height, kCVPixelFormatType_32BGRA, dataPtr, image.bytesPerRow, nil, nil, nil, &pixelBuffer) == kCVReturnSuccess, let buffer = pixelBuffer else {
                return self.videoURL
            }
            let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input)
            adapter.append(buffer, withPresentationTime: CMTime(seconds: time, preferredTimescale: 1000))
        }
        return self.videoURL
    }
    
    func createSummaryFromResults(_ results: [FaceTrackingPluginResult<URL>]) async -> String {
        await withCheckedContinuation { cont in
            self.videoInput?.markAsFinished()
            self.videoWriter.finishWriting(completionHandler: {
                if let error = self.videoWriter.error {
                    cont.resume(returning: "Failed to save video: \(error)")
                } else {
                    cont.resume(returning: "\(results[0].result)")
                }
            })
        }
    }
}
