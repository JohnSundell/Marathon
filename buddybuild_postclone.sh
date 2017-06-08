#!/usr/bin/env bash

swift package generate-xcodeproj

brew upgrade swiftlint

# if ! which swiftlint >/dev/null; then
#     brew install swiftlint
# fi

swiftlint
