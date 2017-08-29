PREFIX?=/usr/local
INSTALL_NAME = marathon

install: build install_bin

build:
	swift package --enable-prefetching update
	swift build --enable-prefetching -c release -Xswiftc -static-stdlib

install_bin:
	mkdir -p $(PREFIX)/bin
	mv .build/Release/Marathon .build/Release/$(INSTALL_NAME)
	install .build/Release/$(INSTALL_NAME) $(PREFIX)/bin

uninstall:
	rm -f $(INSTALL_PATH)
