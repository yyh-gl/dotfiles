include .env

.DEFAULT_GOAL := help
.PHONY: help
help: # Help me
	@echo "Let's 'make build'"

.PHONY: build
build: # Setup my macOS
	@echo "Setup mode: ${MODE}"
	./bin/init.sh
	./bin/brew.sh
	./bin/link.sh
	./bin/defaults.sh
	./bin/mas.sh
	make build-go
	make build-jvm
	./bin/manual.sh


.PHONY: build-go
build-go: # Setup for Go
	GO_VERSION=${GO_VERSION} ./bin/go.sh

.PHONY: build-jvm
build-jvm: # Setup for JVM
	JVM_VERSION=${JVM_VERSION} ./bin/jvm.sh
