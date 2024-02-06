//
//  HeadView3D.swift
//
//
//  Created by Jakub Dolejs on 05/02/2024.
//

import Foundation
import UIKit
import SceneKit
import SwiftUI

struct HeadView3D: UIViewRepresentable {
    
    @Binding var headColor: UIColor
    @Binding var headAngle: (start: EulerAngle<Float>, end: EulerAngle<Float>)
    
    func makeUIView(context: Context) -> HeadUIView3D {
        let view = HeadUIView3D()
        view.headColor = self.headColor
        view.headAngle = self.headAngle
        return view
    }
    
    func updateUIView(_ uiView: HeadUIView3D, context: Context) {
        uiView.headColor = self.headColor
        uiView.headAngle = self.headAngle
    }
}

public class HeadUIView3D: SCNView {
    
    public var headColor: UIColor = .gray {
        didSet {
            self.headNode.geometry?.materials.forEach { material in
                material.diffuse.contents = self.headColor
            }
        }
    }
    
    var isAnimating: Bool = false
    
    public var headAngle: (start: EulerAngle<Float>, end: EulerAngle<Float>) = (start: .init(), end: .init()) {
        didSet {
            self.camera.fieldOfView = CGFloat(atan2(self.headNode.boundingSphere.radius*1.7, self.cameraNode.position.z) / .pi * 180)
            if self.isAnimating {
                return
            }
            let startPitch = self.headAngle.start.pitch / 180 * .pi
            let startYaw = self.headAngle.start.yaw / 180 * .pi
            let endPitch = self.headAngle.end.pitch / 180 * .pi
            let endYaw = self.headAngle.end.yaw / 180 * .pi
            
            let yawAnimation = CABasicAnimation(keyPath: "eulerAngles.y")
            yawAnimation.fromValue = startYaw
            yawAnimation.toValue = endYaw
            let pitchAnimation = CABasicAnimation(keyPath: "eulerAngles.x")
            pitchAnimation.fromValue = startPitch
            pitchAnimation.toValue = endPitch
            let animation = CAAnimationGroup()
            animation.delegate = self
            animation.duration = 1.0
            animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
            animation.animations = [yawAnimation, pitchAnimation]
            self.headNode.removeAnimation(forKey: "rotation")
            self.headNode.addAnimation(animation, forKey: "rotation")
                
                
//                self.headNode.eulerAngles.x = self.headAngle.start.pitch / 180 * .pi
//                self.headNode.eulerAngles.y = self.headAngle.start.yaw / 180 * .pi
//                UIView.animate(withDuration: 1.5) {
//                    self.headNode.eulerAngles.x = endPitch
//                    self.headNode.eulerAngles.y = endYaw
//                } completion: { completed in
//                    self.isAnimating = false
//                }
//            NSLog("Head angle set to: yaw %.0f, pitch %.0f", self.headAngle.yaw, self.headAngle.pitch)
        }
    }
    
    private var headNode: SCNNode!
    private var cameraNode: SCNNode!
    private var camera: SCNCamera!
    
    public override init(frame: CGRect) {
        super.init(frame: frame, options: nil)
        self.setup()
    }
    
    public convenience init() {
        self.init(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    private func setup() {
        self.backgroundColor = .secondarySystemBackground
        guard MDLAsset.canImportFileExtension("obj") else {
            return
        }
        guard let modelURL = Bundle.module.url(forResource: "head1", withExtension: "obj") else {
            return
        }
        self.scene = try? SCNScene(url: modelURL)
        
        self.headNode = self.scene!.rootNode.childNodes.first!
        self.headNode.geometry?.materials.forEach { material in
            material.diffuse.contents = self.headColor
        }
        self.cameraNode = SCNNode()
        self.camera = SCNCamera()
        self.camera.name = "headCam"
        self.camera.projectionDirection = .vertical
        self.camera.fieldOfView = 30
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        self.cameraNode.camera = self.camera
        self.pointOfView = self.cameraNode
        let lightNode = SCNNode()
        let headConstraint = SCNLookAtConstraint(target: self.headNode)
        lightNode.constraints = [headConstraint]
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        self.scene?.rootNode.addChildNode(self.cameraNode)
        self.scene?.rootNode.addChildNode(lightNode)
    }
}

extension HeadUIView3D: CAAnimationDelegate {
    
    public func animationDidStart(_ anim: CAAnimation) {
        self.isAnimating = true
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.isAnimating = false
    }
}
