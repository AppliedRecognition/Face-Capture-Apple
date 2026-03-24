import XCTest
import VerIDCommonTypes
@testable import FaceCapture

final class DefaultFaceTrackingResultTransformDelegateTests: XCTestCase {

    // MARK: - Helpers

    // Creates a CGImage using DeviceRGB + BGRA byte order so vImageConverter_CreateWithCGImageFormat
    // always succeeds, regardless of the device's display color gamut.
    private func makeCGImage(width: Int = 600, height: Int = 800) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let cgImage = context.makeImage() else { fatalError("Failed to create CGImage") }
        return cgImage
    }

    private func makeTrackedProps() -> TrackedFaceSessionProperties {
        let size = CGSize(width: 600, height: 800)
        guard let image = Image(cgImage: makeCGImage()) else {
            fatalError()
        }
        let input = FaceCaptureSessionImageInput(serialNumber: 0, time: 0, image: image, viewSize: size)
        let faceWidth: CGFloat = 240
        let faceHeight: CGFloat = 300
        let bounds = CGRect(x: 180, y: 250, width: faceWidth, height: faceHeight)
        let face = Face(
            bounds: bounds,
            angle: .identity,
            quality: 10,
            landmarks: [],
            leftEye: CGPoint(x: bounds.minX + faceWidth * 0.3, y: bounds.minY + faceHeight * 0.3),
            rightEye: CGPoint(x: bounds.maxX - faceWidth * 0.3, y: bounds.minY + faceHeight * 0.3)
        )
        return TrackedFaceSessionProperties(input: input, requestedBearing: .straight, expectedFaceBounds: .zero, face: face, smoothedFace: face)
    }

    private func makeFaceAligned() -> FaceTrackingResult {
        .faceAligned(makeTrackedProps())
    }

    private func makeFaceFound() -> FaceTrackingResult {
        .faceFound(makeTrackedProps())
    }

    // A transformer that converts .faceAligned → .faceFound (preventing the default → .faceCaptured upgrade)
    private class AlignedToFoundTransformer: FaceTrackingResultTransformer {
        func transformFaceResult(_ faceTrackingResult: FaceTrackingResult) -> FaceTrackingResult {
            if case .faceAligned(let props) = faceTrackingResult {
                return .faceFound(props)
            }
            return faceTrackingResult
        }
    }

    // A transformer that records what it received, passing the result through unchanged
    private class RecordingTransformer: FaceTrackingResultTransformer {
        var callCount = 0
        var lastInput: FaceTrackingResult?
        func transformFaceResult(_ faceTrackingResult: FaceTrackingResult) -> FaceTrackingResult {
            callCount += 1
            lastInput = faceTrackingResult
            return faceTrackingResult
        }
    }

    // MARK: - Tests

    func testNoTransformersConvertsFaceAlignedToFaceCaptured() {
        let delegate = DefaultFaceTrackingResultTransformDelegate([])
        let result = delegate.transformFaceResult(makeFaceAligned())
        if case .faceCaptured = result { } else {
            XCTFail("Expected .faceCaptured, got \(result)")
        }
    }

    func testNoTransformersPassesThroughNonAlignedResult() {
        let delegate = DefaultFaceTrackingResultTransformDelegate([])
        let result = delegate.transformFaceResult(makeFaceFound())
        if case .faceFound = result { } else {
            XCTFail("Expected .faceFound, got \(result)")
        }
    }

    func testSingleTransformerResultIsUsed() {
        // AlignedToFoundTransformer converts .faceAligned → .faceFound, so the default
        // .faceAligned → .faceCaptured upgrade should NOT happen.
        let delegate = DefaultFaceTrackingResultTransformDelegate([AlignedToFoundTransformer()])
        let result = delegate.transformFaceResult(makeFaceAligned())
        if case .faceFound = result { } else {
            XCTFail("Expected .faceFound, got \(result)")
        }
    }

    func testMultipleTransformersAppliedInOrder() {
        let recorder = RecordingTransformer()
        // First transformer: .faceAligned → .faceFound
        // Second transformer: records its input (should be .faceFound, not .faceAligned)
        let delegate = DefaultFaceTrackingResultTransformDelegate([AlignedToFoundTransformer(), recorder])
        delegate.transformFaceResult(makeFaceAligned())
        XCTAssertEqual(recorder.callCount, 1)
        guard let input = recorder.lastInput else {
            XCTFail("Recorder did not receive any input")
            return
        }
        if case .faceFound = input { } else {
            XCTFail("Recorder should have received .faceFound (output of first transformer), got \(input)")
        }
    }
}
