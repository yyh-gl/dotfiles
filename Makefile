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
	./bin/base.sh
	./bin/link.sh
	./bin/manual.sh

.PHONY: nix-switch-hobby
nix-switch-hobby: # Apply Nix configuration (hobby mode)
	sudo darwin-rebuild switch --flake .#yyh-gl-mac-hobby

.PHONY: nix-switch-work
nix-switch-work: # Apply Nix configuration (work mode)
	sudo darwin-rebuild switch --flake .#yyh-gl-mac-work

.PHONY: nix-update
nix-update: # Update Nix flake inputs
	nix flake update
