# ``FaceCapture/FaceCaptureView``

SwiftUI view that guides a user through a face capture session. 

## Overview

The simplest way to capture faces using this view is to present it in a ``sheet(item:onDismiss:content:)``. Here is how you 
can wire your SwiftUI view:

1. Declare state variables `session` and `result`:

    ```swift
    @State var session: FaceCaptureSession?
    @State var result: FaceCaptureSessionResult?
    ```
2. Add ``sheet(item:onDismiss:content:)`` modifier to your SwiftUI view with its `item` property set to your `session` state 
variable and its closure creating a ``FaceCaptureView``. Bind the view's ``result`` property to your result state variable: 

    ```swift
    .sheet(item: self.$session) { session in
        FaceCaptureView(session: session, result: self.$result)
    }
    ```
3. Create a session in response to user action, for example, tapping a button:

    ```swift
    Button("Start capture") {
        self.session = FaceCaptureSession()
    }
    ```
4. Receive the session result in your `result` state variable.

## Example

Presenting a face capture session in a modal sheet

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

## Topics

### Creating the view

- ``init(session:result:configuration:)``

### Configuring the view

- ``session``
- ``configuration``

### Observing the session

- ``result``
