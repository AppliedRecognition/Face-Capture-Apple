//
//  CaptureSessionConfiguration.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 06/08/2025.
//

import Foundation
import FaceCapture
import AVFoundation
import FaceDetectionRetinaFace

struct CaptureSessionConfiguration {

    static func createFaceCaptureSession(settings: Settings) throws -> FaceCaptureSession {
        var config = FaceCaptureConfiguration()
        try configureFaceCapture(configuration: &config, settings: settings)
        return FaceCaptureSession(
            settings: config.settings,
            faceDetection: config.faceDetection,
            faceTrackingPlugins: config.faceTrackingPlugins,
            faceTrackingResultTransformers: config.faceTrackingResultTransformers
        )
    }

    static func configureFaceCapture(configuration: inout FaceCaptureConfiguration, settings: Settings) throws {
        let cameraPosition: AVCaptureDevice.Position = settings.useBackCamera ? .back : .front
        switch settings.faceDetection {
        case .retinaFace:
            configuration.faceDetection = try FaceDetectionRetinaFace()
        case .apple:
            configuration.faceDetection = AppleFaceDetection()
        }
        configuration.settings.faceCaptureCount = settings.enableActiveLiveness ? 2 : 1
        if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
            configuration.faceTrackingPlugins = [DepthLivenessDetection()]
        }
    }
}
