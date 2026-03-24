//
//  FaceCaptureResultViewModel.swift
//  Face Capture Demo
//

import Foundation
import FaceCapture
import Serialization

@MainActor
class FaceCaptureResultViewModel: ObservableObject {

    @Published var zippedResult: Data?

    private let result: FaceCaptureSessionResult

    init(result: FaceCaptureSessionResult) {
        self.result = result
    }

    func prepareShareData() async {
        guard let capture = result.capturedFaces.first else { return }
        let data = await Task.detached(priority: .utility) {
            try? ImagePackage(image: capture.image, face: capture.face).serialized()
        }.value
        zippedResult = data
    }
}
