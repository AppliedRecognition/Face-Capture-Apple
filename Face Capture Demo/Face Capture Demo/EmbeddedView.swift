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
    let title: String
    let description: String
    @State var promptText: String = ""
    @State var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode = .large
    let settings = Settings()
    
    var body: some View {
        GeometryReader { geometryReader in
            VStack {
                if let session = self.faceCaptureSessionManager.session, self.faceCaptureSessionManager.isSessionRunning {
                    FaceCaptureSessionView(session: session, useBackCamera: self.settings.useBackCamera, showTextPrompts: false, onTextPromptChange: { prompt in
                        self.promptText = prompt
                        self.navigationBarTitleDisplayMode = .inline
                    }) { result in
                        self.promptText = self.title
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
                        Text(self.description)
                        Spacer()
                    }
                }
                HStack {
                    if self.faceCaptureSessionManager.isSessionRunning {
                        Button {
                            self.faceCaptureSessionManager.cancelSession()
                            self.navigationBarTitleDisplayMode = .large
                            self.promptText = self.title
                        } label: {
                            Image(systemName: "hand.raised.fill")
                            Text("Cancel capture")
                        }
                    } else {
                        Button {
                            self.faceCaptureSessionManager.startSession(settings: FaceCaptureSessionSettings.fromDefaults)
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
            .onAppear(perform: {
                self.promptText = self.title
            })
        }
    }
}
