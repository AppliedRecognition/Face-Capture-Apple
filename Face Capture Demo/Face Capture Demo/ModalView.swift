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
    
    var body: some View {
        VStack {
            HStack {
                IntroString()
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
        .navigationDestination(for: FaceCaptureSessionResult.self) { result in
            FaceCaptureResultView(result: result)
        }
        .faceCaptureSessionSheet(sessionManager: self.faceCaptureSessionManager, onResult: { result in
            self.navigationPath.append(result)
        })
        .navigationTitle("Modal")
    }
}

fileprivate struct IntroString: View {
    var body: some View {
        Text("This example shows how to present a face capture session in a sheet. Simply add the ")
        + Text(".faceCaptureSessionSheet()").font(.system(.body, design: .monospaced))
        + Text(" view modifier and the sheet will appear when you call ")
        + Text("startSession()").font(.system(.body, design: .monospaced))
        + Text(" on the session manager.")
    }
}
