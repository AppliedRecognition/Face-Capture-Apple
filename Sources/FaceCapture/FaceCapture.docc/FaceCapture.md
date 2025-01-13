# ``FaceCapture``

Capture faces using your device's camera

## Overview

The face capture library helps users capture faces that are suitable to be used for face recognition.

## Requirements

The library runs on iOS 13 or newer. ``FaceCaptureNavigationView`` and ``FaceCaptureViewController`` require iOS 14 or newer.

## Getting started

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
