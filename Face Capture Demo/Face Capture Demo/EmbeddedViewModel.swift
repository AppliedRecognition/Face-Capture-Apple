//
//  EmbeddedViewModel.swift
//  Face Capture Demo
//

import Foundation
import FaceCapture

@MainActor
class EmbeddedViewModel: ObservableObject {

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

    func cancelCapture() {
        session?.cancel()
        session = nil
    }

    func clearSession() {
        session = nil
    }
}
