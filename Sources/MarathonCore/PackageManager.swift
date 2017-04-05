/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files
import Wrap
import Unbox
import ShellOut

// MARK: - Error

public enum PackageManagerError {
    case failedToResolveLatestVersion(URL)
    case failedToResolveName(URL)
    case packageAlreadyAdded(String)
    case failedToSavePackageFile(String, Folder)
    case failedToReadPackageFile(String)
    case failedToUpdatePackages(Folder)
    case unknownPackageForRemoval(String)
    case failedToRemovePackage(String, Folder)
}

extension PackageManagerError: PrintableError {
    public var message: String {
        switch self {
        case .failedToResolveLatestVersion(let url):
            return "Could not resolve the latest version for package at '\(url)'"
        case .failedToResolveName(let url):
            return "Could not resolve the name of package at '\(url)'"
        case .packageAlreadyAdded(let name):
            return "A package named '\(name)' has already been added"
        case .failedToSavePackageFile(let name, _):
            return "Could not save file for package '\(name)'"
        case .failedToReadPackageFile(let name):
            return "Could not read file for package '\(name)'"
        case .failedToUpdatePackages(_):
            return "Failed to update packages"
        case .unknownPackageForRemoval(let name):
            return "Cannot remove package '\(name)' - no such package has been added"
        case .failedToRemovePackage(let name, _):
            return "Could not remove package '\(name)'"
        }
    }

    public var hints: [String] {
        switch self {
        case .failedToResolveLatestVersion(let url):
            var hint = "Make sure that the package you're trying to add is reachable, and has at least one tagged release"

            if !url.isForRemoteRepository {
                hint += "\nYou can make a release by using 'git tag <version>' in your package's repository"
            }

            return [hint]
        case .failedToResolveName(_):
            return ["Make sure that the package you're trying to add is reachable, and has a Package.swift file"]
        case .packageAlreadyAdded(let name):
            return ["Did you mean to update it? If so, run 'marathon update'\n" +
                   "You can also remove the existing package using 'marathon remove \(name)', and then run 'add' again"]
        case .failedToSavePackageFile(_, let folder):
            return ["Make sure you have write permissions to the folder '\(folder.path)'"]
        case .failedToReadPackageFile(let name):
            return ["The file may have become corrupted. Try removing the package using 'marathon remove \(name)' and then add it back again"]
        case .failedToUpdatePackages(let folder):
            return ["Make sure you have write permissions to the folder '\(folder.path)'"]
        case .unknownPackageForRemoval(_):
            return ["Did you mean to remove the cache data for a script? If so, add '.swift' to its path\n" +
                   "To list all added packages run 'marathon list'"]
        case .failedToRemovePackage(_, let folder):
            return ["Make sure you have write permissions to the folder '\(folder.path)'"]
        }
    }
}

// MARK: - PackageManager

internal final class PackageManager {
    private typealias Error = PackageManagerError

    var addedPackages: [Package] { return makePackageList() }

    private let folder: Folder
    private let generatedFolder: Folder
    private let temporaryFolder: Folder
    private let print: Printer
    private var masterPackageName: String { return "MARATHON_PACKAGES" }

    // MARK: - Init

    init(folder: Folder, printer: @escaping Printer) throws {
        self.folder = folder
        self.generatedFolder = try folder.createSubfolderIfNeeded(withName: "Generated")
        self.temporaryFolder = try folder.createSubfolderIfNeeded(withName: "Temp")
        self.print = printer
    }

    // MARK: - API

    @discardableResult func addPackage(at url: URL, throwIfAlreadyAdded: Bool = true) throws -> Package {
        let name = try nameOfPackage(at: url)

        if throwIfAlreadyAdded {
            guard (try? folder.file(named: name)) == nil else {
                throw Error.packageAlreadyAdded(name)
            }
        }

        let latestVersion = try latestMajorVersionForPackage(at: url)
        let package = Package(name: name, url: absoluteRepositoryURL(from: url), majorVersion: latestVersion)
        try save(package: package)
        try updatePackages()
        return package
    }

    func addPackages(fromMarathonFile file: MarathonFile) throws {
        let existingPackageURLs = Set(makePackageList().map { package in
            return package.url
        })

        for url in file.packageURLs {
            guard !existingPackageURLs.contains(url) else {
                continue
            }

            try addPackage(at: url, throwIfAlreadyAdded: false)
        }
    }

    @discardableResult func removePackage(named name: String, shouldUpdatePackages: Bool = true) throws -> Package {
        print("Removing \(name)...")

        let packageFile = try perform(folder.file(named: name),
                                      orThrow: Error.unknownPackageForRemoval(name))

        let package = try perform(unbox(data: packageFile.read()) as Package,
                                  orThrow: Error.failedToReadPackageFile(name))

        try perform(packageFile.delete(), orThrow: Error.failedToRemovePackage(name, folder))

        if shouldUpdatePackages {
            try updatePackages()
        }

        return package
    }

    func removeAllPackages() throws {
        for package in addedPackages {
            try removePackage(named: package.name)
        }

        try updatePackages()
    }

    func makePackageDescription(for script: Script) throws -> String {
        guard let masterDescription = try? generatedFolder.file(named: "Package.swift").readAsString() else {
            try updatePackages()
            return try makePackageDescription(for: script)
        }

        return masterDescription.replacingOccurrences(of: masterPackageName, with: script.name)
    }

