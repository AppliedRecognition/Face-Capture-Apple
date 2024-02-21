//
//  CameraControl.swift
//
//
//  Created by Jakub Dolejs on 26/01/2024.
//

import Foundation
import Combine
import AVFoundation

actor CameraControl {
    
    let captureSession = AVCaptureSession()
    private let captureSessionQueue = DispatchQueue(label: "com.appliedrec.videocapture")
    private let captureDevice: AVCaptureDevice!
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        let pixelFormat: OSType = kCVPixelFormatType_32BGRA
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:pixelFormat]
        output.setSampleBufferDelegate(self.cameraDelegate, queue: self.captureSessionQueue)
        return output
    }()
    private let cameraDelegate: CameraControlDelegate = CameraControlDelegate()
    lazy var cameraPosition: AVCaptureDevice.Position = self.captureDevice.position
    
    init() {
        self.init(cameraPosition: .front)
    }
    
    init(cameraPosition: AVCaptureDevice.Position) {
        self.captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: cameraPosition)
    }
    
    func start() async throws -> AsyncStream<CMSampleBuffer> {
        if self.cameraDelegate.continuation != nil || self.captureSession.isRunning {
            throw FaceCaptureError.anotherCaptureSessionInProgress
        }
        try await self.requestCameraPermission()
        let videoDeviceInput = try AVCaptureDeviceInput(device: self.captureDevice)
        self.captureSession.beginConfiguration()
        if self.captureSession.canAddInput(videoDeviceInput) {
            self.captureSession.addInput(videoDeviceInput)
        }
        if self.captureSession.canAddOutput(self.videoDataOutput) {
            self.captureSession.addOutput(self.videoDataOutput)
        }
        self.captureSession.commitConfiguration()
        do {
            try self.captureDevice.lockForConfiguration()
            defer {
                self.captureDevice.unlockForConfiguration()
            }
            if self.captureDevice.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) {
                self.captureDevice.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            }
            if self.captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus) {
                self.captureDevice.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
            } else if self.captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
                self.captureDevice.focusMode = AVCaptureDevice.FocusMode.autoFocus
            }
            if self.captureDevice.isFocusPointOfInterestSupported {
                self.captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
        }
        self.captureSession.startRunning()
        let stream = AsyncStream<CMSampleBuffer>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.cameraDelegate.continuation = continuation
        }
        return stream
    }
    
    func stop() {
        self.cameraDelegate.continuation?.finish()
        self.cameraDelegate.continuation = nil
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    private func requestCameraPermission() async throws {
        try await withCheckedThrowingContinuation { cont in
            DispatchQueue.main.async {
                switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
                case .authorized:
                    cont.resume()
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                        if granted {
                            cont.resume()
                        } else {
                            cont.resume(throwing: "Camera access denied")
                        }
                    })
                default:
                    cont.resume(throwing: "Camera not authorized or available")
                }
            }
        }
    }
}

fileprivate class CameraControlDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var continuation: AsyncStream<CMSampleBuffer>.Continuation?
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.continuation?.yield(sampleBuffer)
    }
}
