# ``FaceCapture``

Capture faces using your device's camera

## Overview

The face capture library helps users capture faces that are suitable to be used for face recognition.

## Requirements

The library runs on iOS 13 or newer. ``FaceCaptureNavigationView`` and ``FaceCaptureViewController`` require iOS 14 or newer.

## Getting started

### Example 1: Capturing faces

The simplest way to capture faces is to use the static async `captureFaces` method of the ``FaceCapture`` class. The call opens a modal dialog that guides the user to capture their face.

```swift
Task {
    do {
        let faceDetection = try FaceLandmarkDetectionMediaPipe()
        let configuration = FaceCaptureConfiguration(
            settings: FaceCaptureSessionSettings(),
            faceCaptureSessionModuleFactories: FaceCaptureSessionModuleFactories(
                createFaceDetection: { faceDetection },
                createFaceTrackingPlugins: {
                    [DepthLivenessDetection()]
                }
            )
        )
        let result = await FaceCapture.captureFaces(configuration: configuration)
        switch result {
        case .success:
            // Capture succeeded
        case .failure:
            // Capture failed
        case .cancel:
            // Capture cancelled
        }
    } catch {
        // Failed to create face detection
    }
}
```

### Example 2: Integrate face capture in a SwiftUI view layout

1. Add a ``FaceCaptureView`` in your SwiftUI view layout. In the following example the face capture session is presented in 
a modal sheet.

    ```swift
    struct MyView: View {

        @State var session: FaceCaptureSession?
        @State var result: FaceCaptureSessionResult? = nil

        var body: some View {
            Group {
                if let result = self.result {
                    switch result {
                    case .success:
                        Text("Capture succeeded")
                    case .failure:
                        Text("Capture failed")
                    case .cancel:
                        Text("Capture cancelled")
                    }
                    Button("Dismiss") {
                        self.result = nil
                    }
                } else {
                    Button("Start capture") {
                        self.session = FaceCaptureSession()
                    }
                }
            }.sheet(item: self.$session) { session in
                FaceCaptureView(session: session, result: self.$result)
            }
        }
    }
    ```
2. Extract the captured face and image from the session result.

    ```swift
    let result: FaceCaptureSessionResult // result from a face capture session 
    
    switch result {
    case .success(capturedFaces: let capturedFaces, metadata: let metadata):
        // Get the first capture and display its face image
        if var capture = capturedFaces.first, let faceImage = capture.faceImage {
            Image(uiImage: faceImage)
            // The capture face is available in `capture.face`
        }
        // Display the session metadata
        ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { name, value in
            Divider()
            HStack {
                Text(name).font(.headline)
                Spacer()
            }
            HStack {
                Text(value.summary).offset(x: 16)
                Spacer()
            }
        }
    case .failure(capturedFaces: _, metadata: _, error: let error):
        Text("Face capture failed: \(error.localizedDescription)")
    case .cancelled:
        Text("Face capture cancelled")
    }
    ```

## Topics

### Face capture session essentials

- ``FaceCaptureSession``
- ``FaceCaptureSessionSettings``
- ``FaceCaptureSessionResult``
- ``FaceTrackingResult``
- ``FaceCapture``

### Face tracking modules

- ``FaceCaptureSessionModuleFactories``

### Face detection

- ``FaceDetection``
- ``AppleFaceDetection``

### Face tracking plugins

- ``FaceTrackingPluginFactory``
- ``FaceTrackingPlugin``
- ``FaceTrackingPluginResult``
- ``FaceTrackingPluginResultProtocol``

### Face tracking result transformers

- ``FaceTrackingResultTransformerFactory``
- ``FaceTrackingResultTransformer``

### Face capture views

- ``FaceCaptureView``
- ``FaceCaptureNavigationView``
- ``FaceCaptureViewConfiguration``
