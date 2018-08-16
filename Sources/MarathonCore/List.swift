/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

final class ListTask: Task, Executable {
    
    func execute() throws {
        
        let scriptManager = try ScriptManager.assemble(with: rootPath, using: output)
        
        let packages = scriptManager.addedPackages
        let scriptPaths = scriptManager.managedScriptPaths

        var feedback = ""
        var listIsEmpty = true

        if !packages.isEmpty {
            let title = "📦  Packages"
            feedback.append(title + "\n" + title.dashesWithMatchingLength + "\n")

            for package in packages {
                feedback.append("\(package.name) (\(package.url.absoluteString))\n")
            }

            feedback.append("\n")
            listIsEmpty = false
        }

        if !scriptPaths.isEmpty {
            let title = "📄  Scripts"
            feedback.append(title + "\n" + title.dashesWithMatchingLength + "\n")

            for path in scriptPaths {
                feedback.append("\(path)\n")
            }

            feedback.append("\n")
            listIsEmpty = false
        }

        if listIsEmpty {
            feedback.append("ℹ️  No packages or script data has been added to Marathon yet")
        } else {
            feedback.append("👉  To remove either a package or the cached data for a script, use 'marathon remove'")
        }

        output.conclusion(feedback)
    }
}
