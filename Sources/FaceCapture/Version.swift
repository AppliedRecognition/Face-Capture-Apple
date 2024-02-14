//
//  Version.swift
//
//
//  Created by Jakub Dolejs on 12/02/2024.
//

import Foundation

public struct Version {
    
    static let major: Int = 1
    static let minor: Int = 0
    static let patch: Int = 0
    
    static var string: String {
        "\(Self.major).\(Self.minor).\(Self.patch)"
    }
}
