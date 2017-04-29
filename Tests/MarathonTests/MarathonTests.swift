/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import XCTest
import MarathonCore
import Files
import Unbox
import Require

class MarathonTests: XCTestCase {
    fileprivate var folder: Folder!

    // MARK: - XCTestCase

    override func setUp() {
        super.setUp()
        folder = createFolder()
        FileManager.default.changeCurrentDirectoryPath(folder.path)
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

        let packagesFolder = try generatedFolder.subfolder(named: ".build/checkouts")
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(packagesFolder.subfolders.first?.name.hasPrefix("Files.git"), true)

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

        try run(with: ["add", "TestPackage"])
        XCTAssertNotNil(try? folder.subfolder(named: "Packages").file(named: "TestPackage").read())

        let generatedFolder = try folder.subfolder(atPath: "Packages/Generated")

        let packageFile = try generatedFolder.file(named: "Package.swift")
        try XCTAssertTrue(packageFile.readAsString().contains(packageFolder.path))

        let packagesFolder = try generatedFolder.subfolder(atPath: ".build/checkouts")
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(packagesFolder.subfolders.first?.name.hasPrefix("TestPackage-"), true)

        // List should now include the package
        try XCTAssertTrue(run(with: ["list"]).contains(packageFolder.path))

        // Remove the package
        try run(with: ["remove", "TestPackage"])
        XCTAssertEqual(packagesFolder.subfolders.count, 0)
        try XCTAssertEqual(folder.subfolder(named: "Packages").files.count, 0)

        // List should no longer include the package
        try XCTAssertFalse(run(with: ["list"]).contains(packageFolder.path))
    }

    func testRemovingAllPackages() throws {
        try run(with: ["add", "git@github.com:JohnSundell/Files.git"])
        try run(with: ["add", "git@github.com:JohnSundell/Wrap.git"])
        try run(with: ["add", "git@github.com:JohnSundell/Unbox.git"])

        let generatedFolder = try folder.subfolder(atPath: "Packages/Generated")
        let packagesFolder = try generatedFolder.subfolder(named: ".build/checkouts")
        XCTAssertEqual(packagesFolder.subfolders.count, 3)
        try XCTAssertEqual(folder.subfolder(named: "Packages").files.count, 3)

        // Remove all packages
        try run(with: ["remove", "--all-packages"])
        XCTAssertEqual(packagesFolder.subfolders.count, 0)
        try XCTAssertEqual(folder.subfolder(named: "Packages").files.count, 0)
    }

    func testAddingLocalPackage() throws {
        let packageFolder = try folder.createSubfolder(named: "TestPackage")
        try packageFolder.moveToAndPerform(command: "swift package init")

        let packageDescription = "import PackageDescription\n" +
                                 "let package = Package(name: \"TestPackage\")"

        let packageFile = try packageFolder.file(named: "Package.swift")
        try packageFile.write(string: packageDescription)

        let gitCommand = "git init && git add . && git commit -a -m \"Commit\" && git tag 0.1.0"
        try packageFolder.moveToAndPerform(command: gitCommand)

        try run(with: ["add", "TestPackage"])
        XCTAssertNotNil(try? folder.subfolder(named: "Packages").file(named: "TestPackage").read())

        let generatedFolder = try folder.subfolder(atPath: "Packages/Generated")

        let generatedPackageFile = try generatedFolder.file(named: "Package.swift")
        try XCTAssertTrue(generatedPackageFile.readAsString().contains(packageFolder.path))

        let packageNames = try generatedFolder.subfolder(atPath: ".build/checkouts").subfolders.names
        XCTAssertEqual(packageNames.count, 1)
        XCTAssertTrue(packageNames.contains { $0.hasPrefix("TestPackage-") })
    }

