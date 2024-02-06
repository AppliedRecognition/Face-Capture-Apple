//
//  HeadView.swift
//
//
//  Created by Jakub Dolejs on 03/02/2024.
//

import SwiftUI
import Combine
import SceneKit

public struct HeadView: View {
    
    private let scene: SCNScene?
    private var pointOfView: SCNNode? = nil
    private let rendererDelegate = RendererDelegate()
    
    @Binding var angle: EulerAngle<Float>
    @Binding var headColor: UIColor
    
    public init(angle: Binding<EulerAngle<Float>>, headColor: Binding<UIColor>) {
        self._angle = angle
        self._headColor = headColor
        guard #available(iOS 14, *) else {
            self.scene = nil
            return
        }
        guard MDLAsset.canImportFileExtension("obj") else {
            self.scene = nil
            return
        }
        guard let modelURL = Bundle.module.url(forResource: "head1", withExtension: "obj") else {
            self.scene = nil
            return
        }
        self.scene = try? SCNScene(url: modelURL)
        if let headNode = self.scene?.rootNode.childNodes.first {
            headNode.geometry?.materials.forEach { material in
                material.diffuse.contents = self.headColor
            }
            let cameraNode = SCNNode()
            let camera = SCNCamera()
            camera.name = "headCam"
            camera.projectionDirection = .vertical
            camera.fieldOfView = 30
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
            cameraNode.camera = camera
            self.pointOfView = cameraNode
            let lightNode = SCNNode()
            let headConstraint = SCNLookAtConstraint(target: headNode)
            lightNode.constraints = [headConstraint]
            lightNode.light = SCNLight()
            lightNode.light?.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
            self.scene?.rootNode.addChildNode(cameraNode)
            self.scene?.rootNode.addChildNode(lightNode)
        }
    }
    
    public var body: some View {
        if #available(iOS 14, *) {
            GeometryReader { geometryReader in
                SceneView(scene: self.scene, pointOfView: self.pointOfView, delegate: self.rendererDelegate)
                //                .background {
                //                    if #available(iOS 15, *) {
                //                        Color(uiColor: .secondarySystemBackground)
                //                    } else {
                //                        Color(.secondarySystemBackground)
                //                    }
                //                }
                    .clipShape(Ellipse())
                    .onReceive(Just(self.headColor)) { headColour in
                        self.scene?.rootNode.childNodes.first?.geometry?.materials.forEach { material in
                            material.diffuse.contents = self.headColor
                        }
                    }
                    .onReceive(Just(self.angle)) { angle in
                        guard let rootNode = self.scene?.rootNode else {
                            return
                        }
                        guard let headNode = rootNode.childNodes.first else {
                            return
                        }
                        guard let cameraNode = rootNode.childNodes.first(where: { $0.camera?.name == "headCam" }), let camera = cameraNode.camera else {
                            return
                        }
                        if let renderer = rendererDelegate.renderer {
                            let topLeft = renderer.projectPoint(SCNVector3(-headNode.boundingSphere.radius, -headNode.boundingSphere.radius/2, 0))
                            let bottomRight = renderer.projectPoint(SCNVector3(headNode.boundingSphere.radius, headNode.boundingSphere.radius, 0))
                            camera.fieldOfView /= geometryReader.size.height / CGFloat(bottomRight.x - topLeft.x)
                        }
                        let yaw = Float(Measurement(value: Double(angle.yaw), unit: UnitAngle.degrees).converted(to: .radians).value)
                        let pitch = Float(Measurement(value: Double(angle.pitch), unit: UnitAngle.degrees).converted(to: .radians).value)
                        headNode.eulerAngles.x = pitch
                        headNode.eulerAngles.y = yaw
                    }
            }
        } else {
            EmptyView()
        }
    }
}

class RendererDelegate: NSObject, SCNSceneRendererDelegate {
    
    var renderer: SCNSceneRenderer?
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        self.renderer = renderer
    }
}
