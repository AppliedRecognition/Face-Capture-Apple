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
    
    @ObservedObject public var session: FaceCaptureSession
    public let onResult: ((FaceCaptureSessionResult) -> Void)?
    
    public init(session: FaceCaptureSession, onResult: @escaping (FaceCaptureSessionResult) -> Void) {
        self.session = session
        self.onResult = onResult
    }
    
    public init(session: FaceCaptureSession) {
        self.session = session
        self.onResult = nil
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.session.isStarted) {
                if #available(iOS 14, *) {
                    FaceCaptureSessionView(session: self.session)
                        .ignoresSafeArea()
                } else {
                    FaceCaptureSessionView(session: self.session)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .onReceive(Just(self.session.result)) { result in
                if let res = result, let onResult = self.onResult {
                    onResult(res)
                }
            }
    }
}

public extension View {
    
    func faceCaptureSession(_ session: FaceCaptureSession, onResult: @escaping (FaceCaptureSessionResult) -> Void) -> some View {
        return self.modifier(FaceCaptureSessionViewModifier(session: session, onResult: onResult))
    }
    
    func faceCaptureSession(_ session: FaceCaptureSession) -> some View {
        return self.modifier(FaceCaptureSessionViewModifier(session: session))
    }
}
