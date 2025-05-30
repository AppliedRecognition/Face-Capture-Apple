//
//  FaceCaptureViewController.swift
//
//
//  Created by Jakub Dolejs on 21/02/2024.
//

import UIKit
import SwiftUI
import Combine

@available(iOS 14, *)
public class FaceCaptureViewController: UIHostingController<FaceCaptureView> {
    
    public weak var delegate: FaceCaptureViewControllerDelegate?
    
    private var sessionCancellables: Set<AnyCancellable> = []
    
    public init(session: FaceCaptureSession, useBackCamera: Bool = false) {
//        let view = FaceCaptureNavigationView(session: session, useBackCamera: useBackCamera) { _ in }
        let view = FaceCaptureView(session: session, configuration: FaceCaptureViewConfiguration(useBackCamera: useBackCamera))
        super.init(rootView: view)
        session.$result.sink { result in
            if let result = result {
                self.delegate?.faceCaptureViewController(self, didFinishSessionWithResult: result)
            }
        }.store(in: &self.sessionCancellables)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.rootView.session.cancel()
    }
}

@available(iOS 14, *)
public protocol FaceCaptureViewControllerDelegate: AnyObject {
    
    func faceCaptureViewController(_ faceCaptureViewController: FaceCaptureViewController, didFinishSessionWithResult result: FaceCaptureSessionResult)
    
}
