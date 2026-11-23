// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "altcraft_sdk",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "altcraft_sdk", targets: ["altcraft_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/altcraft/ios-sdk", from: "2.0.1")
    ],
    targets: [
        .target(
            name: "altcraft_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AltcraftCore", package: "ios-sdk"),
                .product(name: "AltcraftPush", package: "ios-sdk"),
                .product(name: "AltcraftInApp", package: "ios-sdk"),
                .product(name: "AltcraftTarget", package: "ios-sdk"),
                .product(name: "AltcraftProfile", package: "ios-sdk")
            ],
            path: "Sources/altcraft_sdk"
        )
    ]
)
