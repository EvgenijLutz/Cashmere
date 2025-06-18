// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cashmere",
    platforms: [
        .macOS(.v13),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Cashmere",
            targets: ["Cashmere"]),
    ],
    targets: [
        .target(name: "CMPlatform"),
        .target(
            name: "Cashmere",
            dependencies: [
                .target(name: "CMPlatform")
            ]
        )
    ]
)
