#!/bin/zsh

# Depend on init.sh

DOTFILES="$HOME/workspaces/github.com/yyh-gl/dotfiles"

# Copy config files
## .config
mkdir -p "$HOME"/.config
mkdir -p "$HOME"/workspaces
## k8s
mkdir -p "$HOME"/.kube
cp -f "$DOTFILES"/depended-repositories/dotfiles-private/.kube-config "$HOME"/.kube/config

## AWS
cp -rf "$DOTFILES"/depended-repositories/dotfiles-private/.aws "$HOME"

## k1LoW/deck
mkdir -p "$HOME"/.local/share/deck
cp -f "$DOTFILES"/depended-repositories/dotfiles-private/.deck/credentials.json "$HOME"/.local/share/deck/
