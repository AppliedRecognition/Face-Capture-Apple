//
//  Settings.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 09/02/2024.
//

import Foundation
import FaceCapture

class Settings: ObservableObject {
    
    struct Keys {
        static let useBackCamera = "useBackCamera"
        static let enableActiveLiveness = "enableActiveLiveness"
        static let faceOvalWidth = "faceOvalWidth"
        static let faceOvalHeight = "faceOvalHeight"
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
    
    init() {
        let settings = FaceCaptureSessionSettings()
        UserDefaults.standard.register(defaults: [
            Keys.useBackCamera: false,
            Keys.enableActiveLiveness: false,
            Keys.faceOvalWidth: settings.expectedFaceBoundsWidth,
            Keys.faceOvalHeight: settings.expectedFaceBoundsHeight
        ])
        self.useBackCamera = UserDefaults.standard.bool(forKey: Keys.useBackCamera)
        self.enableActiveLiveness = UserDefaults.standard.bool(forKey: Keys.enableActiveLiveness)
        self.faceOvalWidth = UserDefaults.standard.double(forKey: Keys.faceOvalWidth) * 100
        self.faceOvalHeight = UserDefaults.standard.double(forKey: Keys.faceOvalHeight) * 100
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
