/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files
import Require

// MARK: - Error

public enum MarathonFileError {
    case failedToRead(File)
}

extension MarathonFileError: PrintableError {
    public var message: String {
        switch self {
        case .failedToRead(let file):
            return "Failed to read Marathonfile at '\(file.path)'"
        }
    }

    public var hints: [String] {
        switch self {
        case .failedToRead:
            return ["Ensure that the file is formatted according to the documentation at https://github.com/johnsundell/marathon"]
        }
    }
}

// MARK: - Marathonfile

internal struct MarathonFile {
    private typealias Error = MarathonFileError

    private(set) var packageURLs = [URL]()
    private(set) var scriptURLs = [URL]()
    private(set) var scriptInformation: ScriptInformation = [:]

    // MARK: - Init

    init(file: File, separator: String) throws {
        let lines = try perform(file.readAsString().components(separatedBy: .newlines),
                                  orThrow: Error.failedToRead(file))

        for line in lines {
            guard !line.isEmpty else {
                continue
            }
            
            if let url = try? absoluteURL(from: line, file: file) {
                if url.isForScript {
                    scriptURLs.append(url)
                } else {
                    packageURLs.append(url)
                }
            } else if let informationElement = try? ScriptInformation.resolve(from: line, separator: separator) {
                scriptInformation[informationElement.key] = informationElement.value
            } else {
                throw Error.failedToRead(file)
            }
        }
    }

    // MARK: - Private

    private func absoluteURL(from urlString: String, file: File) throws -> URL {
        guard let url = URL(string: urlString) else {
            throw Error.failedToRead(file)
        }

        guard !url.isForRemoteRepository else {
            return url
        }

        guard !urlString.hasPrefix("/") && !urlString.hasPrefix("~") else {
            return url
        }

        let item = try perform(file.sibling(at: url),
                               orThrow: Error.failedToRead(file))

        return URL(string: item.path)!
    }
}

// MARK: - Private utilities

private extension File {
    func sibling(at url: URL) throws -> FileSystem.Item {
        let parent = self.parent.require()

        if url.isForScript {
            return try parent.file(atPath: url.absoluteString)
        } else {
            return try parent.subfolder(atPath: url.absoluteString)
        }
    }
}
