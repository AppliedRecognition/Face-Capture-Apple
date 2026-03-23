//
//  FaceCaptureViewState.swift
//
//
//  Created by Jakub Dolejs on 23/03/2026.
//

import Foundation
import AVFoundation
import VerIDCommonTypes

internal struct FaceCaptureViewState {

    var serialNumber: UInt64 = 0
    var startTime: Double? = nil

    mutating func processImage(_ sample: Image, session: FaceCaptureSession, viewSize: CGSize) {
        let now = CACurrentMediaTime()
        if startTime == nil { startTime = now }
        let elapsed = now - startTime!
        session.submitImageInput(FaceCaptureSessionImageInput(serialNumber: serialNumber, time: elapsed, image: sample, viewSize: viewSize))
        serialNumber += 1
    }
}
