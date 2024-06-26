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
        .package(url: "https://github.com/AppliedRecognition/Ver-ID-Licence-Apple.git", revision: "3880349a180c4405fd56973f71a8fa88b753d3d9"),
        .package(url: "https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple.git", revision: "74b77e3dea2d19f4f22b27b7437c40c38852bdbf")
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
                    name: "VerIDLicence", 
                    package: "Ver-ID-Licence-Apple"
                ),
                .product(
                    name: "VerIDCommonTypes",
                    package: "Ver-ID-Common-Types-Apple"
                )
            ],
            resources: [
                .process("Resources")
            ]
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
