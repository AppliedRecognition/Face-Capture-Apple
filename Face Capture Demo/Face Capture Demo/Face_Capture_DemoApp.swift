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

    @StateObject private var settings = Settings()
    @State var navigationPath = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: self.$navigationPath) {
                IndexView(navigationPath: self.$navigationPath)
            }
            .environmentObject(settings)
        }
    }
}
