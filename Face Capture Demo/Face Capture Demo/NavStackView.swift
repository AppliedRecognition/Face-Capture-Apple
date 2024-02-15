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
        .navigationTitle(self.title)
        .navigationDestination(for: FaceCaptureSession.self) { session in
            NavigationStackFaceCaptureSessionView(session: session, navigationPath: self.$navigationPath, useBackCamera: self.useBackCamera) { result in
                self.navigationPath.append(result)
            }
        }
        .navigationDestination(for: FaceCaptureSessionResult.self) { result in
            FaceCaptureResultView(result: result)
        }
        .toolbar {
            ToolbarItem {
                NavigationLink {
                    TipsView()
                        .navigationTitle("Tips")
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .onReceive(self.faceCaptureSessionManager.$isSessionRunning) { running in
            if running, let session = self.faceCaptureSessionManager.session {
                self.navigationPath.append(session)
            }
        }
    }
}
