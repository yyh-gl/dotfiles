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


.PHONY: build-for-hobby
build-for-hobby: # Setup for hobby
	MODE=hobby make build

.PHONY: build-for-work
build-for-work: # Setup for work
	MODE=work make build
