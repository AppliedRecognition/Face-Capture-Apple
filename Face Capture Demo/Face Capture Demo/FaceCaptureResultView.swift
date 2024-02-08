//
//  FaceCaptureResultView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 07/02/2024.
//

import SwiftUI
import FaceCapture

struct FaceCaptureResultView: View {
    
    let result: FaceCaptureSessionResult
    
    var body: some View {
        VStack {
            switch result {
            case .success(faceCaptures: let faceCaptures, metadata: _):
                if var capture = faceCaptures.first, let faceImage = capture.faceImage {
                    HStack {
                        Image(uiImage: faceImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                HStack {
                    Text("Face capture succeeded")
                    Spacer()
                }
            case .failure(faceCaptures: _, metadata: _, error: let error):
                HStack {
                    Text("Face capture failed: \(error.localizedDescription)")
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Face capture result")
        .navigationBarTitleDisplayMode(.large)
    }
}
