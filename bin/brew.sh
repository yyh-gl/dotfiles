#!/bin/zsh

# Depend on init.sh

brew bundle --file=.brewfile-base

if [ "$MODE" = "hobby" ]; then
  brew bundle --file=.brewfile-hobby
fi
