.DEFAULT_GOAL := help
.PHONY: help
help: # Help me
	@echo "Let's 'make build-hobby' or 'make build-work'"

.PHONY: init
init: # Initialize the environment
	./bin/init.sh
	./bin/install-nix.sh

.PHONY: build-hobby
build-hobby: # Setup my macOS (hobby mode)
	./bin/manual.sh
	$(MAKE) nix-apply-hobby

.PHONY: build-work
build-work: # Setup my macOS (work mode)
	./bin/manual.sh
	$(MAKE) nix-apply-work

.PHONY: nix-apply-hobby
nix-apply-hobby: # Apply Nix configuration (hobby mode)
	nix flake update
	sudo darwin-rebuild switch --flake .#yyh-gl-mac-hobby

.PHONY: nix-apply-work
nix-apply-work: # Apply Nix configuration (work mode)
	nix flake update
	sudo darwin-rebuild switch --flake .#yyh-gl-mac-work

.PHONY: nix-cleanup
nix-cleanup: # Cleanup Nix
	sudo nix-collect-garbage -d
