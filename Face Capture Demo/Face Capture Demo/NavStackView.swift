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
    
    var body: some View {
        VStack {
            HStack {
                Text("This example shows how to run a face capture session in a view pushed to a navigation stack. The session will start as soon as the view is pushed on to the stack. Once the session finishes the view is closed and the result is shown here.")
                Spacer()
            }
            HStack {
                Button {
                    self.faceCaptureSessionManager.startSession()
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
        .navigationTitle("Navigation stack")
        .navigationDestination(for: FaceCaptureSession.self) { session in
            NavigationStackFaceCaptureSessionView(session: session, navigationPath: self.$navigationPath) { result in
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
