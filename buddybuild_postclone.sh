#!/usr/bin/env bash

swift package generate-xcodeproj

if ! which swiftlint >/dev/null; then
    brew install swiftlint
fi

swiftlint
