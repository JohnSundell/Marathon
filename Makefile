INSTALL_PATH = /usr/local/bin/marathon

install:
	swift package --enable-prefetching update
	swift build --enable-prefetching -c release -Xswiftc -static-stdlib
	cp -f .build/release/Marathon $(INSTALL_PATH)

uninstall:
	rm -f $(INSTALL_PATH)
