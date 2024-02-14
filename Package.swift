// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaceCapture",
    platforms: [.iOS(.v13), .macCatalyst(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FaceCapture",
            targets: ["FaceCapture"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/AppliedRecognition/Liveness-Detection-Apple.git", revision: "fc33cacc6dca2a19c3e0997c6e768cb509be0788"),
        .package(url: "https://github.com/AppliedRecognition/Ver-ID-Licence-Apple.git", revision: "3880349a180c4405fd56973f71a8fa88b753d3d9")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FaceCapture", 
            dependencies: [
                .product(
                    name: "LivenessDetection",
                    package: "Liveness-Detection-Apple"
                ),
                .product(
                    name: "VerIDLicence", 
                    package: "Ver-ID-Licence-Apple"
                )
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FaceCaptureTests",
            dependencies: ["FaceCapture"]),
    ]
)
