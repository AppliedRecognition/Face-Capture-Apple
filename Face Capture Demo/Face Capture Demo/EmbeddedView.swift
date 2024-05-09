//
//  EmbeddedView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import SwiftUI
import FaceCapture

struct EmbeddedView: View {
    
    @Binding var navigationPath: NavigationPath
    let title: String
    let description: String
    @State var promptText: String = ""
    @State var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode = .large
    @State var session: FaceCaptureSession?
    @State var result: FaceCaptureSessionResult?
    var useBackCamera: Bool {
        Settings().useBackCamera
    }
    
    var body: some View {
        GeometryReader { geometryReader in
            VStack {
                if let session = self.session, self.result == nil {
                    FaceCaptureView(session: session, result: self.$result, configuration: FaceCaptureViewConfiguration(useBackCamera: self.useBackCamera, textPrompt: self.$promptText, showTextPrompts: false, showCancelButton: false))
                        .frame(height: geometryReader.size.height * 0.66)
                        .background {
                            RoundedRectangle(cornerRadius: 16).fill(Color.gray)
                        }
                } else {
                    HStack {
                        Text(self.description)
                        Spacer()
                    }
                    Divider().padding(.vertical, 8)
                }
                HStack {
                    if let session = self.session, self.result == nil {
                        Button {
                            session.cancel()
                        } label: {
                            Image(systemName: "hand.raised.fill")
                            Text("Cancel capture")
                        }
                    } else {
                        Button {
                            self.session = createFaceCaptureSession()
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
            .onAppear {
                self.promptText = self.title
            }
            .onChange(of: self.result) { result in
                if let result = result {
                    self.session = nil
                    if case .cancelled = result {} else {
                        self.navigationPath.append(result)
                    }
                }
            }
            .onChange(of: self.session) { session in
                if session != nil {
                    self.navigationBarTitleDisplayMode = .inline
                } else {
                    self.navigationBarTitleDisplayMode = .large
                    self.promptText = self.title
                }
            }
        }
    }
}