    func symlinkPackages(to folder: Folder) throws {
        guard let packagesFolder = try? generatedFolder.subfolder(atPath: ".build/checkouts") else {
            try updatePackages()
            return try symlinkPackages(to: folder)
        }

        guard (try? folder.subfolder(atPath: ".build/checkouts")) == nil else {
            return
        }

        let buildFolder = try folder.createSubfolderIfNeeded(withName: ".build")
        try buildFolder.createSymlink(to: packagesFolder.path, at: "checkouts")
    }

    func updateAllPackagesToLatestMajorVersion() throws {
        for var package in addedPackages {
            let latestMajorVersion = try latestMajorVersionForPackage(at: package.url)

            guard latestMajorVersion > package.majorVersion else {
                continue
            }

            package.majorVersion = latestMajorVersion
            try save(package: package)
        }

        try updatePackages()
    }

    // MARK: - Private

    private func latestMajorVersionForPackage(at url: URL) throws -> Int {
        let command: String

        if url.isForRemoteRepository {
            command = "git ls-remote --tags \(url.absoluteString)"
        } else {
            command = "cd \(url.absoluteString) && git tag"
        }

        let error = Error.failedToResolveLatestVersion(url)
        let commandOutput = try perform(shellOut(to: command), orThrow: error)
        let ignoredVersionTerms = ["alpha", "a", "beta", "b", "pre", "prerelease"]
        var latestVersion: Int?

        try commandOutput.components(separatedBy: "\n").forEach { line in
            guard let versionString = line.components(separatedBy: "refs/tags/").last else {
                throw error
            }

            for term in ignoredVersionTerms {
                if versionString.lowercased().contains(term) {
                    return
                }
            }

            guard let majorVersionString = versionString.components(separatedBy: ".").first else {
                throw error
            }

            guard let majorVersion = majorVersion(from: majorVersionString) else {
                throw error
            }

            if let currentLatestVersion = latestVersion {
                if majorVersion > currentLatestVersion {
                    latestVersion = majorVersion
                }
            } else {
                latestVersion = majorVersion
            }
        }

        guard let version = latestVersion else {
            throw error
        }

        return version
    }

    private func nameOfPackage(at url: URL) throws -> String {
        do {
            if url.isForRemoteRepository {
                return try nameOfRemotePackage(at: url)
            }
            
            let folder = try Folder(path: url.absoluteString)
            return try nameOfPackage(in: folder)
        } catch {
            throw Error.failedToResolveName(url)
        }
    }

    private func nameOfPackage(in folder: Folder) throws -> String {
        let packageFile = try folder.file(named: "Package.swift")
        var packageDescription = try packageFile.readAsString()

        guard let nameStartRange = packageDescription.range(of: "name:") else {
            throw Error.failedToReadPackageFile(packageFile.nameExcludingExtension)
        }

        packageDescription = packageDescription.substring(from: nameStartRange.upperBound)

        guard let delimiterRange = packageDescription.range(of: ",") ?? packageDescription.range(of: ")") else {
            throw Error.failedToReadPackageFile(packageFile.nameExcludingExtension)
        }

        packageDescription = packageDescription.substring(to: delimiterRange.lowerBound)
        packageDescription = packageDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return packageDescription.replacingOccurrences(of: "\"", with: "")
    }

    private func nameOfRemotePackage(at url: URL) throws -> String {
        if let existingClone = try? temporaryFolder.subfolder(named: "Clone") {
            try existingClone.delete()
        }

        print("Cloning \(url.absoluteString)...")

        try temporaryFolder.moveToAndPerform(command: "git clone \(url.absoluteString) Clone -q")
        let clone = try temporaryFolder.subfolder(named: "Clone")
        let name = try nameOfPackage(in: clone)
        try clone.delete()

        return name
    }

    private func majorVersion(from string: String) -> Int? {
        guard var firstComponent = string.components(separatedBy: ".").first else {
            return nil
        }

        var number = Int(firstComponent)

        while number == nil && firstComponent.characters.count > 0 {
            firstComponent.remove(at: firstComponent.startIndex)
            number = Int(firstComponent)
        }

        return number
    }

    private func absoluteRepositoryURL(from url: URL) -> URL {
        guard !url.isForRemoteRepository else {
            return url
        }

        let path = try! Folder(path: url.absoluteString).path
        return URL(string: path)!
    }

    private func save(package: Package) throws {
        try perform(folder.createFile(named: package.name, contents: wrap(package)),
                    orThrow: Error.failedToSavePackageFile(package.name, folder))
    }

    private func updatePackages() throws {
        print("Updating packages...")

        do {
            try generateMasterPackageDescription()
            try generatedFolder.moveToAndPerform(command: "swift package --enable-prefetching update")
            try generatedFolder.createSubfolderIfNeeded(withName: "Packages")
        } catch {
            throw Error.failedToUpdatePackages(folder)
        }
    }

    private func generateMasterPackageDescription() throws {
        var description = "import PackageDescription\n\n" +
                          "let package = Package(\n" +
                          "    name: \"\(masterPackageName)\",\n" +
                          "    dependencies: [\n"

        for (index, file) in folder.files.enumerated() {
            let package = try perform(unbox(data: file.read()) as Package,
                                      orThrow: Error.failedToReadPackageFile(file.name))

            if index > 0 {
                description += ",\n"
            }

            description += "        " + package.dependencyString
        }

        description += "\n    ]\n)"

        try generatedFolder.createFile(named: "Package.swift",
                                       contents: description.data(using: .utf8)!)
    }

    private func makePackageList() -> [Package] {
        return folder.files.flatMap { file in
            return try? unbox(data: file.read())
        }
    }
}
