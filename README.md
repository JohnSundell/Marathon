<p align="center">
    <img src="Logo.png" width="480" max-width="90%" alt="Marathon" />
</p>

<p align="center">
    <a href="https://dashboard.buddybuild.com/apps/58ff19a79a06210001d14c2d/build/latest?branch=master">
        <img src="https://dashboard.buddybuild.com/api/statusImage?appID=58ff19a79a06210001d14c2d&branch=master&build=latest" />
    </a>
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
    <a href="https://twitter.com/johnsundell">
        <img src="https://img.shields.io/badge/contact-@johnsundell-blue.svg?style=flat" alt="Twitter: @johnsundell" />
    </a>
</p>

Welcome to **Marathon**, a command line tool that makes it easy to write, run and manage your Swift scripts. It's powered by the [Swift Package Manager](https://github.com/apple/swift-package-manager) and requires no modification to your existing scripts or dependency packages.

## Features

🐣 Create scripts
```
$ marathon create helloWorld "import Foundation; print(\"Hello world\")"
```

🏃‍♀️ Run scripts
```
$ marathon run helloWorld
> Hello world
```

📦 Hassle free dependency management. Simply add a package...
```
$ marathon add git@github.com:JohnSundell/Files.git
```

...and use it without any additional work
```swift
import Files

for file in try Folder(path: "MyFolder").files {
    print(file.name)
}
```

🚀 Update all of your scripting dependencies with a single call
```
$ marathon update
```

⚒ Edit, run & debug your scripts using Xcode...
```
$ marathon edit helloWorld
```

...or in your favorite text editor
```
$ marathon edit helloWorld --no-xcode
```

💻 Install scripts as binaries and run them independently from anywhere...
```
$ marathon install helloWorld
$ helloWorld
> Hello world
```

...you can even install remote scripts (+ their dependencies) from a URL:
```
$ marathon install https://raw.githubusercontent.com/JohnSundell/Marathon-Examples/master/AddSuffix/addSuffix.swift
$ cd myImages
$ addSuffix "@2x"
> Added suffix "@2x" to 15 files
```

👪 Share your scripts with your team and automatically install their dependencies:
```
$ echo "git@github.com:JohnSundell/Files.git" > Marathonfile
$ marathon run mySharedScript
```

## Installing

### On macOS

Using Make:
```
$ git clone git@github.com:JohnSundell/Marathon.git
$ cd Marathon
$ make
```

Using the Swift Package Manager:
```
$ git clone git@github.com:JohnSundell/Marathon.git
$ cd Marathon
$ swift build -c release -Xswiftc -static-stdlib
$ cp -f .build/release/Marathon /usr/local/bin/marathon
```

### On Linux

```
$ git clone git@github.com:JohnSundell/Marathon.git
$ cd Marathon
$ swift build -c release
$ cp -f .build/release/Marathon /usr/local/bin/marathon
```

If you encounter a permissions failure while installing, you may need to prepend `sudo` to the commands.
To update Marathon, simply repeat any of the above two series of commands, except cloning the repo.

## Requirements

Marathon requires the following to be installed on your system:

- Swift 3.1 or later (bundled with Xcode 8.3 or later)
- Git
- Xcode (if you want to edit scripts using it)

## Examples

Check out [this repository](https://github.com/JohnSundell/Marathon-Examples) for a few example Swift scripts that you can run using Marathon.

## Using a Marathonfile

To easily define dependencies for a script in a declarative way, you can create a `Marathonfile` in the same folder as your script. This file is simply a *new line separated list* of URLs pointing to either:

- The URL to a git repository of a local or remote package to install before running your script.
- The path to another script that should be linked to your script before running it.

 By using a `Marathonfile` you can ensure that the required dependencies will be installed when sharing your script with team members, friends or the wider community.

Here is an example of a `Marathonfile`:
```
git@github.com:JohnSundell/Files.git
git@github.com:JohnSundell/Unbox.git
git@github.com:JohnSundell/Wrap.git
~/packages/MyPackage
otherScript.swift
```

## Help, feedback or suggestions?

- Run `$ marathon help` to display help for the tool itself or for any specific command.
- Append `--verbose` to any command to make Marathon output everything it's doing, for debugging purposes.
- [Open an issue](https://github.com/JohnSundell/Marathon/issues/new) if you need help, if you found a bug, or if you want to discuss a feature request.
- [Open a PR](https://github.com/JohnSundell/Marathon/pull/new/master) if you want to make some change to Marathon.
- Contact [@johnsundell on Twitter](https://twitter.com/johnsundell) for discussions, news & announcements about Marathon.
