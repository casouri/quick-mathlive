ifeq ($(OS), Windows_NT)
	electron_dir = somewhere
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S), Linux)
		electron_dir = somewhere
	endif
	ifeq ($(UNAME_S), Darwin)
		electron_dir = Electron.app/Contents/Resources/app
	endif
endif

$(electron_dir):
	mkdir $(electron_dir)

.PHONY: install

install: $(electron_dir)
	cp index.html $(electron_dir)
	cp main.js $(electron_dir)
	cp script.js $(electron_dir)
	cp package.json $(electron_dir)
	cp style.css $(electron_dir)
	cp -r node_modules $(electron_dir)
	cp -r mathlive $(electron_dir)
