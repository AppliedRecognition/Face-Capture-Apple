//
//  FaceCaptureSessionManager.swift
//
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import Foundation
import VerIDSDKIdentity
import VerIDLicence

public class FaceCaptureSessionManager: ObservableObject, FaceCaptureSessionDelegate {
    
    @MainActor @Published private(set) public var session: FaceCaptureSession?
    @MainActor @Published public var isSessionRunning: Bool = false
    
    @MainActor public var faceTrackingPluginFactories: [(_ settings: FaceCaptureSessionSettings) throws -> any FaceTrackingPlugin] = [
        { _ in try LivenessDetectionPlugin() },
        { _ in FPSMeasurementPlugin() }
    ]
    @MainActor public var faceTrackingResultTransformerFactories: [(_ settings: FaceCaptureSessionSettings) throws -> FaceTrackingResultTransformer] = []
    
    public convenience init() async throws {
        let identity = try VerIDIdentity(url: nil, password: nil)
        try await self.init(identity: identity)
    }
    
    public convenience init(identityFileURL: URL) async throws {
        let identity = try VerIDIdentity(url: identityFileURL)
        try await self.init(identity: identity)
    }
    
    public init(identity: VerIDIdentity) async throws {
        let licence = try await VerIDLicence(identity: identity)
        try await licence.checkLicence()
        Task {
            await licence.reporting.sendReport(componentIdentifier: Bundle(for: type(of: self)).bundleIdentifier ?? "FaceCapture", componentVersion: Version.string, event: "load")
        }
    }
    
    @MainActor public func startSession(settings: FaceCaptureSessionSettings=FaceCaptureSessionSettings(), faceDetection: FaceDetection=AppleFaceDetection()) {
        if let session = self.session {
            session.delegate = nil
            session.cancel()
        }
        self.isSessionRunning = true
        let plugins = self.faceTrackingPluginFactories.compactMap { try? $0(settings) }
        let transformers = self.faceTrackingResultTransformerFactories.compactMap { try? $0(settings) }
        self.session = FaceCaptureSession(faceDetection: faceDetection, settings: settings, delegate: self, faceTrackingPlugins: plugins, faceTrackingResultTransformers: transformers)
    }
    
    @MainActor public func cancelSession() {
        self.session?.cancel()
    }
    
    // MARK: - Session delegate
    
    @MainActor public func faceCaptureSession(_ faceCaptureSession: FaceCaptureSession, didFinishWithResult result: FaceCaptureSessionResult) {
        self.isSessionRunning = false
    }
    
    @MainActor public func didCancelFaceCaptureSession(_ faceCaptureSession: FaceCaptureSession) {
        self.session = nil
        self.isSessionRunning = false
    }
}
