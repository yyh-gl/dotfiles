#!/bin/zsh

# Depend on init.sh

DOTFILES="$HOME/workspaces/github.com/yyh-gl/dotfiles"

# Copy config files
## .config
mkdir -p "$HOME"/.config
mkdir -p "$HOME"/workspaces
mkdir -p "$HOME"/.config/gh
cp -f "$DOTFILES"/.gh-config.yml "$HOME"/.config/gh/config.yml

## k8s
mkdir -p "$HOME"/.kube
cp -f "$DOTFILES"/depended-repositories/dotfiles-private/.kube-config "$HOME"/.kube/config

## AWS
cp -rf "$DOTFILES"/depended-repositories/dotfiles-private/.aws "$HOME"

## Google Drive
read -r STDIN'?Please setup Google Drive. [ENTER]: '
if [ "$MODE" = "hobby" ]; then
  mkdir -p "$HOME"/Desktop/hobby
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/00_Engineering "$HOME"/Desktop/hobby
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife "$HOME"/Desktop/hobby
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/00_Profile "$HOME"/Pictures
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/01_Wallpapers "$HOME"/Pictures
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/02_Geeks "$HOME"/Pictures
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/03_IconsForMac "$HOME"/Pictures
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/04_SlackStamps "$HOME"/Pictures
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/05_Works "$HOME"/Pictures
  ln -sf "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/99_Others "$HOME"/Pictures
elif [ "$MODE" = "work" ]; then
  mkdir -p "$HOME"/Desktop/work
fi

## k1LoW/deck
mkdir -p "$HOME"/.local/share/deck
cp -f "$DOTFILES"/depended-repositories/dotfiles-private/.deck/credentials.json "$HOME"/.local/share/deck/
