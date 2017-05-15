/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "Marathon",
    targets: [
        Target(name: "Marathon", dependencies: ["MarathonCore"]),
        Target(name: "MarathonCore")
    ],
    dependencies: [
        .Package(url: "https://github.com/JohnSundell/Files.git", majorVersion: 1),
        .Package(url: "https://github.com/JohnSundell/Unbox.git", majorVersion: 2),
        .Package(url: "https://github.com/JohnSundell/Wrap.git", majorVersion: 2),
        .Package(url: "https://github.com/JohnSundell/ShellOut.git", majorVersion: 1),
        .Package(url: "https://github.com/JohnSundell/Require.git", majorVersion: 1),
        .Package(url: "https://github.com/JohnSundell/Releases.git", majorVersion: 1)
    ]
)
