# Face Capture for iOS

This library captures images (and depth data if available) from an iOS device and detects faces that can be used for face recognition.

## Requirements

The face capture runs on iOS 13 or newer. iOS 14 is the recommended minimum version that includes all features.

## Installation

Please [contact Applied Recognition](mailto:support@appliedrecognition.com) to obtain credentials to access the package manager repositories.

### Swift Package Manager

- Open Xcode
- Select your project in the Project Navigator
- Click on the Package Dependencies tab
- Click the + button to add a dependency
- In the search bar enter `https://github.com/AppliedRecognition/Face-Capture-Apple.git`
- Click the Add Package button

### CocoaPods

- Open your Podfile in a text editor
- At the top of the file add `source 'https://github.com/AppliedRecognition/Ver-ID-CocoaPods-Repo.git'`
- Unless it's already present, add `source 'https://github.com/CocoaPods/Specs.git'` below the previous source declaration.
- In your target specification add `pod 'Face-Capture', '~> 1.1.1'`
- Save your Podfile
- In terminal, run the command `pod install`

## Usage

### Session configuration

#### Session settings

Construct an instance of the FaceCaptureSessionSettings struct.

```swift
var settings = FaceCaptureSessionSettings()

// Optional: Set face capture count (default = 1).
// The face capture count determines how many faces will be collected during the session.
// Setting the count to a value greater than 1 enables the session's active liveness check. 
// During active liveness check the user is asked to turn their head in random directions.
settings.faceCaptureCount = 2

// Optional: Set the session maximum duration. This setting determines how long the session will
// run before timing out. The default duration is 30 seconds.
settings.maxDuration = 60

// Optional: Set the countdown duration. The session view displays a countdown before the session
// starts. This gives the user time to prepare for the face capture. Setting the count to 0
// disables the countdown.
settings.countdownSeconds = 0
```

#### Configure face detection

