import XCTest
import VerIDCommonTypes
@testable import FaceCapture

final class FaceCaptureSessionTests: XCTestCase {
    
    override func setUp() async throws {
        guard let identityURL = Bundle.module.url(forResource: "Ver-ID", withExtension: "identity", subdirectory: nil) else {
            throw NSError()
        }
        try await FaceCapture.default.load(identityFileURL: identityURL)
    }
    
    func testSession() throws {
        let session = FaceCaptureSession(settings: FaceCaptureSessionSettings(), sessionModuleFactories: FaceCaptureSessionModuleFactories(createFaceDetection: { MockFaceDetection() }, createFaceTrackingPlugins: { [] }, createFaceTrackingResultTransformers: { [] }))
        var serial: UInt64 = 0
        let start = CACurrentMediaTime()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            do {
                if session.result != nil {
                    timer.invalidate()
                    return
                }
                let time = CACurrentMediaTime() - start
                let image = self.createImage()
                try session.submitImageInput(FaceCaptureSessionImageInput(serialNumber: serial, time: time, image: image.convertToImage()))
                serial += 1
            } catch {
                timer.invalidate()
            }
        }
        let expectation = XCTestExpectation(description: "Emit a result")
        let cancellable = session.$result.sink { result in
            if result != nil {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: session.settings.maxDuration)
        cancellable.cancel()
        timer.invalidate()
        guard let result = session.result else {
            XCTFail("Session result is nil")
            return
        }
        if case .failure(_, _, let error) = result {
            XCTFail("Session failed: \(error)")
            return
        } else if case .cancelled = result {
            XCTFail("Session cancelled")
        }
    }
    
    func testFailSessionInPlugin() throws {
        let session = FaceCaptureSession(settings: FaceCaptureSessionSettings(), sessionModuleFactories: FaceCaptureSessionModuleFactories(createFaceDetection: { MockFaceDetection() }, createFaceTrackingPlugins: { [MockThrowingFaceTrackingPlugin()] }, createFaceTrackingResultTransformers: { [] }))
        var serial: UInt64 = 0
        let start = CACurrentMediaTime()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            do {
                if session.result != nil {
                    timer.invalidate()
                    return
                }
                let time = CACurrentMediaTime() - start
                let image = self.createImage()
                try session.submitImageInput(FaceCaptureSessionImageInput(serialNumber: serial, time: time, image: image.convertToImage()))
                serial += 1
            } catch {
                timer.invalidate()
            }
        }
        let expectation = XCTestExpectation(description: "Emit a result")
        let cancellable = session.$result.sink { result in
            if result != nil {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: session.settings.maxDuration)
        cancellable.cancel()
        timer.invalidate()
        guard let result = session.result else {
            XCTFail("Session result is nil")
            return
        }
        if case .success = result {
            XCTFail("Session should have failed but it succeeded")
            return
        } else if case .cancelled = result {
            XCTFail("Session cancelled")
        }
    }
    
    private func createImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 600, height: 800)).image { context in
            
        }
    }
}

class MockFaceDetection: FaceDetection {
    
    func detectFacesInImage(_ image: Image, limit: Int) throws -> [Face] {
        let faceWidth: CGFloat
        let faceHeight: CGFloat
        if image.width > image.height {
            faceHeight = CGFloat(image.height) * 0.8
            faceWidth = faceHeight * 0.8
        } else {
            faceWidth = CGFloat(image.width) * 0.6
            faceHeight = faceWidth * 1.25
        }
        let bounds = CGRect(x: CGFloat(image.width) / 2 - faceWidth / 2, y: CGFloat(image.height) / 2 - faceHeight / 2, width: faceWidth, height: faceHeight)
        return [Face(bounds: bounds, angle: .identity, quality: 10, landmarks: [])]
    }
}

class MockThrowingFaceTrackingPlugin: FaceTrackingPlugin {
    var name: String = "Mock throwing plugin"
    
    func processFaceTrackingResult(_ faceTrackingResult: FaceTrackingResult) throws -> String {
        if case .faceFixed = faceTrackingResult {
            throw FaceCaptureError.passiveLivenessCheckFailed("Test")
        }
        return "Passed"
    }
    
    func createSummaryFromResults(_ results: [FaceTrackingPluginResult<String>]) async -> String {
        "Done"
    }
    
    typealias Element = String
}
