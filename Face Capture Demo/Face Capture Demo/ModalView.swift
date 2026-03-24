//
//  ModalView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import FaceCapture

struct ModalView: View {

    @Binding var navigationPath: NavigationPath
    @EnvironmentObject private var settings: Settings
    @StateObject private var viewModel = ModalViewModel()

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
                    viewModel.startCapture(settings: settings)
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
        .sheet(item: $viewModel.session) { session in
            FaceCaptureView(session: session, result: $viewModel.result, configuration: FaceCaptureViewConfiguration(useBackCamera: settings.useBackCamera))
        }
        .onChange(of: viewModel.result) { result in
            guard let result else { return }
            if case .cancelled = result { return }
            navigationPath.append(result)
        }
        .toolbar {
            ToolbarItem {
                NavigationLink {
                    TipsView()
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .navigationTitle(self.title)
    }
}
