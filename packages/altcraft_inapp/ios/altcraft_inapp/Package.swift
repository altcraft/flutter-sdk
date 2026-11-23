// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "altcraft_inapp",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "altcraft-inapp", targets: ["altcraft_inapp"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/altcraft/ios-sdk", from: "2.0.1")
    ],
    targets: [
        .target(
            name: "altcraft_inapp",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AltcraftCore", package: "ios-sdk"),
                .product(name: "AltcraftInApp", package: "ios-sdk")
            ],
            path: "Sources/altcraft_inapp"
        )
    ]
)
