//
//  Face_Capture_DemoApp.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import FaceCapture
import VerIDSDKIdentity

@main
struct Face_Capture_DemoApp: App {
    
    @State var navigationPath = NavigationPath()
    @State var sessionManager: FaceCaptureSessionManager?
    @State var loadError: String?
    
    var body: some Scene {
        WindowGroup {
            if let sessionMgr = self.sessionManager {
                NavigationStack(path: self.$navigationPath) {
                    IndexView(navigationPath: self.$navigationPath)
                }
                .environmentObject(sessionMgr)
                .onChange(of: self.navigationPath) { path in
                    if path.isEmpty {
                        sessionMgr.cancelSession()
                    }
                }
            } else if let error = self.loadError {
                Text("Failed to load: \(error)")
            } else {
                ProgressView("Loading")
                    .task {
                        if self.sessionManager == nil {
                            do {
                                self.sessionManager = try await FaceCaptureSessionManager()
                            } catch {
                                self.loadError = error.localizedDescription
                            }
                        }
                    }
            }
        }
    }
}
