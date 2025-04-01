#!/bin/zsh

# This script is the first step of setup

# Install base tools
## Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## Git
brew install git

## Xcode
xcode-select --install

# Setup for Zsh
ln -s "$HOME"/workspaces/github.com/yyh-gl/.zlogin "$HOME"/
ln -s "$HOME"/workspaces/github.com/yyh-gl/.zlogout "$HOME"/
ln -s "$HOME"/workspaces/github.com/yyh-gl/.zpreztorc "$HOME"/
ln -s "$HOME"/workspaces/github.com/yyh-gl/.zprofile "$HOME"/
ln -s "$HOME"/workspaces/github.com/yyh-gl/.zshenv "$HOME"/
ln -s "$HOME"/workspaces/github.com/yyh-gl/.zshrc "$HOME"/
mkdir "$HOME"/.zprezto
ln -s "$HOME"/workspaces/github.com/yyh-gl/depended-repositories/prezto/init.zsh "$HOME"/.zprezto/

# Setup for SSH
read -r STDIN'?Please setup 1Password. If you complete to setup. -> [ENTER]: '
rm -rf "$HOME"/.ssh
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.ssh "$HOME"/

## Setup for Google Drive
read -r STDIN'?Please setup Google Drive. If you complete to setup. -> [ENTER]: '
mkdir "$HOME"/Desktop/hobby
