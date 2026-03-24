//
//  IndexViewModel.swift
//  Face Capture Demo
//

import Foundation
import FaceCapture

class IndexViewModel: ObservableObject {

    @Published var captureResult: FaceCaptureSessionResult?

    func runCaptureFunction(settings: Settings) {
        Task(priority: .utility) {
            let result = await FaceCapture.captureFaces { config in
                try CaptureSessionConfiguration.configureFaceCapture(configuration: &config, settings: settings)
            }
            if case .cancelled = result { return }
            await MainActor.run {
                self.captureResult = result
            }
        }
    }
}
