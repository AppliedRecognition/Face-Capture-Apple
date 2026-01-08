# Face Capture for iOS

This library captures images (and depth data if available) from an iOS device and detects faces that can be used for face recognition.

## Requirements

The face capture runs on iOS 15 or newer.

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
- In your target specification add `pod 'Face-Capture'`
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

Create an instance of a class that implements the [FaceDetection](https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple/blob/main/Sources/VerIDCommonTypes/FaceDetection.swift) protocol. The library comes with [AppleFaceDetection](https://github.com/AppliedRecognition/Face-Capture-Apple/blob/main/Sources/FaceCapture/AppleFaceDetection.swift), which uses face detection that's part of the CocoaTouch SDK and is available on all Apple devices. We recommend [RetinaFace face detection](https://github.com/AppliedRecognition/Face-Detection-RetinaFace-Apple) for best performance and accurate face angle estimates.

**Choose from one of the following:**

- Apple face detection (comes with the FaceCapture library):

    ```swift
    let faceDetection = AppleFaceDetection()
    ```
- RetinaFace face detector:

    ```swift
    import FaceDetectionRetinaFace
    
    let faceDetection = try FaceDetectionRetinaFace()
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

If depth-based liveness detection isn't available you can use Ver-ID's [machine-learning liveness detection](https://github.com/AppliedRecognition/Spoof-Device-Detection-Ver-ID-3-Apple).

Here is how you can choose between depth-based and ML-model liveness detection:

```swift
import SpoofDeviceDetection

let cameraPosition: AVCaptureDevice.Position = .front
var plugins: [any FaceTrackingPlugin] = []
if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
    plugins.append(DepthLivenessDetection())
} else {
    let spoofDeviceDetection = SpoofDeviceDetection(apiKey: "your API key", url: URL(string: "server URL")!)
    if let livenessDetection = try? LivenessDetectionPlugin(spoofDetectors: [spoofDeviceDetection]) {
        plugins.append(livenessDetection)
    }
}

```

#### Putting it all together – creating a session

```swift
import FaceCapture
import FaceDetectionRetinaFace
import SpoofDeviceDetection

func createFaceCaptureSession(useBackCamera: Bool) throws -> FaceCaptureSession {
    let cameraPosition: AVCaptureDevice.Position = useBackCamera ? .back : .front
    let settings = FaceCaptureSessionSettings()
    let faceDetection = try FaceDetectionRetinaFace()
    let cameraPosition: AVCaptureDevice.Position = .front
    var plugins: [any FaceTrackingPlugin] = []
    if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
        plugins.append(DepthLivenessDetection())
    } else {
        let spoofDeviceDetection = SpoofDeviceDetection(apiKey: "your API key", url: URL(string: "server URL")!)
        let livenessDetection = try LivenessDetectionPlugin(spoofDetectors: [spoofDeviceDetection])
        plugins.append(livenessDetection)
    }
    return FaceCaptureSession(
        settings: settings, 
        faceDetection: faceDetection,
        faceTrackingPlugins: plugins
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

## API documentation

Full API documentation is available on [this GitHub page](https://appliedrecognition.github.io/Face-Capture-Apple/documentation/facecapture).
