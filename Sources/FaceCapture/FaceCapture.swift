//
//  FaceCapture.swift
//  FaceCapture
//
//  Created by Jakub Dolejs on 30/05/2025.
//

import Foundation
import UIKit
import ObjectiveC
import VerIDCommonTypes

@available(iOS 14, *)
public class FaceCapture {
    
    private static var delegateAssociationKey: UInt8 = 0
    
    /// Capture faces
    /// - Parameter configuration: Face capture configuration
    /// - Returns: Face capture result
    /// - Since: 1.1.0
    public static func captureFaces(configuration: FaceCaptureConfiguration) async -> FaceCaptureSessionResult {
        let session = FaceCaptureSession(
            settings: configuration.settings,
            faceDetection: configuration.faceDetection,
            faceTrackingPlugins: configuration.faceTrackingPlugins,
            faceTrackingResultTransformers: configuration.faceTrackingResultTransformers
        )
        return await captureFaces(session: session, useBackCamera: configuration.useBackCamera)
    }
    
    public static func captureFaces(configure: (inout FaceCaptureConfiguration) throws -> Void) async -> FaceCaptureSessionResult {
        var configuration = FaceCaptureConfiguration()
        do {
            try configure(&configuration)
        } catch {
            return FaceCaptureSessionResult.failure(capturedFaces: [], metadata: [:], error: error)
        }
        let session = FaceCaptureSession(
            settings: configuration.settings,
            faceDetection: configuration.faceDetection,
            faceTrackingPlugins: configuration.faceTrackingPlugins,
            faceTrackingResultTransformers: configuration.faceTrackingResultTransformers
        )
        return await captureFaces(session: session, useBackCamera: configuration.useBackCamera)
    }
    
    /// Capture faces
    /// - Parameters:
    ///   - session: Face capture session
    ///   - useBackCamera: `true` to use the device's back camera
    /// - Returns: Face capture result
    /// - Since: 1.1.0
    public static func captureFaces(session: FaceCaptureSession, useBackCamera: Bool = false) async -> FaceCaptureSessionResult {
        return await withCheckedContinuation { cont in
            Task { @MainActor in
                guard let window = UIApplication.shared.keyWindowInConnectedScenes else {
                    cont.resume(returning: FaceCaptureSessionResult.failure(capturedFaces: [], metadata: [:], error: FaceCaptureError.failedToPresentViewController))
                    return
                }
                let rootVC = window.rootViewController
                guard let topVC = rootVC?.topMostViewController() ?? rootVC else {
                    cont.resume(returning: FaceCaptureSessionResult.failure(capturedFaces: [], metadata: [:], error: FaceCaptureError.failedToPresentViewController))
                    return
                }
                let delegate = FaceCaptureDelegate(continuation: cont)
                let controller = FaceCaptureViewController(session: session, useBackCamera: useBackCamera)
                controller.delegate = delegate
                objc_setAssociatedObject(controller, &delegateAssociationKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                topVC.present(controller, animated: true)
            }
        }
    }
}

/// Face capture configuration
/// - Since: 1.1.0
public struct FaceCaptureConfiguration {
    /// Face capture session settings
    public var settings: FaceCaptureSessionSettings = FaceCaptureSessionSettings()
    /// `true` to use the device's back camera
    public var useBackCamera: Bool = false
    /// Factories for session plugins like liveness detection
    public var faceDetection: FaceDetection = AppleFaceDetection()
    public var faceTrackingPlugins: [any FaceTrackingPlugin] = []
    public var faceTrackingResultTransformers: [FaceTrackingResultTransformer] = []
    
    public init(
        settings: FaceCaptureSessionSettings = FaceCaptureSessionSettings(),
        useBackCamera: Bool = false,
        faceDetection: FaceDetection = AppleFaceDetection(),
        faceTrackingPlugins: [any FaceTrackingPlugin] = {
            if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(.front) {
                return [DepthLivenessDetection()]
            } else {
                return []
            }
        }(),
        faceTrackingResultTransformers: [FaceTrackingResultTransformer] = []
    ) {
        self.settings = settings
        self.useBackCamera = useBackCamera
        self.faceDetection = faceDetection
        self.faceTrackingPlugins = faceTrackingPlugins
        self.faceTrackingResultTransformers = faceTrackingResultTransformers
    }
    
    public static func spoofDetectionUsingFrontCamera(
        faceDetection: FaceDetection,
        fallbackSpoofDetectors: [SpoofDetection] = []
    ) -> FaceCaptureConfiguration {
        var plugins: [any FaceTrackingPlugin] = []
        if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(.front) {
            plugins.append(DepthLivenessDetection())
        } else if !fallbackSpoofDetectors.isEmpty, let plugin = try? LivenessDetectionPlugin(spoofDetectors: fallbackSpoofDetectors) {
            plugins.append(plugin)
        }
        let config = FaceCaptureConfiguration(
            settings: FaceCaptureSessionSettings(),
            useBackCamera: false,
            faceDetection: faceDetection,
            faceTrackingPlugins: plugins
        )
        return config
    }
}

@available(iOS 14, *)
fileprivate class FaceCaptureDelegate: FaceCaptureViewControllerDelegate {
    
    let continuation: CheckedContinuation<FaceCaptureSessionResult,Never>
    
    init(continuation: CheckedContinuation<FaceCaptureSessionResult, Never>) {
        self.continuation = continuation
    }
    
    func faceCaptureViewController(_ faceCaptureViewController: FaceCaptureViewController, didFinishSessionWithResult result: FaceCaptureSessionResult) {
        faceCaptureViewController.dismiss(animated: true) {
            self.continuation.resume(returning: result)
        }
    }
}

fileprivate extension UIApplication {
    var keyWindowInConnectedScenes: UIWindow? {
        // Finds the active key window for the foreground scene
        return self
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

fileprivate extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController() ?? nav
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        return self
    }
}
