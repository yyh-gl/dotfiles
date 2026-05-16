#!/bin/zsh

# Depend on init.sh
# taps/brews/casks are managed by nix-darwin (nix/darwin/homebrew.nix).
# VSCode extensions and gopls are managed by home-manager (nix/home/vscode.nix).

if [ "$MODE" = "hobby" ]; then
  brew bundle --file=.brewfile-hobby
fi
