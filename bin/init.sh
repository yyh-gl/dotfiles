#!/bin/zsh

# This script is the first step of setup

# Install base tools
## Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## Git
brew install git

## Xcode
xcode-select --install

# Setup of SSH
read -r STDIN'?Please setup 1Password. If you complete to setup. -> [ENTER]: '
rm -rf "$HOME"/.ssh
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.ssh "$HOME"/

## Google Drive
read -r STDIN'?Please setup Google Drive. If you complete to setup. -> [ENTER]: '
mkdir "$HOME"/Desktop/hobby
