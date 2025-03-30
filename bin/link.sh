#!/bin/zsh

# Depend on init.sh

# Link to config
## Zsh
ln -s ./zlogin $HOME/
ln -s ./zlogout $HOME/
ln -s ./zpreztorc $HOME/
ln -s ./zprofile $HOME/
ln -s ./zshenv $HOME/
ln -s ./zshrc $HOME/
mkdir $HOME/.zprezto
ln -s ./depended-repositories/prezto/init.zsh $HOME/.zprezto

## .config
mkdir -p $HOME/.config
mkdir -p $HOME/workspaces
ln -s $HOME/workspaces/config/dotfiles/.karabiner $HOME/.config/karabiner
mkdir -p $HOME/.config/gh
ln -s $HOME/workspaces/config/dotfiles/.gh-config.yml $HOME/.config/gh/config.yml
ln -s $HOME/workspaces/config/dotfiles/.git-config $HOME/.config/git

## k8s
mkdir $HOME/.kube
ln -s $HOME/workspaces/config/dotfiles-pirvate/.kube-config $HOME/.kube/config

## AWS
ln -s $HOME/workspaces/config/dotfiles-private/.aws $HOME/

## Google Drive
ln -s $HOME/GoogleDrive/01_Personal/00_Engineering $HOME/Desktop/hobby/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife $HOME/Desktop/hobby/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife/99_Pictures/00_Profile $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife/99_Pictures/01_Wallpapers $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife/99_Pictures/02_Geeks $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife/99_Pictures/03_IconsForMac $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife/99_Pictures/04_SlackStamps $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife/99_Pictures/05_Works $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_Personal/01_CasualLife/99_Pictures/99_Others $HOME/Pictures/
