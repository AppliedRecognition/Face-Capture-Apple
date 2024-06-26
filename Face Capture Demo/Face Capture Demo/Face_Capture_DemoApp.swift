//
//  Face_Capture_DemoApp.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import FaceCapture
import SpoofDeviceDetection
import SpoofDeviceDetectionModel

@main
struct Face_Capture_DemoApp: App {
    
    @State var navigationPath = NavigationPath()
    @State var loadError: Error?
    @StateObject var faceCapture: FaceCapture = .default
    
    var body: some Scene {
        WindowGroup {
            if self.faceCapture.isLoaded {
                NavigationStack(path: self.$navigationPath) {
                    IndexView(navigationPath: self.$navigationPath)
                }
            } else if let error = self.loadError {
                Text("Failed to load: \(error.localizedDescription)")
            } else {
                ProgressView("Loading")
                    .task {
                        do {
                            try await self.faceCapture.load()
                        } catch {
                            self.loadError = error
                        }
                    }
            }
        }
    }
}

func createFaceCaptureSession() -> FaceCaptureSession {
    let moduleFactories: FaceCaptureSessionModuleFactories
    if let spoofDeviceDetector = try? SpoofDeviceDetector() {
        moduleFactories = .livenessDetection(detectors: [spoofDeviceDetector])
    } else {
        moduleFactories = .default
    }
    return FaceCaptureSession(settings: .fromDefaults, sessionModuleFactories: moduleFactories)
}
