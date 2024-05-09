//
//  NavStackView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import SwiftUI
import FaceCapture

struct NavStackView: View {
    
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
                    let session = createFaceCaptureSession()
                    self.navigationPath.append(session)
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
            FaceCaptureNavigationView(session: session, useBackCamera: self.useBackCamera) { result in
                self.navigationPath.removeLast()
                self.navigationPath.append(result)
            }
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
    }
}
