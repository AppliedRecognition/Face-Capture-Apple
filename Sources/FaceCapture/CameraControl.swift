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
    private(set) var supportsDepthCapture: Bool
    private let captureSessionQueue = DispatchQueue(label: "com.appliedrec.videocapture", attributes: [], autoreleaseFrequency: .workItem)
    private let dataOutputQueue = DispatchQueue(label: "com.appliedrec.videodata", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private let captureDevice: AVCaptureDevice!
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        let pixelFormat: OSType = kCVPixelFormatType_32BGRA
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:pixelFormat]
        return output
    }()
    private let deptDataOutput = AVCaptureDepthDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    private let cameraDelegate: CameraControlDelegate = CameraControlDelegate()
    lazy var cameraPosition: AVCaptureDevice.Position = self.captureDevice.position
    
    init() {
        self.init(cameraPosition: .front)
    }
    
    init(cameraPosition: AVCaptureDevice.Position) {
        if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera], mediaType: .video, position: cameraPosition).devices.first {
            self.captureDevice = device
            self.supportsDepthCapture = true
        } else {
            self.captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: cameraPosition)
            self.supportsDepthCapture = false
        }
    }
    
    func start() async throws -> AsyncStream<Capture> {
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
            if !self.supportsDepthCapture {
                self.videoDataOutput.setSampleBufferDelegate(self.cameraDelegate, queue: self.dataOutputQueue)
            }
            self.captureSession.addOutput(self.videoDataOutput)
            self.cameraDelegate.videoDataOutput = self.videoDataOutput
        }
        if self.supportsDepthCapture && self.captureSession.canAddOutput(self.deptDataOutput) {
            self.captureSession.addOutput(self.deptDataOutput)
            if let connection = self.deptDataOutput.connection(with: .depthData) {
                connection.isEnabled = true
                
                self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput, self.deptDataOutput])
                self.cameraDelegate.depthDataOutput = self.deptDataOutput
                self.outputSynchronizer!.setDelegate(self.cameraDelegate, queue: self.dataOutputQueue)
            } else {
                self.captureSession.removeOutput(self.deptDataOutput)
            }
        }
        self.captureSession.commitConfiguration()
        do {
            try self.captureDevice.lockForConfiguration()
            defer {
                self.captureDevice.unlockForConfiguration()
            }
            self.captureDevice.activeDepthDataFormat = self.depthFormat(device: self.captureDevice)
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
        let stream = AsyncStream<Capture>(bufferingPolicy: .bufferingNewest(1)) { continuation in
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
    
    private func depthFormat(device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        let depthFormats = device.activeFormat.supportedDepthDataFormats
        let filtered = depthFormats.filter({
            CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat32 // kCVPixelFormatType_DepthFloat16
        })
        return filtered.max(by: {
            first, second in CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
        })
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

fileprivate class CameraControlDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDataOutputSynchronizerDelegate {
    
    var continuation: AsyncStream<Capture>.Continuation?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var depthDataOutput: AVCaptureDepthDataOutput?
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        self.continuation?.yield(Capture(video: videoPixelBuffer, depth: nil))
    }
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        guard let videoDataOutput = self.videoDataOutput, let depthDataOutput = self.depthDataOutput else {
            return
        }
        guard let syncedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData, let syncedVideoData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else {
            return
        }
        if syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped {
            return
        }
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(syncedVideoData.sampleBuffer) else {
            return
        }
        self.continuation?.yield(Capture(video: videoPixelBuffer, depth: syncedDepthData.depthData))
    }
}

internal struct Capture {
    let video: CVPixelBuffer
    let depth: AVDepthData?
}
