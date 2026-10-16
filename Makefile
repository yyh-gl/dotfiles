.DEFAULT_GOAL := help
NIX := /nix/var/nix/profiles/default/bin/nix

.PHONY: help
help: # Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*# ' $(MAKEFILE_LIST) | awk -F':.*# ' '{printf "  %-16s %s\n", $$1, $$2}'

# 初回セットアップ。事前にXcode Command Line Toolsを入れ、リポジトリをHTTPSでcloneしておくこと（README参照）
.PHONY: init-hobby
init-hobby: # First-time setup (hobby mode)
	$(MAKE) _init MODE=hobby

.PHONY: init-work
init-work: # First-time setup (work mode)
	$(MAKE) _init MODE=work

.PHONY: _init
_init:
	./bin/init.sh
	./bin/install-nix.sh
	@# nix-darwinは管理対象の/etc/zshrc・/etc/bashrcが既にあるとactivationを中断するため退避する
	@for f in zshrc bashrc; do \
	  if [ -e /etc/$$f ] && [ ! -L /etc/$$f ]; then sudo mv /etc/$$f /etc/$$f.before-nix-darwin; fi; \
	done
	@# makeのシェルにはインストール直後のNixのPATHが通っていないため、フルパスで呼ぶ
	sudo $(NIX) --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#yyh-gl-mac-$(MODE)

.PHONY: setup-hooks
setup-hooks: # Set up local git hooks for this repo
	git config core.hooksPath hooks

.PHONY: build-hobby
build-hobby: setup-hooks # Setup my macOS (hobby mode)
	$(MAKE) nix-apply-hobby
	./bin/manual.sh

.PHONY: build-work
build-work: setup-hooks # Setup my macOS (work mode)
	$(MAKE) nix-apply-work
	./bin/manual.sh

.PHONY: nix-apply-hobby
nix-apply-hobby: # Apply Nix configuration (hobby mode)
	sudo darwin-rebuild switch --flake .#yyh-gl-mac-hobby

.PHONY: nix-apply-work
nix-apply-work: # Apply Nix configuration (work mode)
	sudo darwin-rebuild switch --flake .#yyh-gl-mac-work

.PHONY: nix-update
nix-update: # Update tools on Nix
	nix flake update

.PHONY: brew-upgrade
brew-upgrade: # Update Homebrew and upgrade formulae and casks
	brew update
	brew upgrade

.PHONY: nix-cleanup
nix-cleanup: # Cleanup Nix (keep generations from the last 14 days for rollback)
	sudo nix-collect-garbage --delete-older-than 14d

.PHONY: gitleaks-all
gitleaks-all: # Scan git history for secrets
	gitleaks git -v --redact

.PHONY: gitleaks-staged
gitleaks-staged: # Scan staged changes for secrets
	gitleaks git -v --redact --staged

.PHONY: test-mods
test-mods: # Test and validate Claude Code mods
	bun test claude/mods/prompt-highlight-md/hooks/lib
	@for mod in claude/mods/*/; do \
	  echo "== $$mod"; \
	  claude plugin validate $$mod || exit 1; \
	  if ls $$mod/hooks/*.test.ts >/dev/null 2>&1; then claude plugin test $$mod || exit 1; fi; \
	done
