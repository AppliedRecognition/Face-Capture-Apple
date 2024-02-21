//
//  FaceCaptureViewConfiguration.swift
//  
//
//  Created by Jakub Dolejs on 21/02/2024.
//

import Foundation
import SwiftUI

public class FaceCaptureViewConfiguration {
    
    public let useBackCamera: Bool
    public var textPromptProvider: Binding<TextPromptProvider>! = nil
    public var textPrompt: Binding<String>?
    public var showTextPrompts: Bool
    public var showCancelButton: Bool
    
    public init(useBackCamera: Bool = false, textPromptProvider: Binding<TextPromptProvider>? = nil, textPrompt: Binding<String>? = nil, showTextPrompts: Bool = true, showCancelButton: Bool = true) {
        self.useBackCamera = useBackCamera
        self.textPrompt = textPrompt
        self.showTextPrompts = showTextPrompts
        self.showCancelButton = showCancelButton
        self.textPromptProvider = textPromptProvider ?? Binding(get: {
            { faceTrackingResult in
                switch faceTrackingResult {
                case .created:
                    return NSLocalizedString("Preparing face detection", bundle: .module, comment: "")
                case .faceFixed, .faceAligned, .paused:
                    return NSLocalizedString("Great, hold it", bundle: .module, comment: "")
                case .faceMisaligned:
                    return NSLocalizedString("Turn to follow the arrow", bundle: .module, comment: "")
                default:
                    return NSLocalizedString("Align your face with the oval", tableName: "FaceCapture", bundle: .module, comment: "")
                }
            }
        }, set: { provider in
            self.textPromptProvider.wrappedValue = provider
        })
    }
    
    public static var `default`: FaceCaptureViewConfiguration {
        .init()
    }
}