    func testAddingLocalPackageWithDependency() throws {
        let packageFolder = try folder.createSubfolder(named: "TestPackage")
        try packageFolder.moveToAndPerform(command: "swift package init")

        let packageDescription = "import PackageDescription\n" +
                                 "let package = Package(name: \"TestPackage\",\n" +
                                 "dependencies: [.Package(url: \"https://github.com/johnsundell/Files.git\", majorVersion: 1)])"

        let packageFile = try packageFolder.file(named: "Package.swift")
        try packageFile.write(string: packageDescription)

        let gitCommand = "git init && git add . && git commit -a -m \"Commit\" && git tag 0.1.0"
        try packageFolder.moveToAndPerform(command: gitCommand)

        try run(with: ["add", "TestPackage"])
        XCTAssertNotNil(try? folder.subfolder(named: "Packages").file(named: "TestPackage").read())

        let generatedFolder = try folder.subfolder(atPath: "Packages/Generated")

        let generatedPackageFile = try generatedFolder.file(named: "Package.swift")
        try XCTAssertTrue(generatedPackageFile.readAsString().contains(packageFolder.path))

        let packageNames = try generatedFolder.subfolder(atPath: ".build/checkouts").subfolders.names
        XCTAssertEqual(packageNames.count, 2)
        XCTAssertTrue(packageNames.contains { $0.hasPrefix("TestPackage-") })
        XCTAssertTrue(packageNames.contains { $0.hasPrefix("Files.git-") })
    }

    func testAddingLocalPackageWithUnsortedVersionsContainingLetters() throws {
        let packageFolder = try folder.createSubfolder(named: "TestPackage")
        try packageFolder.moveToAndPerform(command: "swift package init")

        let gitInitCommand = "git init && git add . && git commit -a -m \"Commit\" && git tag 0.1.0"
        try packageFolder.moveToAndPerform(command: gitInitCommand)

        // Here we tag a future version first, to make sure Marathon is able to order the versions correctly
        try packageFolder.moveToAndPerform(command: "git tag 1.0.0")

        // Tag a few versions with a "v" prefix
        try packageFolder.moveToAndPerform(command: "git tag v0.2.0")
        try packageFolder.moveToAndPerform(command: "git tag v0.3.0")

        // Also tag a few alpha & beta versions, which should be ignored
        try packageFolder.moveToAndPerform(command: "git tag 2.0.0-alpha")
        try packageFolder.moveToAndPerform(command: "git tag 2.0.0a")
        try packageFolder.moveToAndPerform(command: "git tag 2.0.0-beta")
        try packageFolder.moveToAndPerform(command: "git tag 2.0.0b")

        try run(with: ["add", "TestPackage"])
        let packageData = try folder.subfolder(named: "Packages").file(named: "TestPackage").read()
        let package = try unbox(data: packageData) as Package
        XCTAssertEqual(package.majorVersion, 1)
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

        // List should now include cache data for the script
        try XCTAssertTrue(run(with: ["list"]).contains(scriptFile.path))
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

    func testRunningScriptWithBuildFailedErrorThrows() throws {
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: "notAFunction()")

        let expectedError = ScriptError.buildFailed(["1:1: use of unresolved identifier 'notAFunction'"], missingPackage: nil)
        assert(try run(with: ["run", scriptFile.path]), throwsError: expectedError)
    }

    func testRunningScriptWithBuildFailedErrorWhenNoSuchModuleThrows() throws {
        let scriptFile = try folder.createFile(named: "script.swift")
        let packageName = "Files"
        try scriptFile.write(string: "import \(packageName)")

        let expectedError = ScriptError.buildFailed(["1:8: no such module '\(packageName)'"], missingPackage: packageName)
        assert(try run(with: ["run", scriptFile.path]), throwsError: expectedError)

        XCTAssertTrue(expectedError.description.contains("You can add \(packageName) to Marathon using 'marathon add <url-to-\(packageName)>'"))
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

    func testScriptWithLargeAmountOfOutput() throws {
        let script = "for _ in 0..<99999 { print(\"Hello\") }"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)
        try run(with: ["run", scriptFile.path])
    }

    func testRunningScriptWithVerboseOutput() throws {
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: "")

