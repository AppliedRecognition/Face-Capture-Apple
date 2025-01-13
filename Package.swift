// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaceCapture",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .macCatalyst(.v14), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FaceCapture",
            targets: ["FaceCapture"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/AppliedRecognition/Liveness-Detection-Core-Apple.git", revision: "c8f9cc500e8f62a58b758ab83e559e361662a104"),
        .package(url: "https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple.git", revision: "0debdd8d6f1c04b6b7dfd4161f27911c06b2e174")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FaceCapture", 
            dependencies: [
                .product(
                    name: "LivenessDetection",
                    package: "Liveness-Detection-Core-Apple"
                ),
                .product(
                    name: "VerIDCommonTypes",
                    package: "Ver-ID-Common-Types-Apple"
                )
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [.define("SPM")]
        ),
        .testTarget(
            name: "FaceCaptureTests",
            dependencies: [
                "FaceCapture",
                .product(name: "VerIDCommonTypes", package: "Ver-ID-Common-Types-Apple")
            ],
            resources: [
                .process("Resources")
            ])
    ]
)
