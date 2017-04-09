INSTALL_PATH = /usr/local/bin/marathon

install:
	swift package --enable-prefetching update
	swift build --enable-prefetching -c release -Xswiftc -static-stdlib
	cp -f .build/release/Marathon $(INSTALL_PATH)

test:
	mv Package.swift .Package.swift && cp .Package.test.swift Package.swift
	swift build --clean && swift build && swift test
	mv .Package.swift Package.swift

uninstall:
	rm -f $(INSTALL_PATH)
