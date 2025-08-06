//
//  CaptureSessionConfiguration.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 06/08/2025.
//

import Foundation
import SwiftUI
import FaceCapture
import AVFoundation
import VerIDCommonTypes
import FaceDetectionRetinaFace

struct CaptureSessionConfiguration {
    
    static func configureFaceCaptureSession(_ session: Binding<FaceCaptureSession?>, result: Binding<FaceCaptureSessionResult?>) {
        var config = FaceCaptureConfiguration()
        do {
            try configureFaceCapture(configuration: &config)
            session.wrappedValue = FaceCaptureSession(
                settings: config.settings,
                faceDetection: config.faceDetection,
                faceTrackingPlugins: config.faceTrackingPlugins,
                faceTrackingResultTransformers: config.faceTrackingResultTransformers
            )
        } catch {
            result.wrappedValue = FaceCaptureSessionResult.failure(capturedFaces: [], metadata: [:], error: error)
        }
    }
    
    static func createFaceCaptureSession() throws -> FaceCaptureSession {
        var config = FaceCaptureConfiguration()
        try configureFaceCapture(configuration: &config)
        return FaceCaptureSession(
            settings: config.settings,
            faceDetection: config.faceDetection,
            faceTrackingPlugins: config.faceTrackingPlugins,
            faceTrackingResultTransformers: config.faceTrackingResultTransformers
        )
    }
    
    static func configureFaceCapture(configuration: inout FaceCaptureConfiguration) throws {
        let settings = Settings()
        let cameraPosition: AVCaptureDevice.Position = settings.useBackCamera ? .back : .front
        switch settings.faceDetection {
        case .retinaFace:
            configuration.faceDetection = try FaceDetectionRetinaFace()
        case .apple:
            configuration.faceDetection = AppleFaceDetection()
        }
        if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
            configuration.faceTrackingPlugins = [DepthLivenessDetection()]
        }
    }
}
