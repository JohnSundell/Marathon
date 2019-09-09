**⚠️ DEPRECATED**: Marathon is now deprecated in favor of using the Swift Package Manager directly. It's recommended to migrate your scripts as soon as possible, since future Xcode/macOS versions may break compatibility. See [this issue](https://github.com/JohnSundell/Marathon/issues/208) for more info.

<p align="center">
    <img src="Logo.png" width="480" max-width="90%" alt="Marathon" />
</p>

<p align="center">
    <a href="https://dashboard.buddybuild.com/apps/58ff19a79a06210001d14c2d/build/latest?branch=master">
        <img src="https://dashboard.buddybuild.com/api/statusImage?appID=58ff19a79a06210001d14c2d&branch=master&build=latest" />
    <a href="https://travis-ci.org/JohnSundell/Marathon/branches">
        <img src="https://img.shields.io/travis/JohnSundell/Marathon/master.svg" alt="Travis status" />
    </a>
    <img src="https://img.shields.io/badge/Swift-4.2-orange.svg" />
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
$ marathon add https://github.com/JohnSundell/Files.git
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

🌍 Run remote scripts directly from a Git repository...
```
$ marathon run https://github.com/johnsundell/testdrive.git
```

...using only a GitHub username & repository name:
```
$ marathon run johnsundell/testdrive
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

...or from a GitHub repository:
```
$ marathon install johnsundell/testdrive
$ testdrive
```

👪 Share your scripts with your team and automatically install their dependencies...
```swift
import Files // marathon:https://github.com/JohnSundell/Files.git

print(Folder.current.path)
```

...or specify your dependencies using a `Marathonfile`:
```
$ echo "https://github.com/JohnSundell/Files.git" > Marathonfile
```

## Installing

### On macOS

Using Make **(recommended)**:
```sh
$ git clone https://github.com/JohnSundell/Marathon.git
$ cd Marathon
$ make
```

Using the Swift Package Manager:
```sh
$ git clone https://github.com/JohnSundell/Marathon.git
$ cd Marathon
$ swift build -c release -Xswiftc -static-stdlib
$ cp -f .build/release/Marathon /usr/local/bin/marathon
```

Using [Mint](https://github.com/yonaskolb/mint):
```sh
$ mint install JohnSundell/Marathon
```

Using Homebrew **(not recommended, due to slow update cycle)**:
```sh
brew install marathon-swift
```

### On Linux

```sh
$ git clone https://github.com/JohnSundell/Marathon.git
$ cd Marathon
$ swift build -c release
$ cp -f .build/release/Marathon /usr/local/bin/marathon
```

If you encounter a permissions failure while installing, you may need to prepend `sudo` to the commands.
To update Marathon, simply repeat any of the above two series of commands, except cloning the repo.

## Requirements

Marathon requires the following to be installed on your system:

- Swift 4.1 or later (bundled with Xcode 9.3 or later)
- Git
- Xcode (if you want to edit scripts using it)

## Examples

Check out [this repository](https://github.com/JohnSundell/Marathon-Examples) for a few example Swift scripts that you can run using Marathon.

## Specifying dependencies inline

Scripting usually involves using 3rd party frameworks to get your job done, and Marathon provides an easy way to define such dependencies right when you are importing them in your script, using a simple comment syntax:

```swift
import Files // marathon:https://github.com/JohnSundell/Files.git
import Unbox // marathon:https://github.com/JohnSundell/Unbox.git
```

Specifying your dependencies ensures that they will always be installed by Marathon before your script is run, edited or installed - making it super easy to share scripts with your friends, team or the wider community. All you have to do is share the script file, and Marathon takes care of the rest!

## Using a Marathonfile

If you prefer to keep your dependency declarations separate, you can create a `Marathonfile` in the same folder as your script. This file is simply a *new line separated list* of URLs pointing to either:

- The URL to a git repository of a local or remote package to install before running your script.
- The path to another script that should be linked to your script before running it.

Here is an example of a `Marathonfile`:
```
https://github.com/JohnSundell/Files.git
https://github.com/JohnSundell/Unbox.git
https://github.com/JohnSundell/Wrap.git
~/packages/MyPackage
otherScript.swift
```

## Shell autocomplete

Marathon includes autocomplete for the `zsh` and `fish` shells (PRs adding support for other shells is more than welcome!). To enable it, do the following:

+ `zsh`:
    - Add the line `fpath=(~/.marathon/ShellAutocomplete/zsh $fpath)` to your `~/.zshrc` file.
    - Add the line `autoload -Uz compinit && compinit -i` to your `~/.zshrc` file if it doesn't already contain it.
    - Restart your terminal.

+ `fish`:
    - `cp -f ~/.marathon/ShellAutocomplete/fish/marathon.fish ~/.config/fish/completions`

You can now type `marathon r` and have it be autocompleted to `marathon run` 🎉

## Help, feedback or suggestions?

- Run `$ marathon help` to display help for the tool itself or for any specific command.
- Append `--verbose` to any command to make Marathon output everything it's doing, for debugging purposes.
- [Open an issue](https://github.com/JohnSundell/Marathon/issues/new) if you need help, if you found a bug, or if you want to discuss a feature request.
- [Open a PR](https://github.com/JohnSundell/Marathon/pull/new/master) if you want to make some change to Marathon.
- Contact [@johnsundell on Twitter](https://twitter.com/johnsundell) for discussions, news & announcements about Marathon.
