//
//  CameraPreviewView.swift
//
//
//  Created by Jakub Dolejs on 20/02/2024.
//

import SwiftUI
import UIKit
import AVFoundation

class CameraPreviewUIView: UIView {
    
    init(cameraControl: CameraControl) {
        super.init(frame: .zero)
        self.videoPreviewLayer.session = cameraControl.captureSession
        self.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.videoPreviewLayer.addObserver(self, forKeyPath: "connection", options: [.initial,.new], context: nil)
    }
    
    deinit {
        self.videoPreviewLayer.removeObserver(self, forKeyPath: "connection")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            if keyPath == "connection", let connection = self.videoPreviewLayer.connection, connection.isVideoOrientationSupported, let orientation = self.videoOrientation {
                connection.videoOrientation = orientation
            }
        }
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return self.layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return self.videoPreviewLayer.session
        }
        set {
            self.videoPreviewLayer.session = newValue
        }
    }
    
    var videoOrientation: AVCaptureVideoOrientation? {
        didSet {
            if let orientation = self.videoOrientation, let conn = self.videoPreviewLayer.connection, conn.isVideoOrientationSupported {
                conn.videoOrientation = orientation
            }
        }
    }
    
    // MARK: UIView
    
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

struct CameraPreviewView: UIViewRepresentable {
    
    let cameraControl: CameraControl
    @Binding var videoOrientation: AVCaptureVideoOrientation?
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView(cameraControl: self.cameraControl)
        self.updateVideoOrientation(view)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        self.updateVideoOrientation(uiView)
    }
    
    private func updateVideoOrientation(_ uiView: CameraPreviewUIView) {
        if let orientation = self.videoOrientation {
            uiView.videoOrientation = orientation
        }
    }
}

fileprivate extension AVCaptureVideoOrientation {
    
    var name: String {
        switch self {
        case .portrait:
            return "Portrait"
        case .landscapeLeft:
            return "Landscape left"
        case .landscapeRight:
            return "Landscape right"
        case .portraitUpsideDown:
            return "Portrait upside down"
        @unknown default:
            return "Unknown"
        }
    }
}
