//
//  FaceCaptureSessionViewController.swift
//  
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import UIKit
import SwiftUI

public class FaceCaptureSessionViewController: UIHostingController<FaceCaptureSessionView> {
    
    public weak var delegate: FaceCaptureSessionDelegate?
    
    public static func create(settings: FaceCaptureSessionSettings? = nil, useBackCamera: Bool = false, faceDetection: FaceDetection? = nil, onCreate: @escaping (Result<FaceCaptureSessionViewController,Error>) -> Void) {
        Task {
            do {
                let sessionManager = try await FaceCaptureSessionManager()
                let sessionSettings = settings ?? FaceCaptureSessionSettings()
                let faceDet = faceDetection ?? AppleFaceDetection()
                sessionManager.startSession(settings: sessionSettings, faceDetection: faceDet)
                guard let session = sessionManager.session else {
                    throw "Failed to start session"
                }
                await MainActor.run {
                    let sessionView = FaceCaptureSessionView(session: session, useBackCamera: useBackCamera)
                    let viewController = FaceCaptureSessionViewController(rootView: sessionView)
                    onCreate(.success(viewController))
                }
            } catch {
                await MainActor.run {
                    onCreate(.failure(error))
                }
            }
        }
    }
    
    public convenience init(session: FaceCaptureSession, useBackCamera: Bool = false) {
        let sessionView = FaceCaptureSessionView(session: session, useBackCamera: useBackCamera)
        self.init(rootView: sessionView)
    }
    
    public override init(rootView: FaceCaptureSessionView) {
        super.init(rootView: rootView)
        rootView.session.delegate = self
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.rootView.session.result == nil {
            self.rootView.session.cancel()
        }
    }
}

extension FaceCaptureSessionViewController: FaceCaptureSessionDelegate {
    
    public func faceCaptureSession(_ faceCaptureSession: FaceCaptureSession, didFinishWithResult result: FaceCaptureSessionResult) {
        self.delegate?.faceCaptureSession(faceCaptureSession, didFinishWithResult: result)
    }
    
    public func didCancelFaceCaptureSession(_ faceCaptureSession: FaceCaptureSession) {
        self.delegate?.didCancelFaceCaptureSession(faceCaptureSession)
    }
}
