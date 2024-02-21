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
    @State var isCapturing: Bool = false
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
                    self.isCapturing = true
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
        .sheet(isPresented: self.$isCapturing) {
            FaceCaptureView(configuration: .default, isCapturing: self.$isCapturing, result: self.$result)
        }
        .onChange(of: self.result) { result in
            if let result = result {
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
        .navigationTitle(self.title)
    }
}
