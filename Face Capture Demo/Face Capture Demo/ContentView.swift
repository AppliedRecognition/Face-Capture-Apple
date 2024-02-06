//
//  ContentView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import SwiftUI
import FaceCapture

struct ContentView: View {
    
    @StateObject var session: FaceCaptureSession = FaceCaptureSession()
    
    var body: some View {
        Group {
            if let result = session.result {
                if case .success(let faceCaptures, _) = result, var capture = faceCaptures.first, let image = capture.faceImage  {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else if case .failure(_, _, let error) = result {
                    Text(error.localizedDescription)
                }
                Button {
                    self.session.result = nil
                } label: {
                    Text("OK")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            } else {
                Button {
                    self.session.start()
                } label: {
                    Image(systemName: "camera.fill")
                    Text("Start capture")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .faceCaptureSession(self.session)
    }
}
