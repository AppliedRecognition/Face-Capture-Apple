//
//  NavigationStackFaceCaptureSessionView.swift
//
//
//  Created by Jakub Dolejs on 07/02/2024.
//

import SwiftUI

@available(iOS 16, *)
public struct NavigationStackFaceCaptureSessionView: View {
    
    public let session: FaceCaptureSession
    @Binding public var navigationPath: NavigationPath
    let useBackCamera: Bool
    let textPromptProvider: TextPromptProvider?
    let onTextPromptChange: OnTextPromptChange?
    public let onResult: OnFaceCaptureSessionResult
    @State var promptText: String = Bundle.module.localizedString(forKey: "Preparing face detection", value: nil, table: nil)
    
    public init(session: FaceCaptureSession, navigationPath: Binding<NavigationPath>, useBackCamera: Bool=false, textPromptProvider: TextPromptProvider?=nil, onTextPromptChange: OnTextPromptChange?=nil, onResult: @escaping OnFaceCaptureSessionResult) {
        self.session = session
        self._navigationPath = navigationPath
        self.useBackCamera = useBackCamera
        self.textPromptProvider = textPromptProvider
        self.onTextPromptChange = onTextPromptChange
        self.onResult = onResult
    }
    
    public var body: some View {
        FaceCaptureSessionView(session: self.session, useBackCamera: self.useBackCamera, showTextPrompts: false, textPromptProvider: self.textPromptProvider, onTextPromptChange: { text in
            self.promptText = text
            self.onTextPromptChange?(text)
        }) { result in
            self.navigationPath.removeLast()
            self.onResult(result)
        }
        .navigationTitle(self.promptText)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if self.session.result == nil {
                self.session.cancel()
            }
        }
    }
}
