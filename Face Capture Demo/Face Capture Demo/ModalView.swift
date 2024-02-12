//
//  ModalView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import FaceCapture

struct ModalView: View {
    
    @EnvironmentObject var faceCaptureSessionManager: FaceCaptureSessionManager
    @Binding var navigationPath: NavigationPath
    var useBackCamera: Bool {
        Settings().useBackCamera
    }
    let title: String
    let description: String
    
    var body: some View {
        VStack {
            HStack {
                Text(self.description)
                Spacer()
            }
            Divider().padding(.vertical, 8)
            HStack {
                Button {
                    self.faceCaptureSessionManager.startSession(settings: FaceCaptureSessionSettings.fromDefaults)
                } label: {
                    Image(systemName: "camera.fill")
                    Text("Start capture")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            Spacer()
        }
        .padding()
        .navigationDestination(for: FaceCaptureSessionResult.self) { result in
            FaceCaptureResultView(result: result)
        }
        .faceCaptureSessionSheet(sessionManager: self.faceCaptureSessionManager, useBackCamera: self.useBackCamera, onResult: { result in
            self.navigationPath.append(result)
        })
        .navigationTitle(self.title)
    }
}
