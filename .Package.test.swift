//
//  .Package.test.swift
//  Marathon
//
//  Created by pixyzehn on 2017/04/09.
//
//

import PackageDescription

let package = Package(
    name: "Marathon",
    // TODO: Once the `test` command has been implemented in the Swift Package Manager, this should be changed to
    // be `testDependencies:` instead. For now it has to be done like this for the library to get linked with the test targets.
    // See: https://github.com/apple/swift-evolution/blob/master/proposals/0019-package-manager-testing.md
    targets: [
        Target(name: "Marathon", dependencies: ["MarathonCore"]),
        Target(name: "MarathonCore")
    ],
    dependencies: [
        .Package(url: "https://github.com/johnsundell/files.git", majorVersion: 1),
        .Package(url: "https://github.com/johnsundell/unbox.git", majorVersion: 2),
        .Package(url: "https://github.com/johnsundell/wrap.git", majorVersion: 2),
        .Package(url: "https://github.com/johnsundell/shellout.git", majorVersion: 1),
        .Package(url: "https://github.com/johnsundell/require.git", majorVersion: 1),
        .Package(url: "https://github.com/JohnSundell/Assert.git", majorVersion: 1)
    ]
)