        let output = try run(with: ["run", scriptFile.path, "--verbose"])
        XCTAssertTrue(output.contains("🏃"))
    }

    // MARK: - Installing scripts

    func testInstallingLocalScript() throws {
        try run(with: ["add", "git@github.com:JohnSundell/Files.git"])

        let script = "import Files\n\n" +
                     "print(FileSystem().currentFolder.path)"

        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["install", "script", "installed-script"])

        // Run the installed binary
        let output = try folder.moveToAndPerform(command: "./installed-script")
        XCTAssertEqual(output, folder.path)

        // Force a re-install
        try scriptFile.write(string: "print(\"Re-installed\")")
        try run(with: ["install", "script", "installed-script", "--force"])
        let reInstalledOutput = try folder.moveToAndPerform(command: "./installed-script")
        XCTAssertEqual(reInstalledOutput, "Re-installed")
    }
    
    func testInstallingRemoteScriptWithDependenciesUsingRegularGithubURL() throws {
        let gitHubURLString = "https://github.com/JohnSundell/Marathon-Examples/blob/master/AddSuffix/addSuffix.swift"
        try testInstallingRemoteScriptWithDependenciesUsingURL(gitHubURLString)
    }
    
    func testInstallingRemoteScriptWithDependenciesUsingRawGithubURL() throws {
        let rawGitHubURLString = "https://raw.githubusercontent.com/JohnSundell/Marathon-Examples/master/AddSuffix/addSuffix.swift"
        try testInstallingRemoteScriptWithDependenciesUsingURL(rawGitHubURLString)
    }

    // MARK: - Creating scripts

    func testCreatingScriptWithoutNameThrows() {
        assert(try run(with: ["create"]), throwsError: CreateError.missingName)
    }

    func testCreatingScriptWithName() throws {
        try run(with: ["create", "script", "--no-open"])

        let scriptFile = try File(path: FileSystem().currentFolder.path + "script.swift")

        // Verify that the script has default content
        try XCTAssertEqual(scriptFile.readAsString(), "import Foundation\n\n")

        // Delete the file since we're creating it in the current working folder
        try scriptFile.delete()
    }

    func testCreatingScriptWithPath() throws {
        let scriptFolder = try folder.createSubfolder(named: "testScript")
        let scriptPath = scriptFolder.path + "script.swift"

        try run(with: ["create", scriptPath, "--no-open"])
        try XCTAssertFalse(scriptFolder.file(named: "script.swift").read().isEmpty)
    }

    func testCreatingScriptWithContent() throws {
        let script = "import Foundation\nprint(\"Hello\")"
        try run(with: ["create", "script", script, "--no-open"])

        let scriptFile = try File(path: FileSystem().currentFolder.path + "script.swift")
        try XCTAssertEqual(scriptFile.readAsString(), script)

        // Delete the file since we're creating it in the current working folder
        try scriptFile.delete()
    }

    func testCreatingAndRunningScriptInFolderWithSpaces() throws {
        let scriptFolder = try folder.createSubfolder(named: "test script with spaces")
        let scriptPath = scriptFolder.path + "script.swift"

        try run(with: ["create", scriptPath, "--no-open"])

        // For running the script, move to the script folder to ensure that spaces are handled
        FileManager.default.changeCurrentDirectoryPath(scriptFolder.path)
        try run(with: ["run", "script"])
    }

    // MARK: - Editing scripts

    func testEditingScriptWithoutPathThrows() {
        assert(try run(with: ["edit"]), throwsError: EditError.missingPath)
    }

    func testEditingScriptWithXcode() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["edit", scriptFile.path, "--no-open"])

        let scriptFolders = try folder.subfolder(atPath: "Scripts/Cache").subfolders
        XCTAssertEqual(scriptFolders.count, 1)
        XCTAssertNotNil(try? scriptFolders.first.require().subfolder(named: "Script.xcodeproj"))
    }

    func testEditingScriptWithoutXcode() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["edit", scriptFile.path, "--no-xcode", "--no-open"])

        let scriptFolders = try folder.subfolder(atPath: "Scripts/Cache").subfolders
        XCTAssertEqual(scriptFolders.count, 1)
        XCTAssertNil(try? scriptFolders.first.require().subfolder(named: "Script.xcodeproj"))
    }

    // MARK: - Removing script data

    func testRemovingScriptCacheData() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        try run(with: ["run", scriptFile.path])

        let scriptsFolder = try folder.subfolder(atPath: "Scripts/Cache")
        XCTAssertEqual(scriptsFolder.subfolders.count, 1)

        try run(with: ["remove", scriptFile.path])
        XCTAssertEqual(scriptsFolder.subfolders.count, 0)

        // Make sure that the actual script file is not removed, only the cache data
        XCTAssertNotNil(try? scriptFile.read())
    }

    func testRemovingScriptCacheDataForDeletedScript() throws {
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: "import Foundation")

        try run(with: ["run", scriptFile.path])

        let scriptsFolder = try folder.subfolder(atPath: "Scripts/Cache")
        XCTAssertEqual(scriptsFolder.subfolders.count, 1)

        // Delete the script before running 'remove'
        try scriptFile.delete()

        try run(with: ["remove", scriptFile.path])
        XCTAssertEqual(scriptsFolder.subfolders.count, 0)
    }

    func testRemovingAllScriptData() throws {
        var scriptFiles: [File] = []

        for i in 0..<3 {
            let scriptFile = try folder.createFile(named: "script_\(i).swift")
            try scriptFile.write(string: "import Foundation")
            try run(with: ["run", scriptFile.path])
            scriptFiles.append(scriptFile)
        }

        let scriptsFolder = try folder.subfolder(atPath: "Scripts/Cache")
        XCTAssertEqual(scriptsFolder.subfolders.count, scriptFiles.count)

        // Delete the script before running 'remove'
        for scriptFile in scriptFiles {
            try scriptFile.delete()
        }

        try run(with: ["remove", "--all-script-data"])
        XCTAssertEqual(scriptsFolder.subfolders.count, 0)
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

        let packagesFolder = try folder.subfolder(atPath: "Packages/Generated/.build/checkouts")
        let checkedOutFolder = packagesFolder.subfolders.first
        XCTAssertNotNil(checkedOutFolder)

        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(checkedOutFolder?.name.hasPrefix("TestPackage-"), true)
        XCTAssertEqual(try checkedOutFolder?.moveToAndPerform(command: "git tag").contains("0.1.0"), true)

        // Bump to a new minor version and update
        try packageFolder.moveToAndPerform(command: "git tag 0.2.0")
        try run(with: ["update"])
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(checkedOutFolder?.name.hasPrefix("TestPackage-"), true)
        XCTAssertEqual(try checkedOutFolder?.moveToAndPerform(command: "git tag").contains("0.2.0"), true)

        // Bump to a new major version and update
        try packageFolder.moveToAndPerform(command: "git tag 1.0.0")
        try run(with: ["update"])
        XCTAssertEqual(packagesFolder.subfolders.count, 1)
        XCTAssertEqual(checkedOutFolder?.name.hasPrefix("TestPackage-"), true)
        XCTAssertEqual(try checkedOutFolder?.moveToAndPerform(command: "git tag").contains("1.0.0"), true)
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

        let packagesFolder = try folder.subfolder(atPath: "Packages/Generated/.build/checkouts")
        XCTAssertEqual(packagesFolder.subfolders.count, 2)
    }

    func testAddingLocalPackageUsingRelativePathInMarathonfile() throws {
        let packageFolder = try folder.createSubfolder(named: "TestPackage")
        try packageFolder.moveToAndPerform(command: "swift package init")

        let gitCommand = "git init && git add . && git commit -a -m \"Commit\" && git tag 0.1.0"
        try packageFolder.moveToAndPerform(command: gitCommand)

        let scriptFolder = try folder.createSubfolder(named: "TestScript")

        let scriptFile = try scriptFolder.createFile(named: "script.swift")
        try scriptFile.write(string: "import TestPackage")

        let marathonFile = try scriptFolder.createFile(named: "Marathonfile")
        try marathonFile.write(string: "../TestPackage")

        try run(with: ["run", "TestScript/script"])
    }

    func testAddingOtherScriptAsDependencyUsingMarathonfile() throws {
        let scriptFolder = try folder.createSubfolder(named: "TestScript")

        let script = "import Foundation\nprint(helloWorld())"
        let scriptFile = try scriptFolder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        let dependencyScriptFile = try scriptFolder.createFile(named: "dependency.swift")
        try dependencyScriptFile.write(string: "func helloWorld() -> String { return \"Hello world\" }")

        let marathonFile = try scriptFolder.createFile(named: "Marathonfile")
        try marathonFile.write(string: "dependency.swift")

        XCTAssertEqual(try run(with: ["run", "TestScript/script"]), "Hello world")

        // Verify build folder structure
        let buildFolder = try folder.subfolder(atPath: "Scripts/Cache").subfolders.first.require().subfolder(named: "Sources")
        XCTAssertEqual(buildFolder.files.names, ["dependency.swift", "main.swift"])

        // Scripts removed from the Marathonfile should also be removed from the build folder
        try marathonFile.write(string: "")
        try scriptFile.write(string: "import Foundation\nprint(\"Hello again\")")

        XCTAssertEqual(try run(with: ["run", "TestScript/script"]), "Hello again")
        XCTAssertEqual(buildFolder.files.names, ["main.swift"])
    }

    func testIncorrectlyFormattedMarathonfileThrows() throws {
        let script = "import Foundation"
        let scriptFile = try folder.createFile(named: "script.swift")
        try scriptFile.write(string: script)

        let marathonFile = try folder.createFile(named: "Marathonfile")
        try marathonFile.write(string: "💥")

        assert(try run(with: ["run", scriptFile.path]),
               throwsError: MarathonFileError.failedToRead(marathonFile))
    }

    // MARK: - Source verification

    func testNoDirectUsesOfPrintFunction() throws {
        for file in try resolveSourceFiles() {
            XCTAssertEqual(file.extension, "swift")

            // Whitelist Marathon.swift & main.swift, since it sets up the Printer wrapper
            switch file.nameExcludingExtension {
            case "Marathon", "main":
                continue
            default:
                break
            }

            let source = try file.readAsString()
            XCTAssertFalse(source.contains("print("),
                           "\(file.name) uses the print() function directly. Use Printer instead.")
        }
    }

    func testNoDirectUsesOfShellOut() throws {
        for file in try resolveSourceFiles() {
            XCTAssertEqual(file.extension, "swift")

            // Whitelist ShellOut+Marathon.swift, since it wraps ShellOut
            guard file.nameExcludingExtension != "ShellOut+Marathon" else {
                continue
            }

            for line in try file.readAsString().components(separatedBy: "\n") {
                guard line.contains("shellOut(to:") else {
                    continue
                }

                XCTAssertTrue(line.contains("printer:"),
                              "\(file.name) uses ShellOut directly. Use ShellOut+Marathon instead.")
            }
        }
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

        var output = ""

        let printFunction: PrintFunction = { message in
            output.append(message)
        }

        try Marathon.run(with: arguments, folderPath: folder.path, printFunction: printFunction)

        return output
    }

    func resolveSourceFiles() throws -> FileSystemSequence<File> {
        let currentFile = try File(path: #file)
        let testModuleFolder = currentFile.parent.require()
        let sourcesFolder = try Folder(path: "\(testModuleFolder.path)../../Sources")
        XCTAssertEqual(sourcesFolder.name, "Sources")

        let sourceFiles = sourcesFolder.makeFileSequence(recursive: true)
        XCTAssertNotNil(sourceFiles.first)

        return sourceFiles
    }
}

