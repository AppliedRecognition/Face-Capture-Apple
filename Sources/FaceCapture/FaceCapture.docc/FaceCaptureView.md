# ``FaceCapture/FaceCaptureView``

SwiftUI view that guides a user through a face capture session. 

## Overview

You can embed this view in your SwiftUI layout. Change the ``isCapturing`` property to start or stop the session. The 
session result is updated in the ``result`` property.

## Example

Presenting a face capture session in a modal sheet

```swift
struct MyView: View {

    @State var isCapturing: Bool = false
    @State var result: FaceCaptureSessionResult? = nil

    var body: some View {
        Group {
            if let result = self.result {
                switch result {
                case .success:
                    Text("Capture succeeded")
                case .failure:
                    Text("Capture failed")
                }
                Button("Dismiss") {
                    self.result = nil
                }
            } else {
                Button("Start capture") {
                    self.isCapturing = true
                }
            }
        }.sheet(isPresented: self.$isCapturing) {
            FaceCaptureView(configuration: .default, isCapturing: self.$isCapturing, result: self.$result)
        }
    }
}
```

## Topics

### Creating the view

- ``init(configuration:isCapturing:result:settings:sessionModuleFactories:)``

### Configuring the view

- ``settings``
- ``sessionModuleFactories``
- ``configuration``

### Observing the session

- ``isCapturing``
- ``result``
