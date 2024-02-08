//
//  EmbeddedView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import SwiftUI
import FaceCapture

struct EmbeddedView: View {
    
    @EnvironmentObject var faceCaptureSessionManager: FaceCaptureSessionManager
    @Binding var navigationPath: NavigationPath
    @State var promptText: String = "Embedded"
    @State var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode = .large
    
    var body: some View {
        GeometryReader { geometryReader in
            VStack {
                if let session = self.faceCaptureSessionManager.session, self.faceCaptureSessionManager.isSessionRunning {
                    FaceCaptureSessionView(session: session, showTextPrompts: false, onTextPromptChange: { prompt in
                        self.promptText = prompt
                        self.navigationBarTitleDisplayMode = .inline
                    }) { result in
                        self.promptText = "Embedded"
                        self.navigationBarTitleDisplayMode = .large
                        self.navigationPath.append(result)
                    }
                        .frame(height: geometryReader.size.height * 0.66)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray)
                        }
                } else {
                    HStack {
                        Text("This example shows how to embed a face capture session view in your layout.")
                        Spacer()
                    }
                }
                HStack {
                    if self.faceCaptureSessionManager.isSessionRunning {
                        Button {
                            self.faceCaptureSessionManager.cancelSession()
                            self.navigationBarTitleDisplayMode = .large
                            self.promptText = "Embedded"
                        } label: {
                            Image(systemName: "hand.raised.fill")
                            Text("Cancel capture")
                        }
                    } else {
                        Button {
                            self.faceCaptureSessionManager.startSession()
                        } label: {
                            Image(systemName: "camera.fill")
                            Text("Start capture")
                        }
                    }
                    Spacer()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle(self.promptText)
            .navigationBarTitleDisplayMode(self.navigationBarTitleDisplayMode)
            .navigationDestination(for: FaceCaptureSessionResult.self) { sessionResult in
                FaceCaptureResultView(result: sessionResult)
            }
//            .onFaceCaptureSessionResult(sessionManager: self.faceCaptureSessionManager) { result in
//                self.navigationPath.append(result)
//            }
        }
    }
}
