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
    @State var session: FaceCaptureSession?
    @State var result: FaceCaptureSessionResult? = nil
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
                    self.session = createFaceCaptureSession()
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
        .sheet(item: self.$session) { session in
            FaceCaptureView(session: session, result: self.$result, configuration: FaceCaptureViewConfiguration(useBackCamera: self.useBackCamera))
        }
        .onChange(of: self.result) { result in
            if let result = result {
                if case .cancelled = result {} else {
                    Task { @MainActor in
                        self.navigationPath.append(result)
                    }
                }
            }
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
