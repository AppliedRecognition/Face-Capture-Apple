# ``FaceCapture/FaceCaptureSession``

## Essentials 

Face capture session is the main building block of the face capture library. When a ``FaceCaptureSession`` is created it 
starts expecting input. Image input is supplied to the session via ``submitImageInput(_:)``. When the session terminates it 
changes the value of its ``result`` property. The possible results are:

- ``FaceCaptureSessionResult/success(capturedFaces:metadata:)``: the session succeeded,
- ``FaceCaptureSessionResult/failure(capturedFaces:metadata:error:)``: the session failed,
- ``FaceCaptureSessionResult/cancelled``: the session was cancelled by the user.

>Important: Before starting a session you should load the face capture library using one of the 
``FaceCapture/FaceCapture/load()`` methods. Otherwise the session will attempt to load the library using a Ver-ID.identity 
file in your app's main bundle. 

## Session modules

Each session has three categories of modules that alter the way it behaves:

1. [`FaceDetection`](https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple/blob/main/Sources/VerIDCommonTypes/FaceDetection.swift) detects faces in the images supplied to the session.
2. ``FaceTrackingPlugin`` processes images with the face tracked by [`FaceDetection`](https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple/blob/main/Sources/VerIDCommonTypes/FaceDetection.swift) at a pace independent from the session
output. Face tracking results that the plugin cannot process in time are dropped from the plugin queue. Face tracking 
plugins are useful if you need to evaluate the session output independently, for example, in passive liveness detection.
3. ``FaceTrackingResultTransformer`` transforms each ``FaceTrackingResult`` before its displayed by the session view. For 
example, say you want to pick the best quality face from a number of face tracking results. You can save a buffer of results 
and when the buffer is full set the status of the best result to ``FaceTrackingResult/faceCaptured(_:)``. Bear in mind that 
transformer work synchronously. If your transformer takes a long time to process the face tracking result the session preview 
frame rate will suffer.

The face capture library comes with a number of useful session modules. To supply your own session modules pass an instance 
of ``FaceCaptureSessionModuleFactories`` to the session constructor.

## Topics

### Creating a session

- ``FaceCaptureSession/init(settings:sessionModuleFactories:)``
- ``FaceCaptureSessionSettings``
- ``FaceCaptureSessionModuleFactories``

### Submitting session input

- ``submitImageInput(_:)``

### Observing session results

- ``result``

### Observing face tracking results

- ``faceTrackingResult``

### Cancelling the session

- ``cancel()``
