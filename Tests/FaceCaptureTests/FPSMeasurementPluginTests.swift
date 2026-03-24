import XCTest
import VerIDCommonTypes
@testable import FaceCapture

final class FPSMeasurementPluginTests: XCTestCase {

    // MARK: - Helpers

    // Creates a CGImage using DeviceRGB + BGRA byte order so vImageConverter_CreateWithCGImageFormat
    // always succeeds, regardless of the device's display color gamut.
    private func makeCGImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 400, space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let cgImage = context.makeImage() else { fatalError("Failed to create CGImage") }
        return cgImage
    }

    private func makeFaceFound(time: Double) -> FaceTrackingResult {
        let size = CGSize(width: 100, height: 100)
        guard let image = Image(cgImage: makeCGImage()) else { fatalError() }
        let input = FaceCaptureSessionImageInput(serialNumber: 0, time: time, image: image, viewSize: size)
        let face = Face(
            bounds: CGRect(x: 10, y: 10, width: 60, height: 75),
            angle: .identity,
            quality: 10,
            landmarks: [],
            leftEye: CGPoint(x: 25, y: 30),
            rightEye: CGPoint(x: 55, y: 30)
        )
        let props = TrackedFaceSessionProperties(input: input, requestedBearing: .straight, expectedFaceBounds: .zero, face: face, smoothedFace: face)
        return .faceFound(props)
    }

    private func makePluginResult(time: Double, measurement: FPSMeasurement) -> FaceTrackingPluginResult<FPSMeasurement> {
        FaceTrackingPluginResult(serialNumber: 0, time: time, result: measurement)
    }

    // MARK: - Tests

    func testThrowsOnResultWithoutTime() {
        let plugin = FPSMeasurementPlugin()
        let result = FaceTrackingResult.created(.straight)
        XCTAssertThrowsError(try plugin.processFaceTrackingResult(result)) { error in
            guard case .invalidFaceTrackingResult = error as? FaceCaptureError else {
                XCTFail("Expected FaceCaptureError.invalidFaceTrackingResult, got \(error)")
                return
            }
        }
    }

    func testStartTimeIsLatchedOnFirstResult() throws {
        let plugin = FPSMeasurementPlugin()
        XCTAssertNil(plugin.startTime)
        _ = try plugin.processFaceTrackingResult(makeFaceFound(time: 1.5))
        XCTAssertNotNil(plugin.startTime)
        XCTAssertEqual(plugin.startTime!, 1.5, accuracy: 0.001)
        // Second call must not overwrite startTime
        _ = try plugin.processFaceTrackingResult(makeFaceFound(time: 2.0))
        XCTAssertEqual(plugin.startTime!, 1.5, accuracy: 0.001)
    }

    func testZeroDurationDoesNotCrash() throws {
        let plugin = FPSMeasurementPlugin()
        let measurement = try plugin.processFaceTrackingResult(makeFaceFound(time: 0.0))
        // duration = 0, so sinceStart is guarded to 0
        XCTAssertEqual(measurement.sinceStart, 0, accuracy: 0.001)
    }

    func testRollingWindowPrunesOldEntries() throws {
        let plugin = FPSMeasurementPlugin()
        _ = try plugin.processFaceTrackingResult(makeFaceFound(time: 0.0))
        // At t=2.0, oneSecAgo = 1.0; the entry at t=0.0 is older than 1 s and gets pruned
        let measurement = try plugin.processFaceTrackingResult(makeFaceFound(time: 2.0))
        XCTAssertEqual(measurement.lastSecond, 1.0, accuracy: 0.001)
    }

    func testSinceStartIncreasesWithMoreFrames() throws {
        let plugin = FPSMeasurementPlugin()
        var last: FPSMeasurement!
        for i in 0..<5 {
            last = try plugin.processFaceTrackingResult(makeFaceFound(time: Double(i) * 0.2))
        }
        XCTAssertGreaterThan(last.sinceStart, 0)
        XCTAssertGreaterThan(last.lastSecond, 0)
    }

    func testSummaryFormatsCorrectly() async throws {
        let plugin = FPSMeasurementPlugin()
        let m1 = try plugin.processFaceTrackingResult(makeFaceFound(time: 1.0))
        let m2 = try plugin.processFaceTrackingResult(makeFaceFound(time: 2.0))
        let results = [makePluginResult(time: 1.0, measurement: m1),
                       makePluginResult(time: 2.0, measurement: m2)]
        let summary = await plugin.createSummaryFromResults(results)
        // sinceStart = totalCount / (lastTime - startTime) = 2 / (2.0 - 1.0) = 2.0
        XCTAssertEqual(summary, "2.0 frames per second")
    }

    func testSummaryForEmptyResultsIsUnavailable() async {
        let plugin = FPSMeasurementPlugin()
        let summary = await plugin.createSummaryFromResults([])
        XCTAssertEqual(summary, "Unavailable")
    }
}
