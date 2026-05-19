#!/bin/zsh

# Depend on init.sh

DOTFILES="$HOME/workspaces/github.com/yyh-gl/dotfiles"

mkdir -p "$HOME"/.config
mkdir -p "$HOME"/workspaces

# Secrets (.ssh/config, .aws/credentials, .kube/config, .deck/credentials.json) are
# now managed by Nix home-manager via 1Password (nix/home/secrets.nix).
# Run: make nix-switch-hobby or make nix-switch-work
