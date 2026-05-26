.DEFAULT_GOAL := help
.PHONY: help
help: # Help me
	@echo "Let's 'make build-hobby' or 'make build-work'"

.PHONY: init
init: # Initialize the environment
	./bin/init.sh
	./bin/install-nix.sh
	sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#yyh-gl-mac-hobby

.PHONY: build-hobby
build-hobby: # Setup my macOS (hobby mode)
	$(MAKE) nix-apply-hobby
	./bin/manual.sh

.PHONY: build-work
build-work: # Setup my macOS (work mode)
	$(MAKE) nix-apply-work
	./bin/manual.sh

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