Create an instance of a class that implements the [FaceDetection](https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple/blob/main/Sources/VerIDCommonTypes/FaceDetection.swift) protocol. The library comes with [AppleFaceDetection](https://github.com/AppliedRecognition/Face-Capture-Apple/blob/main/Sources/FaceCapture/AppleFaceDetection.swift), which uses face detection that's part of the CocoaTouch SDK and is available on all Apple devices. We recommend [MediaPipe face detection](https://github.com/AppliedRecognition/Face-Detection-MediaPipe-Apple) package for best performance and accurate face angle estimates. To add it to your Podfile use `pod 'FaceDetectionMediaPipe', '~> 1.0.0'`.

**Choose from one of the following:**

- Apple face detection (comes with the FaceCapture library):

    ```swift
    let faceDetection = AppleFaceDetection()
    ```
- MediaPipe face detector:

    ```swift
    import FaceDetectionMediaPipe
    
    let faceDetection = try FaceDetectionMediaPipe()
    ```

- MediaPipe face landmark detector:

    ```swift
    import FaceDetectionMediaPipe
    
    let faceDetection = try FaceLandmarkDetectionMediaPipe()
    ```

#### Configure face tracking plugins

Face tracking plugins asynchronously consume the face tracking results. Plugins can be used to perform auxiliary tasks related to the session, for example, liveness detection or session diagnostics.

The FaceCapture SDK comes with [DepthLivenessDetection](https://github.com/AppliedRecognition/Face-Capture-Apple/blob/main/Sources/FaceCapture/DepthLivenessDetection.swift), which uses depth data from the TrueDepth sensor available on devices with Apple's Face ID. To see if the device supports depth data capture use:

```swift
let cameraPosition: AVCaptureDevice.Position = .front // Front-facing (selfie) camera
if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
    // Can use depth-based liveness detection
} else {
    // Depth-based liveness detection unavailable
}
```

If depth-based liveness detection isn't available you can use Ver-ID's machine-learning liveness detection model. Add it to your application by including `pod 'SpoofDeviceDetection/Model', '~> 1.0'` in your Podfile.

Here is how you can choose between depth-based and ML-model liveness detection:

```swift
import SpoofDeviceDetection

let cameraPosition: AVCaptureDevice.Position = .front
var plugins: [any FaceTrackingPlugin] = []
if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
    plugins.append(DepthLivenessDetection())
} else if let spoofDeviceDetector = try? SpoofDeviceDetector(), let livenessDetection = try? LivenessDetectionPlugin(spoofDetectors: [spoofDeviceDetector]) {
    plugins.append(livenessDetection)
}

```

#### Face capture session module factories

The `FaceCaptureSessionModuleFactories` struct encapsulates the face detection and face tracking plugin configuration.

```swift
var faceCaptureSessionModuleFactories = FaceCaptureSessionModuleFactories(
    createFaceDetection: {
        faceDetection
    },
    createFaceTrackingPlugins: {
        plugins
    }
)
```

#### Putting it all together – creating a session

```swift
import FaceCapture
import FaceDetectionMediaPipe
import SpoofDeviceDetection

func createFaceCaptureSession() throws -> FaceCaptureSession {
    let cameraPosition: AVCaptureDevice.Position = .front // Front-facing (selfie) camera
    let settings = FaceCaptureSessionSettings()
    let faceDetection = try FaceDetectionMediaPipe()
    var plugins: [any FaceTrackingPlugin] = []
    if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
        plugins.append(DepthLivenessDetection())
    } else {
        let spoofDeviceDetector = try SpoofDeviceDetector()
        let livenessDetection = try LivenessDetectionPlugin(spoofDetectors: [spoofDeviceDetector])
        plugins.append(livenessDetection)
    }
    let faceCaptureSessionModuleFactories = FaceCaptureSessionModuleFactories(
        createFaceDetection: {
            faceDetection
        },
        createFaceTrackingPlugins: {
            plugins
        }
    )
    return FaceCaptureSession(
        settings: settings, 
        sessionModuleFactories: faceCaptureSessionModuleFactories
    )
}
```

### Presenting the session view

The FaceCapture library uses SwiftUI to render its user interface. The easiest way to add the face capture capability to your app is to present a modal sheet.

```swift
import SwiftUI

struct MySessionView: View {
    
    @State var session: FaceCaptureSession?
    @State var result: FaceCaptureSessionResult? = nil
    
    var body: some View {
        Group {
            if let sessionResult = self.result {
                // Session result is available
                switch result {
                case .success(capturedFaces: let capturedFaces):
                    // Display the captured face
                    if var capture = capturedFaces.first, let faceImage = capture.faceImage {
                        Image(uiImage: faceImage)
                    }
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
                // Session result is not available, display a "Start capture" button
                Button("Start capture") {
                    do {
                        // Create the session (see previous section)
                        self.session = try createFaceCaptureSession()
                    } catch {
                        // Set result to failure if session creation fails
                        self.result = .failure(capturedFaces: [], metadata: [:], error: error)
                    }
                }
            }
        }.sheet(item: self.$session) { session in
            // Display a face capture view if session is not nil
            FaceCaptureView(session: session, result: self.$result)
        }
    }
}
```

## Demo app

The project contains a [demo app](https://github.com/AppliedRecognition/Face-Capture-Apple/tree/main/Face%20Capture%20Demo) that shows the above concepts in the context of a mobile app.

The app shows how to present the session view as a modal sheet, embedded in another view or pushed in a navigation stack.

### Demo app setup

1. Navigate to the [Face Capture Demo](https://github.com/AppliedRecognition/Face-Capture-Apple/tree/main/Face%20Capture%20Demo) directory.
2. Run `pod install` to install the app's dependencies.
3. Run the app from Xcode.

## API documentation

Full API documentation is available on [this GitHub page](https://appliedrecognition.github.io/Face-Capture-Apple/documentation/facecapture).
