//
//  FaceCaptureSessionViewController.swift
//  
//
//  Created by Jakub Dolejs on 30/01/2024.
//

import UIKit
import AVFoundation

class FaceCaptureSessionViewController: UIViewController {
    
    let cameraControl = CameraControl()
    private var captureTask: Task<(),Error>?
    private var cgImageOrientation: CGImagePropertyOrientation = .right
    private var session: FaceCaptureSession
    
    init(session: FaceCaptureSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cgImageOrientation = self.view.window?.windowScene?.interfaceOrientation.cgImageOrientation ?? .right
        self.captureTask = Task {
            var serialNumber: UInt64 = 0
            let startTime = CACurrentMediaTime()
            let stream = try await self.cameraControl.start()
            for await sample in stream {
                var image = try sample.convertToImage()
                let rect = AVMakeRect(aspectRatio: view.bounds.size, insideRect: CGRect(origin: .zero, size: image.size))
                try image.applyOrientation(self.cgImageOrientation)
                image.cropToRect(rect)
                let inputFrame = FaceCaptureSessionImageInput(serialNumber: serialNumber, time: CACurrentMediaTime()-startTime, image: image)
                self.session.addInputFrame(inputFrame)
                serialNumber += 1
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureTask?.cancel()
        self.captureTask = nil
        Task {
            await self.cameraControl.stop()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.view, animation: nil, completion: { context in
            if !context.isCancelled, let orientation = self.view.window?.windowScene?.interfaceOrientation.cgImageOrientation {
                self.cgImageOrientation = orientation
            }
        })
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
