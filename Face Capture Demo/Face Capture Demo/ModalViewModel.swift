//
//  ModalViewModel.swift
//  Face Capture Demo
//

import Foundation
import FaceCapture

@MainActor
class ModalViewModel: ObservableObject {

    @Published var session: FaceCaptureSession?
    @Published var result: FaceCaptureSessionResult?

    func startCapture(settings: Settings) {
        result = nil
        do {
            session = try CaptureSessionConfiguration.createFaceCaptureSession(settings: settings)
        } catch {
            result = .failure(capturedFaces: [], metadata: [:], error: error)
        }
    }
}
