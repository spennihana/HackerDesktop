# literal space
space :=
space +=

# Decide OS-specific questions
# jar-file seperator
SEP = :
ifeq ($(OS),Windows_NT)
  SEP = ;
endif

DIR := ${CURDIR}

SRC = src/main/kt
kt = $(wildcard $(SRC)/com/hnd/*kt $(SRC)/com/hnd/*/*kt)
main_classes = $(patsubst $(SRC)/%kt,build/classes/main/%class,$(kt))
libs = $(wildcard lib/*jar)
jars = $(subst $(space),$(SEP),$(libs))

default: elm build/hnd.jar

jar: build/hnd.jar

elm: web/src/elm.js
web/src/elm.js: $(wildcard src/main/elm/gui/*elm src/main/elm/gui/*/*elm src/main/elm/gui/Native/*js)
	@echo "compiling " $@ " because " $?
	@cd src/main/elm && elm-package install -y && elm make ./gui/HackerDesktop.elm --output ../../../web/src/elm.js;
	@cd ../../../

$(main_classes): build/classes/main/%class: $(SRC)/%kt
	@echo "compiling " $@ " because " $?
	@[ -d build/classes/main ] || mkdir -p build/classes/main
	@echo 'kotlinc -cp "build/classes/main$(SEP)$(jars)" $(kt)'
	@kotlinc -cp "build/classes/main$(SEP)$(jars)" $(SRC) -d build/classes/main $(kt)

build/hnd.jar: $(main_classes)
	@echo " jarring " $@ " because " $?
	@[ -d build ] || mkdir -p build
	@jar -cf build/hnd.jar -C build/classes/main .

init: web/package.json web/node_modules

package: clean init elm jars $(wildcard web/src/*js) 
	@echo "building " $@ " because " $?
	@(cd web && electron-forge package && mv out ../)

dist: clean init elm jars $(wildcard web/src/*js)
	@echo "creating installer"
	@(cd web && electron-forge make && mv out ../)
	@mkdir dist
	@mv out/make/*dmg dist/HackerDesktop.dmg

jars: web/src/resources/hnd.jar
web/src/resources/hnd.jar: build/hnd.jar
	@echo "creating jars in resources "
	@[ -d web/src/resources/jars ] || mkdir -p web/src/resources/jars
	@cp lib/*jar web/src/resources/jars
	@cp build/hnd.jar web/src/resources/jars

web/package.json:
	@echo "updating package.json"
	@echo "path = ${DIR}"
	@sed -e"s|@web@|"${DIR}/web"|" web/package.json.in > web/package.json

web/node_modules:
	@echo "getting node_modules"
	@rm -rf tmpnm
	@mkdir tmpnm
	@(cd tmpnm && electron-forge init && mv node_modules ../web/node_modules)
	@rm -rf tmpnm
	@(cd web && npm i --save winston)
	@(cd web && npm i --save winston-electron)

.PHONY: clean
clean:
	rm -rf web/src/elm.js
	rm -rf out
	rm -rf build
	rm -rf dist
	rm -rf tmpnm
	rm -rf web/package.json
	rm -rf web/src/resources/jars
