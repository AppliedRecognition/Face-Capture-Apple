//
//  FaceCaptureSessionManager.swift
//
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import Foundation

@MainActor
public class FaceCaptureSessionManager: ObservableObject, FaceCaptureSessionDelegate {
    
    @Published private(set) public var session: FaceCaptureSession?
    @Published public var isSessionRunning: Bool = false
    
    public var faceTrackingPluginFactories: [(_ settings: FaceCaptureSessionSettings) throws -> any FaceTrackingPlugin] = [
        { _ in try LivenessDetectionPlugin() },
        { _ in FPSMeasurementPlugin() }
    ]
    public var faceTrackingResultTransformerFactories: [(_ settings: FaceCaptureSessionSettings) throws -> FaceTrackingResultTransformer] = []
    
    public init() {
    }
    
    public func startSession(settings: FaceCaptureSessionSettings=FaceCaptureSessionSettings(), faceDetection: FaceDetection=AppleFaceDetection()) {
        if let session = self.session {
            session.delegate = nil
            session.cancel()
        }
        self.isSessionRunning = true
        let plugins = self.faceTrackingPluginFactories.compactMap { try? $0(settings) }
        let transformers = self.faceTrackingResultTransformerFactories.compactMap { try? $0(settings) }
        self.session = FaceCaptureSession(faceDetection: faceDetection, settings: settings, delegate: self, faceTrackingPlugins: plugins, faceTrackingResultTransformers: transformers)
    }
    
    public func cancelSession() {
        self.session?.cancel()
    }
    
    // MARK: - Session delegate
    
    public func faceCaptureSession(_ faceCaptureSession: FaceCaptureSession, didFinishWithResult result: FaceCaptureSessionResult) {
        self.isSessionRunning = false
    }
    
    public func didCancelFaceCaptureSession(_ faceCaptureSession: FaceCaptureSession) {
        self.session = nil
        self.isSessionRunning = false
    }
}
