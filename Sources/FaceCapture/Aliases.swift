//
//  Aliases.swift
//
//
//  Created by Jakub Dolejs on 16/02/2024.
//

import Foundation

/// Alias for function that accepts ``FaceTrackingResult`` and outputs a text prompt to the user based on the result
/// - Since: 1.0.0
public typealias TextPromptProvider = (FaceTrackingResult) -> String

/// Alias for a function that consumes a ``FaceCaptureSessionResult``
/// - Since: 1.0.0
public typealias OnFaceCaptureSessionResult = (FaceCaptureSessionResult) -> Void
