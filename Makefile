.PHONY: build install uninstall check clean

build:
	./scripts/build-app.sh

install:
	./install.sh

uninstall:
	./uninstall.sh

check:
	./scripts/check.sh

clean:
	rm -rf .build dist *.Rcheck *.tar.gz
