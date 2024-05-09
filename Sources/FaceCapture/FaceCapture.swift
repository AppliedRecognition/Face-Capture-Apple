//
//  FaceCapture.swift
//
//
//  Created by Jakub Dolejs on 20/02/2024.
//

import Foundation
import VerIDSDKIdentity
import VerIDLicence
import VerIDCommonTypes

/// - Since: 1.0.0
public class FaceCapture: ObservableObject {
    
    /// Default instance
    /// - Since: 1.0.0
    public static let `default`: FaceCapture = .init()
    /// Returns `true` if face capture is loaded
    /// - Since: 1.0.0
    @Published @MainActor private(set) public var isLoaded: Bool = false
    
    private init() {
    }
    
    /// Load the face capture library
    /// - Parameter identity: Ver-ID identity for your app
    /// - Since: 1.0.0
    public func load(identity: VerIDIdentity) async throws {
        let loaded = await MainActor.run {
            self.isLoaded
        }
        if loaded {
            return
        }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            await MainActor.run {
                self.isLoaded = true
            }
            return
        }
        let licence = try await VerIDLicence(identity: identity)
        try await licence.checkLicence()
        await MainActor.run {
            self.isLoaded = true
        }
        Task.detached {
            if let ca = try? licence.identity.certificate.issuer, ca != .standalone {
                await licence.reporting.sendReport(componentIdentifier: Bundle(for: type(of: self)).bundleIdentifier ?? "FaceCapture", componentVersion: version.string, event: "load")
            }
        }
    }
    
    /// Load the face capture library with an identity supplied by Ver-ID.identity file in your app's main bundle.
    /// - Since: 1.0.0
    public func load() async throws {
        let identity = try VerIDIdentity(url: nil, password: nil)
        try await self.load(identity: identity)
    }
    
    /// Load the face capture library with an identity supplied by an identity file at the given URL.
    /// - Parameter identityFileURL: Identity file URL
    /// - Since: 1.0.0
    public func load(identityFileURL: URL) async throws {
        let identity = try VerIDIdentity(url: identityFileURL)
        try await self.load(identity: identity)
    }
}

public let version: Version = .init(major: 1, minor: 0, patch: 0)
