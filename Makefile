include .env

.DEFAULT_GOAL := help
.PHONY: help
help: # Help me
	@echo "Let's 'make build'"

.PHONY: build
build: # Setup my Mac
	./bin/init.sh
	./bin/brew.sh
	./bin/link.sh
	./bin/defaults.sh
	./bin/mas.sh
	./bin/manual.sh
