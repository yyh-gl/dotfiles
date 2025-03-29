#!/bin/zsh

# Depend on init.sh

# Link to config
## Zsh
git clone https://github.com/sorin-ionescu/prezto
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
