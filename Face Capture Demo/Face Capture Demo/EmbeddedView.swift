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
    @EnvironmentObject private var settings: Settings
    @StateObject private var viewModel = EmbeddedViewModel()

    let title: String
    let description: String
    @State var promptText: String = ""
    @State var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode = .large

    var body: some View {
        GeometryReader { geometryReader in
            VStack {
                if let session = viewModel.session, viewModel.result == nil {
                    FaceCaptureView(session: session, result: $viewModel.result, configuration: FaceCaptureViewConfiguration(useBackCamera: settings.useBackCamera, textPrompt: self.$promptText, showTextPrompts: false, showCancelButton: false))
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
                    if viewModel.session != nil && viewModel.result == nil {
                        Button {
                            viewModel.cancelCapture()
                        } label: {
                            Image(systemName: "hand.raised.fill")
                            Text("Cancel capture")
                        }
                    } else {
                        Button {
                            viewModel.startCapture(settings: settings)
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
            .onChange(of: viewModel.result) { result in
                guard let result else { return }
                viewModel.clearSession()
                if case .cancelled = result { return }
                Task { @MainActor in
                    self.navigationPath.append(result)
                }
            }
            .onChange(of: viewModel.session) { session in
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
