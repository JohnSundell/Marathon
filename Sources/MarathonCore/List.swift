/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

internal final class ListTask: Task, Executable {
    func execute() throws -> String {
        let packages = packageManager.addedPackages
        let scriptPaths = scriptManager.managedScriptPaths

        var output = ""

        if !packages.isEmpty {
            let title = "📦  Packages"
            output.append(title + "\n" + title.dashesWithMatchingLength + "\n")

            for package in packageManager.addedPackages {
                output.append("\(package.name) (\(package.url))\n")
            }

            output.append("\n")
        }

        if !scriptPaths.isEmpty {
            let title = "📄  Scripts"
            output.append(title + "\n" + title.dashesWithMatchingLength + "\n")

            for path in scriptPaths {
                output.append("\(path)\n")
            }

            output.append("\n")
        }

        output.append("👉  To remove either a package or the cached data for a script, use 'marathon remove'")

        return output
    }
}
