#!/bin/zsh

# Depend on init.sh

brew bundle --file=.Brewfile-base

if [ $MODE = "hobby" ]; then
  brew bundle --file=.Brewfile-hobby
fi
