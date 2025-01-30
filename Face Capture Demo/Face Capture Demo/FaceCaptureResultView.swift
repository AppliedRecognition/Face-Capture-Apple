//
//  FaceCaptureResultView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 07/02/2024.
//

import SwiftUI
import FaceCapture
import Ver_ID_3_Serialization
import UniformTypeIdentifiers

struct FaceCaptureResultView: View {
    
    let result: FaceCaptureSessionResult
    let title: String
    @State var isPresentingShareSheet = false
    @State var zippedResult: Data? = nil
    
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
            case .success(capturedFaces: let faceCaptures, metadata: let metadata):
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
                ResultMetadataView(metadata: metadata)
            case .failure(capturedFaces: _, metadata: let metadata, error: let error):
                HStack {
                    Text("Face capture failed: \(error.localizedDescription)")
                    Spacer()
                }
                .padding(.bottom, 8)
                ResultMetadataView(metadata: metadata)
            case .cancelled:
                HStack {
                    Text("Session cancelled")
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle(self.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem {
                Button {
                    self.isPresentingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(self.zippedResult == nil)
            }
        }
        .sheet(isPresented: self.$isPresentingShareSheet) {
            if let zip = self.zippedResult, let image = self.result.capturedFaces.first?.image.toCGImage() {
                ShareSheet(items: [Image3DActivityItem(data: zip, name: "Image", image: UIImage(cgImage: image))])
            }
//            if let cgImage = self.result.capturedFaces.first?.image.toCGImage() {
//                let uiImage = UIImage(cgImage: cgImage)
//                ShareSheet(items: [uiImage])
//            }
        }
        .task {
            if let capture = self.result.capturedFaces.first, 
                let imageData = try? capture.image.serialized(),
                let faceData = try? capture.face.serialized()
            {
                let imageSize = UInt32(imageData.count)
                var data = Data()
                data.append(contentsOf: withUnsafeBytes(of: imageSize.bigEndian, Array.init))
                data.append(imageData)
                let faceSize = UInt32(faceData.count)
                data.append(contentsOf: withUnsafeBytes(of: faceSize.bigEndian, Array.init))
                data.append(faceData)
                self.zippedResult = data
            }
        }
    }
}

struct ResultMetadataView: View {
    
    let metadata: [String:TaskResults]
    
    var body: some View {
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
        
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    
    let items: [Any]
    
    func makeUIViewController(context: Context) -> some UIViewController {
        UIActivityViewController(activityItems: self.items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class Image3DActivityItem: NSObject, UIActivityItemSource {
    
    let data: Data
    let name: String
    let image: UIImage
    
    init(data: Data, name: String, image: UIImage) {
        self.data = data
        self.name = name
        self.image = image
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        self.data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        self.data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        self.name
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        UTType.data.identifier
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        UIGraphicsImageRenderer(size: size).image { context in
            let scale: CGFloat
            if size.width/size.height > self.image.size.width/self.image.size.height {
                scale = size.width / self.image.size.width
            } else {
                scale = size.height / self.image.size.height
            }
            let width: CGFloat = self.image.size.width * scale
            let height: CGFloat = self.image.size.height * scale
            self.image.draw(in: CGRect(x: size.width / 2 - width / 2, y: size.height / 2 - height / 2, width: width, height: height))
        }
    }
}
