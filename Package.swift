// swift-tools-version:4.1

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
        .package(url: "https://github.com/JohnSundell/Unbox.git", from: "3.0.0"),
        .package(url: "https://github.com/JohnSundell/Wrap.git", from: "3.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Require.git", from: "2.0.0"),
        .package(url: "https://github.com/JohnSundell/Releases.git", from: "3.0.0"),
        .package(url: "https://github.com/alexito4/ImportSpecification", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "Marathon",
            dependencies: ["MarathonCore"]
        ),
        .target(
            name: "MarathonCore",
            dependencies: ["Files", "Unbox", "Wrap", "ShellOut", "Require", "Releases", "ImportSpecification"]
        ),
        .testTarget(
            name: "MarathonTests",
            dependencies: ["MarathonCore"]
        )
    ]
)
