//
//  Face_Capture_DemoApp.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import FaceCapture
import AVFoundation

@main
struct Face_Capture_DemoApp: App {
    
    @State var navigationPath = NavigationPath()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: self.$navigationPath) {
                IndexView(navigationPath: self.$navigationPath)
            }
        }
    }
}

func createFaceCaptureSession() -> FaceCaptureSession {
    let settings = Settings()
    let cameraPosition: AVCaptureDevice.Position = settings.useBackCamera ? .back : .front
    if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
        return FaceCaptureSession(settings: .fromDefaults, sessionModuleFactories: .withDepthBasedLiveness)
    } else {
        return FaceCaptureSession(settings: .fromDefaults, sessionModuleFactories: .fromDefaults)
    }
}
