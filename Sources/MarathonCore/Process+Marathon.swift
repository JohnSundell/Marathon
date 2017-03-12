/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public extension Process {
    internal struct Error: Swift.Error {
        let message: String
        let output: String
    }

    @discardableResult func launchBash(withCommand command: String) throws -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        let outputPipe = Pipe()
        standardOutput = outputPipe

        let errorPipe = Pipe()
        standardError = errorPipe

        launch()
        waitUntilExit()

        let output = outputPipe.output ?? ""

        if let error = errorPipe.output {
            if !error.isEmpty {
                throw Error(message: error, output: output)
            }
        }

        return output
    }
}

private extension Pipe {
    var output: String? {
        let data = fileHandleForReading.readDataToEndOfFile()

        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }

        guard !output.hasSuffix("\n") else {
            let outputLength = output.distance(from: output.startIndex, to: output.endIndex)
            return output.substring(to: output.index(output.startIndex, offsetBy: outputLength - 1))
        }

        return output
    }
}
