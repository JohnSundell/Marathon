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
        .Package(url: "git@github.com:johnsundell/files.git", majorVersion: 1),
        .Package(url: "git@github.com:johnsundell/unbox.git", majorVersion: 2),
        .Package(url: "git@github.com:johnsundell/wrap.git", majorVersion: 2),
        .Package(url: "git@github.com:johnsundell/shellout.git", majorVersion: 1),
        .Package(url: "git@github.com:johnsundell/require.git", majorVersion: 1),
        .Package(url: "git@github.com:johnsundell/releases.git", majorVersion: 1)
    ]
)
