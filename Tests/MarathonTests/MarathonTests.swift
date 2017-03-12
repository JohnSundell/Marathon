/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import XCTest
import MarathonCore
import Files

class MarathonTests: XCTestCase {
    fileprivate var folder: Folder!

    // MARK: - XCTestCase

    override func setUp() {
        super.setUp()
        folder = createFolder()
    }

    override func tearDown() {
        try! folder.delete()
        super.tearDown()
    }

    // MARK: - Command parsing

    func testInvalidCommandThrows() {
        assert(try run(with: ["not-a-valid-command"]), throwsError: CommandError.invalid("not-a-valid-command"))
    }

    // MARK: - Managing packages

    func testAddingAndRemovingRemotePackage() throws {
        try run(with: ["add", "git@github.com:JohnSundell/Files.git"])
        XCTAssertNotNil(try? folder.subfolder(named: "Packages").file(named: "Files").read())

        let generatedFolder = try folder.subfolder(atPath: "Packages/Generated")

        let packageFile = try generatedFolder.file(named: "Package.swift")
        try XCTAssertTrue(packageFile.readAsString().contains("git@github.com:JohnSundell/Files.git"))

        let packagesFolder = try generatedFolder.subfolder(named: "Packages")
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertTrue(packagesFolder.subfolders.first!.name.hasPrefix("Files"))

        // List should now include the package
        try XCTAssertTrue(run(with: ["list"]).contains("git@github.com:JohnSundell/Files.git"))

        // Remove the package
        try run(with: ["remove", "files"])
        XCTAssertEqual(packagesFolder.subfolders.count, 0)
        try XCTAssertEqual(folder.subfolder(named: "Packages").files.count, 0)

        // List should no longer include the package
        try XCTAssertFalse(run(with: ["list"]).contains("git@github.com:JohnSundell/Files.git"))
    }

    func testAddingAndRemovingLocalPackage() throws {
        let packageFolder = try folder.createSubfolder(named: "TestPackage")
        try packageFolder.moveToAndPerform(command: "swift package init")

        let gitCommand = "git init && git add . && git commit -a -m \"Commit\" && git tag 0.1.0"
        try packageFolder.moveToAndPerform(command: gitCommand)

        try run(with: ["add", packageFolder.path])
        XCTAssertNotNil(try? folder.subfolder(named: "Packages").file(named: "TestPackage").read())

        let generatedFolder = try folder.subfolder(atPath: "Packages/Generated")

        let packageFile = try generatedFolder.file(named: "Package.swift")
        try XCTAssertTrue(packageFile.readAsString().contains(packageFolder.path))

        let packagesFolder = try generatedFolder.subfolder(named: "Packages")
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(packagesFolder.subfolders.first!.name, "TestPackage-0.1.0")

        // List should now include the package
        try XCTAssertTrue(run(with: ["list"]).contains(packageFolder.path))

        // Remove the package
        try run(with: ["remove", "TestPackage"])
        XCTAssertEqual(packagesFolder.subfolders.count, 0)
        try XCTAssertEqual(folder.subfolder(named: "Packages").files.count, 0)

        // List should no longer include the package
        try XCTAssertFalse(run(with: ["list"]).contains(packageFolder.path))
    }

    func testAddingAlreadyAddedPackageThrows() throws {
        try run(with: ["add", "git@github.com:JohnSundell/Files.git"])
        XCTAssertNotNil(try? folder.subfolder(named: "Packages").file(named: "Files").read())

        assert(try run(with: ["add", "git@github.com:JohnSundell/Files.git"]),
               throwsError: PackageManagerError.packageAlreadyAdded("Files"))
    }

    // MARK: - Running scripts

    func testRunningScriptWithoutPathThrows() {
        assert(try run(with: ["run"]), throwsError: RunError.missingPath)
    }

    func testRunningScript() throws {
        let script = "import Files\n\n" +
                     "try FileSystem().createFolder(at: \"\(folder.path)addedFromScript\")"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["add", "git@github.com:JohnSundell/Files.git"])
        try run(with: ["run", scriptFile.path])

