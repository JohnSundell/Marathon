# Contributing to Marathon

First of all, super exciting that you want to contribute to Marathon! 🎉👍🚀

The goal of the Marathon project is ambitious but also simple: *"To provide a world class development
environment for Swift scripting, making it the easiest to use and most powerful way of creating scripts,
automation & developer tools"*.

You can help us reach that goal by contributing. Here are some ways you can contribute:

- [Report any issues or bugs that you find](https://github.com/JohnSundell/Marathon/issues/new)
- [Open issues for any new features you'd like Marathon to have](https://github.com/JohnSundell/Marathon/issues/new)
- [Implement one of our starter tasks](https://github.com/JohnSundell/Marathon/issues?q=is%3Aissue+is%3Aopen+label%3A%22starter+task%22)
- [Implement other tasks selected for development](https://github.com/JohnSundell/Marathon/issues?q=is%3Aissue+is%3Aopen+label%3A%22ready+for+implementation%22)
- [Help answer questions asked by the community](https://github.com/JohnSundell/Marathon/issues?q=is%3Aopen+is%3Aissue+label%3Aquestion)
- [Share a script as an example](https://github.com/JohnSundell/Marathon-Examples)
- [Spread the word about Marathon](https://twitter.com/intent/tweet?text=Marathon%20makes%20it%20easy%20to%20write,%20run%20and%20manage%20your%20Swift%20scripts:%20https://github.com/johnsundell/marathon)

## Code of conduct

All contributors are expected to follow our [Code of conduct](CONDUCT.md).
Please read it before making any contributions.

## Setting up the project for development

Marathon uses the [Swift Package Manager](https://github.com/apple/swift-package-manager) as its build system.

No Xcode project is checked into the repository, and is instead git ignored and ad-hoc generated.

To generate an Xcode project to begin development, run `$ swift package generate-xcodeproj` in the Marathon repository.

It's recommended that you re-generate the Xcode project whenever you pull down new changes, as files might've been added or removed.

## Running tests

Tests should be added for all functionality, both when adding new behaviors to existing features, and implementing new ones.

Marathon uses `XCTest` to run its tests, which can either be run through Xcode or by running `$ swift test` in the repository.

## Architectural overview

Here is a quick overview of the architecture of Marathon, to help you orient yourself in the project.

### Modules

Marathon consists of 3 modules (+ its dependencies). These are:
- Marathon (the command line app that the user can run)
- MarathonCore (a framework that Marathon links against)
- MarathonTests (test suite for Marathon, run against MarathonCore)

For more information, take a look at [Package.swift](https://github.com/JohnSundell/Marathon/blob/master/Package.swift).

### Commands

Whenever the user runs a command (such as `marathon run`), the arguments passed into Marathon will be resolved into a
[`Command`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/Command.swift). The command contains
information such as usage instructions, but its most important job is to resolve a `Task` to be executed.

### Tasks

Marathon uses a modular architecture, where each part of its functionality is implemented as a [`Task`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/Task.swift).
For example, running a script is done by [`RunTask`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/Run.swift) and editing a script is done by [`EditTask`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/Edit.swift). If a new feature should be implemented, this should be done as a new task.

### ScriptManager

Tasks that manipulate scripts in any way do this through [`ScriptManager`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/ScriptManager.swift), which is responsible for managing all scripts that Marathon knows about.
It performs tasks such as creating cache folders, removing script data, and loading script files. For each script, it creates a [`Script`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/Script.swift) instance, that
can be used to work with the script in an object-oriented way.

### PackageManager

The equivalent of `ScriptManager` for packages is [`PackageManager`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/PackageManager.swift). It is responsible for managing the
packages that have been added to Marathon through `marathon add`, as well as through a `Marathonfile`. For each package, it stores metadata in a JSON file, and loads this data into a [`Package`](https://github.com/JohnSundell/Marathon/blob/master/Sources/MarathonCore/Package.swift)
instance before working with the package.

## Questions or discussions

If you have a question about the inner workings of Marathon, or if you want to discuss a new feature - feel free to [open an issue](https://github.com/JohnSundell/Marathon/issues/new).
If you're planning to make a non-trivial change to the project, it's usually a good idea to discuss it in an issue first, to make the workflow as smooth as possible.

Happy contributing! 🚀
