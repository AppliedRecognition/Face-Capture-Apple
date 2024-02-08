//
//  FaceCaptureSessionViewModifier.swift
//
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import Foundation
import Combine
import SwiftUI

public struct FaceCaptureSessionViewModifier: ViewModifier {
    
    @ObservedObject public var sessionManager: FaceCaptureSessionManager
    let useBackCamera: Bool
    let textPromptProvider: ((FaceTrackingResult) -> String)?
    let onTextPromptChange: ((String) -> Void)?
    let onResult: ((FaceCaptureSessionResult) -> Void)?
    
    public init(sessionManager: FaceCaptureSessionManager, useBackCamera: Bool=false, textPromptProvider: ((FaceTrackingResult) -> String)?=nil, onTextPromptChange: ((String) -> Void)?=nil, onResult: ((FaceCaptureSessionResult) -> Void)?=nil) {
        self.sessionManager = sessionManager
        self.useBackCamera = useBackCamera
        self.textPromptProvider = textPromptProvider
        self.onTextPromptChange = onTextPromptChange
        self.onResult = onResult
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$sessionManager.isSessionRunning) {
                if let session = self.sessionManager.session {
                    if #available(iOS 14, *) {
                        FaceCaptureSessionView(session: session, useBackCamera: self.useBackCamera, textPromptProvider: self.textPromptProvider, onTextPromptChange: self.onTextPromptChange, onResult: self.onResult)
                            .ignoresSafeArea()
                    } else {
                        FaceCaptureSessionView(session: session, useBackCamera: self.useBackCamera, textPromptProvider: self.textPromptProvider, onTextPromptChange: self.onTextPromptChange, onResult: self.onResult)
                            .edgesIgnoringSafeArea(.all)
                    }
                } else {
                    EmptyView()
                }
            }
    }
}

public extension View {
    
    func faceCaptureSessionSheet(sessionManager: FaceCaptureSessionManager, useBackCamera: Bool=false, textPromptProvider: ((FaceTrackingResult) -> String)?=nil, onTextPromptChange: ((String) -> Void)?=nil, onResult: ((FaceCaptureSessionResult) -> Void)?=nil) -> some View {
        return self.modifier(FaceCaptureSessionViewModifier(sessionManager: sessionManager, useBackCamera: useBackCamera, textPromptProvider: textPromptProvider, onTextPromptChange: onTextPromptChange, onResult: onResult))
    }
}
