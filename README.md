<p align="center">
    <img src="Logo.png" width="480" max-width="90%" alt="Marathon" />
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

📦 Add dependencies...
```
$ marathon add git@github.com:JohnSundell/Files.git
```

...and use them without any additional work
```swift
import Files

for file in try Folder(path: "MyFolder").files {
    print(file.name)
}
```

🚀 Hassle free dependency management. Just a simple call to update all of them
```
$ marathon update
```

⚒ Edit your scripts using Xcode...
```
$ marathon edit helloWorld
```

...or in your favorite text editor:
```
$ marathon edit helloWorld -no-xcode
```

👪 Share your scripts with your team and automatically install their dependencies:
```
$ echo "git@github.com:JohnSundell/Files.git" > Marathonfile
$ marathon run mySharedScript
```
