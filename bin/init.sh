#!/bin/zsh

# This script is the first step of setup

# Install Xcode
sudo rm -rf /Library/Developer/CommandLineTools
sudo xcode-select --install
read -r STDIN'?Please setup Xcode. If you complete to setup. -> [ENTER]: '
sudo xcodebuild -license accept

# Setup for Zsh
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zlogin "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zlogout "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zpreztorc "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zprofile "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zshenv "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zshrc "$HOME"
mkdir "$HOME"/.zprezto
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/depended-repositories/prezto/init.zsh "$HOME"/.zprezto
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/depended-repositories/prezto/modules "$HOME"/.zprezto

# Setup for SSH
read -r STDIN'?Please setup 1Password. If you complete to setup. -> [ENTER]: '
rm -rf "$HOME"/.ssh
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/depended-repositories/dotfiles-private/.ssh "$HOME"
