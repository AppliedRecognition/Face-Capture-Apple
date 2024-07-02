//
//  Settings.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 09/02/2024.
//

import Foundation
import FaceCapture
import SpoofDeviceDetection
import FaceDetectionMediaPipe

class Settings: ObservableObject {
    
    struct Keys {
        static let useBackCamera = "useBackCamera"
        static let enableActiveLiveness = "enableActiveLiveness"
        static let faceOvalWidth = "faceOvalWidth"
        static let faceOvalHeight = "faceOvalHeight"
        static let faceDetection = "faceDetection"
    }
    
    @Published var useBackCamera: Bool = false {
        didSet {
            UserDefaults.standard.set(self.useBackCamera, forKey: Keys.useBackCamera)
        }
    }
    @Published var enableActiveLiveness: Bool = false {
        didSet {
            UserDefaults.standard.set(self.enableActiveLiveness, forKey: Keys.enableActiveLiveness)
        }
    }
    @Published var faceOvalWidth: CGFloat {
        didSet {
            UserDefaults.standard.set(self.faceOvalWidth * 0.01, forKey: Keys.faceOvalWidth)
        }
    }
    @Published var faceOvalHeight: CGFloat {
        didSet {
            UserDefaults.standard.set(self.faceOvalHeight * 0.01, forKey: Keys.faceOvalHeight)
        }
    }
    @Published var faceDetection: FaceDetectionImplementation {
        didSet {
            UserDefaults.standard.set(self.faceDetection.rawValue, forKey: Keys.faceDetection)
        }
    }
    
    init() {
        let settings = FaceCaptureSessionSettings()
        UserDefaults.standard.register(defaults: [
            Keys.useBackCamera: false,
            Keys.enableActiveLiveness: false,
            Keys.faceOvalWidth: settings.expectedFaceBoundsWidth,
            Keys.faceOvalHeight: settings.expectedFaceBoundsHeight,
            Keys.faceDetection: FaceDetectionImplementation.mediaPipe.rawValue
        ])
        self.useBackCamera = UserDefaults.standard.bool(forKey: Keys.useBackCamera)
        self.enableActiveLiveness = UserDefaults.standard.bool(forKey: Keys.enableActiveLiveness)
        self.faceOvalWidth = UserDefaults.standard.double(forKey: Keys.faceOvalWidth) * 100
        self.faceOvalHeight = UserDefaults.standard.double(forKey: Keys.faceOvalHeight) * 100
        self.faceDetection = FaceDetectionImplementation(rawValue: UserDefaults.standard.string(forKey: Keys.faceDetection) ?? FaceDetectionImplementation.mediaPipe.rawValue) ?? .mediaPipe
    }
}

extension FaceCaptureSessionSettings {
    
    static var fromDefaults: FaceCaptureSessionSettings {
        let settings = Settings()
        var sessionSettings = FaceCaptureSessionSettings()
        sessionSettings.faceCaptureCount = settings.enableActiveLiveness ? 2 : 1
        sessionSettings.expectedFaceBoundsWidth = settings.faceOvalWidth / 100
        sessionSettings.expectedFaceBoundsHeight = settings.faceOvalHeight / 100
        return sessionSettings
    }
}

extension FaceCaptureSessionModuleFactories {
    
    static var fromDefaults: FaceCaptureSessionModuleFactories {
        let settings = Settings()
        return .livenessDetection(createSpoofDetectors: {
            if let spoofDeviceDetector = try? SpoofDeviceDetector() {
                return [spoofDeviceDetector]
            }
            return []
        }, createFaceDetection: {
            do {
                switch settings.faceDetection {
                case .apple:
                    return AppleFaceDetection()
                case .mediaPipe:
                    return try FaceDetectionMediaPipe()
                case .mediaPipeLandmarker:
                    return try FaceLandmarkDetectionMediaPipe()
                }
            } catch {
                return AppleFaceDetection()
            }
        })
    }
}

enum FaceDetectionImplementation: String, CaseIterable {
    case apple = "Apple face detection"
    case mediaPipe = "MediaPipe face detector"
    case mediaPipeLandmarker = "MediaPipe landmarker"
}
