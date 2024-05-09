# ``FaceCapture``

Capture faces using your device's camera

## Overview

The face capture library helps users capture faces that are suitable to be used for face recognition.

## Requirements

The library runs on iOS 13 or newer. ``FaceCaptureNavigationView`` and ``FaceCaptureViewController`` require iOS 14 or newer.

## Getting started

1. Obtain a Ver-ID identity for your app on the [Ver-ID licensing website](https://licensing.ver-id.com). Your app's bundle 
identifier must match the identifier on the licence.
2. Copy the Ver-ID.identity file to your app's main bundle.
3. Load the library. For example, you can do this in one of your app view's' `task` modifier.

    ```swift
    import SwiftUI
    import FaceCapture

    @main
    struct MyApp: App {

        @State var error: Error?
        @StateObject var faceCapture: FaceCapture = .default

        var body: some Scene {
            WindowGroup {
                if self.faceCapture.isLoaded {
                    MyView()
                } else if let error = self.error {
                    Text("Failed to load face capture: \(error.localizedDescription)")
                } else {
                    ProgressView("Loading")
                        .task {
                            do {
                                try await self.faceCapture.load()
                            } catch {
                                self.error = error
                            }
                        }
                }
            }
        }
    }
    ```
4. Add a ``FaceCaptureView`` in your SwiftUI view layout. In the following example the face capture session is presented in 
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
5. Extract the captured face and image from the session result.

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

### Loading the library

- ``FaceCapture/FaceCapture``

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
