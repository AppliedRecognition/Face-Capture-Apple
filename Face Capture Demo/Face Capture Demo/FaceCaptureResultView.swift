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
    let title: String
    
    init(result: FaceCaptureSessionResult) {
        self.result = result
        if case .success = result {
            self.title = "Succeeded"
        } else {
            self.title = "Failed"
        }
    }
    
    var body: some View {
        VStack {
            switch result {
            case .success(faceCaptures: let faceCaptures, metadata: let metadata):
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
                ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { name, value in
                    Divider()
                    HStack {
                        Text(name).font(.headline)
                        Spacer()
                    }
                    HStack {
                        Text(value.summary).offset(x: 16)
                        Spacer()
                    }
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
        .navigationTitle(self.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
