//
//  NavStackView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import SwiftUI
import FaceCapture

struct NavStackView: View {
    
    @EnvironmentObject var faceCaptureSessionManager: FaceCaptureSessionManager
    @Binding var navigationPath: NavigationPath
    let settings = Settings()
    let title: String
    let description: String
    
    var body: some View {
        VStack {
            HStack {
                Text(self.description)
                Spacer()
            }
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
        .navigationTitle(self.title)
        .navigationDestination(for: FaceCaptureSession.self) { session in
            NavigationStackFaceCaptureSessionView(session: session, navigationPath: self.$navigationPath, useBackCamera: self.settings.useBackCamera) { result in
                self.navigationPath.append(result)
            }
        }
        .navigationDestination(for: FaceCaptureSessionResult.self) { result in
            FaceCaptureResultView(result: result)
        }
        .onReceive(self.faceCaptureSessionManager.$isSessionRunning) { running in
            if running, let session = self.faceCaptureSessionManager.session {
                self.navigationPath.append(session)
            }
        }
    }
}