        XCTAssertNotNil(try? folder.subfolder(named: "addedFromScript"))
    }

    func testRunningScriptWithNewDependency() throws {
        var script = "import Foundation\n\n" +
                     "let filePath = \"\(folder.path)addedFromScript\"\n"

        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["run", scriptFile.path])
        try run(with: ["add", "git@github.com:JohnSundell/Files.git"])

        script += "import Files\n\n" +
                  "try FileSystem().createFolder(at: filePath)"
        try scriptFile.write(string: script)
        try run(with: ["run", scriptFile.path])
    }

    func testRunningScriptWithCompileErrorThrows() throws {
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: "notAFunction()")

        let expectedError = RunError.failedToCompileScript(["1:1: use of unresolved identifier 'notAFunction'"])
        assert(try run(with: ["run", scriptFile.path]), throwsError: expectedError)
    }

    func testRunningScriptWithRuntimeErrorThrows() throws {
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: "fatalError(\"Script failed\")")

        // A simple error check will have to do here, since the stack trace is too complex to assert equality to
        XCTAssertThrowsError(try run(with: ["run", scriptFile.path]))
    }

    func testRunningScriptReturnsOutput() throws {
        let script = "import Foundation\n\n" +
                     "print(\"Hello world!\")"

        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        let output = try run(with: ["run", scriptFile.path])
        XCTAssertEqual(output, "Hello world!")
    }

    func testPassingArgumentsToScript() throws {
        let script = "import Foundation\n\n" +
                     "let arguments = ProcessInfo.processInfo.arguments\n" +
                     "print(arguments[1] + \", \" + arguments[2])"

        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        let output = try run(with: ["run", scriptFile.path, "Arg1", "Arg2"])
        XCTAssertEqual(output, "Arg1, Arg2")
    }

    func testCurrentWorkingDirectoryOfScriptIsExecutionFolder() throws {
        let script = "import Foundation\n\n" +
                     "print(FileManager.default.currentDirectoryPath + \"/\")"

        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        let output = try run(with: ["run", scriptFile.path])
        try XCTAssertEqual(output, Folder(path: "").path)
    }

    // MARK: - Creating scripts

    func testCreatingScriptWithoutNameThrows() {
        assert(try run(with: ["create"]), throwsError: CreateError.missingName)
    }

    func testCreatingScript() throws {
        try run(with: ["create", "script", "-no-open"])

        let scriptFile = try File(path: FileSystem().currentFolder.path + "script.swift")
        try scriptFile.delete()
    }

    func testEditingScriptWithoutPathThrows() {
        assert(try run(with: ["edit"]), throwsError: EditError.missingPath)
    }

    func testEditingScriptWithXcode() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["edit", scriptFile.path, "-no-open"])

        let scriptFolders = try folder.subfolder(named: "Scripts").subfolders
        XCTAssertEqual(scriptFolders.count, 1)
        XCTAssertNotNil(try? scriptFolders.first!.subfolder(named: "Script.xcodeproj"))
    }

    func testEditingScriptWithoutXcode() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["edit", scriptFile.path, "-no-xcode", "-no-open"])

        let scriptFolders = try folder.subfolder(named: "Scripts").subfolders
        XCTAssertEqual(scriptFolders.count, 1)
        XCTAssertNil(try? scriptFolders.first!.subfolder(named: "Script.xcodeproj"))
    }

    // MARK: - Removing script data

    func testRemovingScriptCacheData() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["run", scriptFile.path])

        let scriptsFolder = try folder.subfolder(named: "Scripts")
        XCTAssertEqual(scriptsFolder.subfolders.count, 1)

        try run(with: ["remove", scriptFile.path])
        XCTAssertEqual(scriptsFolder.subfolders.count, 0)

        // Make sure that the actual script file is not removed, only the cache data
        XCTAssertNotNil(try? scriptFile.read())
    }

    // MARK: - Updating packages

    func testUpdatingPackages() throws {
        // First make sure running update without any packages doesn't throw
        try run(with: ["update"])

        let packageFolder = try folder.createSubfolder(named: "TestPackage")
        try packageFolder.moveToAndPerform(command: "swift package init")

        let gitCommand = "git init && git add . && git commit -a -m \"Commit\" && git tag 0.1.0"
        try packageFolder.moveToAndPerform(command: gitCommand)

        try run(with: ["add", packageFolder.path])
        XCTAssertNotNil(try? folder.subfolder(named: "Packages").file(named: "TestPackage").read())

        let packagesFolder = try folder.subfolder(atPath: "Packages/Generated/Packages")
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(packagesFolder.subfolders.first!.name, "TestPackage-0.1.0")

        // Bump to a new minor version and update
        try packageFolder.moveToAndPerform(command: "git tag 0.2.0")
        try run(with: ["update"])
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(packagesFolder.subfolders.first!.name, "TestPackage-0.2.0")

        // Bump to a new major version and update
        try packageFolder.moveToAndPerform(command: "git tag 1.0.0")
        try run(with: ["update"])
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(packagesFolder.subfolders.first!.name, "TestPackage-1.0.0")
    }

    // MARK: - Using a Marathonfile

    func testUsingMarathonfileToInstallDependencies() throws {
        // Add Files before, since already installed dependencies should be ignored
        try run(with: ["add", "git@github.com:JohnSundell/Files.git"])

        let script = "import Foundation\n" +
                     "import Files\n" +
                     "import Wrap\n\n" +
                     "FileSystem().homeFolder\n" +
                     "struct MyStruct {}\n" +
                     "try wrap(MyStruct()) as Data"

        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        let marathonFileContent = "git@github.com:JohnSundell/Files.git\n" +
                                  "git@github.com:JohnSundell/Wrap.git"

        let marathonFile = try folder.createFile(named: "Marathonfile")
        try marathonFile.write(string: marathonFileContent)

        try run(with: ["run", scriptFile.path])

        let packagesFolder = try folder.subfolder(atPath: "Packages/Generated/Packages")
        XCTAssertEqual(packagesFolder.subfolders.count, 2)
    }

    func testIncorrectlyFormattedMarathonfileThrows() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        let marathonFile = try folder.createFile(named: "Marathonfile")
        try marathonFile.write(string: "💥")

        assert(try run(with: ["run", scriptFile.path]),
               throwsError: PackageManagerError.failedToReadMarathonFile(marathonFile))
    }
}

// MARK: - Utilities

fileprivate extension MarathonTests {
    func createFolder() -> Folder {
        let folderName = ".marathonTests"

        if let existingFolder = try? FileSystem().homeFolder.subfolder(named: folderName) {
            try! existingFolder.empty(includeHidden: true)
            return existingFolder
        }

        return try! FileSystem().homeFolder.createSubfolder(named: folderName)
    }

    @discardableResult func run(with arguments: [String]) throws -> String {
        var arguments = arguments
        arguments.insert(folder.path, at: 0)
        return try Marathon.run(with: arguments, folderPath: folder.path)
    }
}

// MARK: - Linux

#if os(Linux)
extension MarathonTests {
    static var allTests : [(String, (MarathonTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
#endif
