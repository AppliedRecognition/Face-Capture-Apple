//
//  Face_Capture_DemoApp.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import FaceCapture

@main
struct Face_Capture_DemoApp: App {
    
    @State var navigationPath = NavigationPath()
    let sessionManager: FaceCaptureSessionManager
    
    init() {
        self.sessionManager = FaceCaptureSessionManager()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: self.$navigationPath) {
                IndexView(navigationPath: self.$navigationPath)
            }
            .environmentObject(self.sessionManager)
            .onChange(of: self.navigationPath) { path in
                if path.isEmpty {
                    self.sessionManager.cancelSession()
                }
            }
        }
    }
}
