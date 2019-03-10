// swift-tools-version:4.2

/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "Marathon",
    products: [
        .executable(name: "Marathon", targets: ["Marathon"]),
        .library(name: "MarathonCore", targets: ["MarathonCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Require.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Releases.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "Marathon",
            dependencies: ["MarathonCore"]
        ),
        .target(
            name: "MarathonCore",
            dependencies: ["Files", "ShellOut", "Require", "Releases"]
        ),
        .testTarget(
            name: "MarathonTests",
            dependencies: ["MarathonCore"]
        )
    ]
)
