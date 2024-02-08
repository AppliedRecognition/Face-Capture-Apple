//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 23/10/2023.
//

import Foundation

public protocol FaceDetection: AnyObject {
    
    func detectFacesInImage(_ image: Image, limit: Int) throws -> [Face]
}
