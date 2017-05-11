#!/usr/bin/env bash

swift package generate-xcodeproj

# Install swiftlint if necessary
if ! which swiftlint >/dev/null; then
    brew install swiftlint
fi

# Run Swiftlint
echo "Here comes the output of Swiftlint"
swiftlint