// MARK: - Linux

#if os(Linux)
extension MarathonTests {
    static var allTests : [(String, (MarathonTests) -> () throws -> Void)] {
        return [
            ("testInvalidCommandThrows", testInvalidCommandThrows),
            ("testAddingAndRemovingRemotePackage", testAddingAndRemovingRemotePackage),
            ("testAddingAndRemovingLocalPackage", testAddingAndRemovingLocalPackage),
            ("testRemovingAllPackages", testRemovingAllPackages),
            ("testAddingLocalPackageWithDependency", testAddingLocalPackageWithDependency),
            ("testAddingLocalPackageWithUnsortedVersionsContainingLetters", testAddingLocalPackageWithUnsortedVersionsContainingLetters),
            ("testAddingAlreadyAddedPackageThrows", testAddingAlreadyAddedPackageThrows),
            ("testRunningScriptWithoutPathThrows", testRunningScriptWithoutPathThrows),
            ("testRunningScript", testRunningScript),
            ("testRunningScriptWithNewDependency", testRunningScriptWithNewDependency),
            ("testRunningScriptWithBuildFailedErrorThrows", testRunningScriptWithBuildFailedErrorThrows),
            ("testRunningScriptWithBuildFailedErrorWhenNoSuchModuleThrows", testRunningScriptWithBuildFailedErrorWhenNoSuchModuleThrows),
            ("testRunningScriptWithRuntimeErrorThrows", testRunningScriptWithRuntimeErrorThrows),
            ("testRunningScriptReturnsOutput", testRunningScriptReturnsOutput),
            ("testPassingArgumentsToScript", testPassingArgumentsToScript),
            ("testCurrentWorkingDirectoryOfScriptIsExecutionFolder", testCurrentWorkingDirectoryOfScriptIsExecutionFolder),
            ("testScriptWithLargeAmountOfOutput", testScriptWithLargeAmountOfOutput),
            ("testInstallingLocalScript", testInstallingLocalScript),
            ("testInstallingRemoteScriptWithDependencies", testInstallingRemoteScriptWithDependencies),
            ("testCreatingScriptWithoutNameThrows", testCreatingScriptWithoutNameThrows),
            ("testCreatingScriptWithName", testCreatingScriptWithName),
            ("testCreatingScriptWithPath", testCreatingScriptWithPath),
            ("testCreatingScriptWithContent", testCreatingScriptWithContent),
            ("testCreatingAndRunningScriptInFolderWithSpaces", testCreatingAndRunningScriptInFolderWithSpaces),
            ("testEditingScriptWithoutPathThrows", testEditingScriptWithoutPathThrows),
            ("testEditingScriptWithoutXcode", testEditingScriptWithoutXcode),
            ("testRemovingScriptCacheData", testRemovingScriptCacheData),
            ("testRemovingScriptCacheDataForDeletedScript", testRemovingScriptCacheDataForDeletedScript),
            ("testRemovingAllScriptData", testRemovingAllScriptData),
            ("testUpdatingPackages", testUpdatingPackages),
            ("testUsingMarathonfileToInstallDependencies", testUsingMarathonfileToInstallDependencies),
            ("testAddingLocalPackageUsingRelativePathInMarathonfile", testAddingLocalPackageUsingRelativePathInMarathonfile),
            ("testAddingOtherScriptAsDependencyUsingMarathonfile", testAddingOtherScriptAsDependencyUsingMarathonfile),
            ("testIncorrectlyFormattedMarathonfileThrows", testIncorrectlyFormattedMarathonfileThrows),
            ("testNoDirectUsesOfPrintFunction", testNoDirectUsesOfPrintFunction),
            ("testNoDirectUsesOfShellOut", testNoDirectUsesOfShellOut)
        ]
    }
}
#endif

// MARK: - Abstract Test Cases

fileprivate extension MarathonTests {
    func testInstallingRemoteScriptWithDependenciesUsingURL(_ urlString: String) throws {
        try run(with: ["install", urlString, "installed-script"])
        
        // Make a couple of files that we can try the installed script on
        let executionFolder = try folder.createSubfolder(named: "TestInstallation")
        try executionFolder.createFile(named: "A.swift")
        try executionFolder.createFile(named: "B.swift")
        
        // Run the installed binary
        try executionFolder.moveToAndPerform(command: "../installed-script -suffix")
        XCTAssertEqual(executionFolder.files.names, ["A-suffix.swift", "B-suffix.swift"])
        
        // List should not contain the script, as it was only added temporarily
        try XCTAssertFalse(run(with: ["list"]).lowercased().contains("addsuffix"))
        
        // Make sure that the temporary folder for the script is cleaned up
        try XCTAssertEqual(folder.subfolder(atPath: "Scripts/Temp").subfolders.count, 0)
    }
}
