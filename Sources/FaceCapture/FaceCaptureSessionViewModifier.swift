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
    let textPromptProvider: TextPromptProvider?
    let onTextPromptChange: OnTextPromptChange?
    let onResult: OnFaceCaptureSessionResult?
    
    public init(sessionManager: FaceCaptureSessionManager, useBackCamera: Bool=false, textPromptProvider: TextPromptProvider?=nil, onTextPromptChange: OnTextPromptChange?=nil, onResult: OnFaceCaptureSessionResult?=nil) {
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
                    ZStack(alignment: .bottom) {
                        FaceCaptureSessionView(session: session, useBackCamera: self.useBackCamera, textPromptProvider: self.textPromptProvider, onTextPromptChange: self.onTextPromptChange, onResult: self.onResult)
                        Button {
                            self.sessionManager.cancelSession()
                        } label: {
                            Text("Cancel", bundle: .module)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemBackground)))
                        .padding(.bottom, 48)
                    }
                    .ignoreSafeArea()
                } else {
                    EmptyView()
                }
            }
    }
}

public extension View {
    
    func faceCaptureSessionSheet(sessionManager: FaceCaptureSessionManager, useBackCamera: Bool=false, textPromptProvider: TextPromptProvider?=nil, onTextPromptChange: OnTextPromptChange?=nil, onResult: OnFaceCaptureSessionResult?=nil) -> some View {
        return self.modifier(FaceCaptureSessionViewModifier(sessionManager: sessionManager, useBackCamera: useBackCamera, textPromptProvider: textPromptProvider, onTextPromptChange: onTextPromptChange, onResult: onResult))
    }
}

fileprivate struct IgnoreSafeArea: ViewModifier {
    
    func body(content: Content) -> some View {
        if #available(iOS 14, *) {
            content.ignoresSafeArea()
        } else {
            content.edgesIgnoringSafeArea(.all)
        }
    }
}

fileprivate extension View {
    
    func ignoreSafeArea() -> some View {
        self.modifier(IgnoreSafeArea())
    }
}
