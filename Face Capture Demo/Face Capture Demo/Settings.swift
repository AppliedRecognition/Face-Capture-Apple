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
    @Published var faceOvalWidth: CGFloat = 60 {
        didSet {
            UserDefaults.standard.set(self.faceOvalWidth * 0.01, forKey: Keys.faceOvalWidth)
        }
    }
    @Published var faceOvalHeight: CGFloat = 80 {
        didSet {
            UserDefaults.standard.set(self.faceOvalHeight * 0.01, forKey: Keys.faceOvalHeight)
        }
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            Keys.useBackCamera: false,
            Keys.enableActiveLiveness: false,
            Keys.faceOvalWidth: 0.6,
            Keys.faceOvalHeight: 0.8
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
        sessionSettings.expectedFaceBoundsWidth = settings.faceOvalWidth
        sessionSettings.expectedFaceBoundsHeight = settings.faceOvalHeight
        return sessionSettings
    }
}
