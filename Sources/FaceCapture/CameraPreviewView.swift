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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        get {
            if let conn = self.videoPreviewLayer.connection, conn.isVideoOrientationSupported {
                return conn.videoOrientation
            } else {
                return nil
            }
        }
        set {
            if let orientation = newValue, let conn = self.videoPreviewLayer.connection, conn.isVideoMirroringSupported {
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
        if let orientation = self.videoOrientation {
            view.videoOrientation = orientation
        }
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if let orientation = self.videoOrientation {
            uiView.videoOrientation = orientation
        }
    }
}
