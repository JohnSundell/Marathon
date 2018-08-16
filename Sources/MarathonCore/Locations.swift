//
//  Locations.swift
//  MarathonCore
//
//  Created by Robert Nash on 29/07/2018.
//

import Foundation
import Files

enum Locations {
    case autocompletions
    case scripts
    case packages
    func folder(rootPath path: String) throws -> Folder {
        let rootFolder = try FileSystem().createFolderIfNeeded(at: path)
        switch self {
        case .autocompletions:
            return try rootFolder.createSubfolderIfNeeded(withName: "ShellAutocomplete")
        case .scripts:
            return try rootFolder.createSubfolderIfNeeded(withName: "Scripts")
        case .packages:
            return try rootFolder.createSubfolderIfNeeded(withName: "Packages")
        }
    }
}
