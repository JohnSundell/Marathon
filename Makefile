INSTALL_PATH = /usr/local/bin/marathon

install:
	swift package update
	swift build -c release
	cp -f .build/release/Marathon $(INSTALL_PATH)

uninstall:
	rm -f $(INSTALL_PATH)
