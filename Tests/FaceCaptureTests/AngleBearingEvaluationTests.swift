import XCTest
import VerIDCommonTypes
@testable import FaceCapture

final class AngleBearingEvaluationTests: XCTestCase {

    private var settings: FaceCaptureSessionSettings!
    private var eval: AngleBearingEvaluation!

    override func setUp() {
        settings = FaceCaptureSessionSettings()
        eval = AngleBearingEvaluation(sessionSettings: settings)
    }

    // MARK: - Helpers

    private func angle(yaw: Float = 0, pitch: Float = 0) -> EulerAngle<Float> {
        var a = EulerAngle<Float>()
        a.yaw = yaw
        a.pitch = pitch
        return a
    }

    // MARK: - matchesBearing

    func testStraightFaceMatchesStraightBearing() {
        XCTAssertTrue(eval.angle(angle(), matchesBearing: .straight))
    }

    func testLeftTurnMatchesLeftBearing() {
        XCTAssertTrue(eval.angle(angle(yaw: -20), matchesBearing: .left))
    }

    func testRightTurnMatchesRightBearing() {
        XCTAssertTrue(eval.angle(angle(yaw: 20), matchesBearing: .right))
    }

    func testStraightFaceDoesNotMatchLeftBearing() {
        XCTAssertFalse(eval.angle(angle(), matchesBearing: .left))
    }

    // STRAIGHT yaw window is (-(yawThreshold - tolerance), +(yawThreshold - tolerance)) exclusive.
    // Boundary value = 17 - 5 = 12; condition is yaw < 12, so 12.0 does NOT match.
    func testBoundaryYawDoesNotMatchStraight() {
        let boundaryYaw = settings.yawThreshold - settings.yawThresholdTolerance
        XCTAssertFalse(eval.angle(angle(yaw: boundaryYaw), matchesBearing: .straight))
    }

    // MARK: - offsetFromAngle(_:toBearing:)

    func testOffsetIsZeroWhenAlreadyOnBearing() {
        let offset = eval.offsetFromAngle(angle(), toBearing: .straight)
        XCTAssertEqual(offset.yaw, 0, accuracy: 0.001)
        XCTAssertEqual(offset.pitch, 0, accuracy: 0.001)
    }

    func testOffsetIsNonZeroWhenMisaligned() {
        let offset = eval.offsetFromAngle(angle(), toBearing: .left)
        XCTAssertNotEqual(offset.yaw, 0)
    }

    // MARK: - isBetweenBearing

    // Halfway between STRAIGHT (yaw=0) and LEFT (yaw=-yawThreshold=-17): yaw = -8.5.
    // -8.5 is inside the STRAIGHT window (-12, 12), so it matches STRAIGHT, making
    // isBetweenBearing return true immediately.
    func testAngleHalfwayBetweenStraightAndLeftIsInBetween() {
        let halfwayYaw = -(settings.yawThreshold / 2)
        XCTAssertTrue(eval.angle(angle(yaw: halfwayYaw), isBetweenBearing: .straight, and: .left))
    }

    // yaw = +25 is in the opposite direction from STRAIGHT → LEFT and outside the
    // start-bearing radius (17°), so it should NOT be between the two bearings.
    func testAngleOppositeDirectionIsNotBetween() {
        XCTAssertFalse(eval.angle(angle(yaw: 25), isBetweenBearing: .straight, and: .left))
    }
}
