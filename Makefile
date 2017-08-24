INSTALL_PATH = /usr/local/bin/marathon

install: build install_bin

build:
	swift package --enable-prefetching update
	swift build --enable-prefetching -c release -Xswiftc -static-stdlib

install_bin:
	cp -f .build/release/Marathon $(INSTALL_PATH)

uninstall:
	rm -f $(INSTALL_PATH)
