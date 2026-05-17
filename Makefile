include .env.public

.DEFAULT_GOAL := help
.PHONY: help
help: # Help me
	@echo "Let's 'make build'"

.PHONY: init
init: # Initialize the environment
	./bin/init.sh
	./bin/install-nix.sh

.PHONY: apply
apply: # Apply config files to HOME
	./bin/base.sh
	./bin/link.sh

.PHONY: snapshot
snapshot: # Snapshot config files from HOME back to dotfiles
	./bin/snapshot.sh

.PHONY: build
build: # Setup my macOS
	@echo "Setup mode: ${MODE}"
	./bin/base.sh
	./bin/brew.sh
	./bin/gh.sh
	./bin/link.sh
	./bin/mas.sh
	./bin/manual.sh

.PHONY: nix-switch
nix-switch: # Apply Nix configuration
	sudo darwin-rebuild switch --flake .#yyh-gl-mac

.PHONY: nix-update
nix-update: # Update Nix flake inputs
	nix flake update
