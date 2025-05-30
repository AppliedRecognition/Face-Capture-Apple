//
//  FaceCapture.swift
//  FaceCapture
//
//  Created by Jakub Dolejs on 30/05/2025.
//

import Foundation
import UIKit
import ObjectiveC

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
            sessionModuleFactories: configuration.faceCaptureSessionModuleFactories
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
                    cont.resume(returning: FaceCaptureSessionResult.failure(capturedFaces: [], metadata: [:], error: NSError()))
                    return
                }
                let rootVC = window.rootViewController
                guard let topVC = rootVC?.topMostViewController() ?? rootVC else {
                    cont.resume(returning: FaceCaptureSessionResult.failure(capturedFaces: [], metadata: [:], error: NSError()))
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
    public let settings: FaceCaptureSessionSettings
    /// `true` to use the device's back camera
    public let useBackCamera: Bool
    /// Factories for session plugins like liveness detection
    public let faceCaptureSessionModuleFactories: FaceCaptureSessionModuleFactories
    
    public init(settings: FaceCaptureSessionSettings, faceCaptureSessionModuleFactories: FaceCaptureSessionModuleFactories, useBackCamera: Bool = false) {
        self.settings = settings
        self.useBackCamera = useBackCamera
        self.faceCaptureSessionModuleFactories = faceCaptureSessionModuleFactories
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
