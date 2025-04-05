#!/bin/zsh

# Depend on init.sh

# Link to config
## .config
mkdir -p "$HOME"/.config
mkdir -p "$HOME"/workspaces
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.karabiner "$HOME"/.config/karabiner
mkdir -p "$HOME"/.config/gh
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.gh-config.yml "$HOME"/.config/gh/config.yml
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.git-config "$HOME"/.config/git

## k8s
mkdir "$HOME"/.kube
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles-pirvate/.kube-config "$HOME"/.kube/config

## AWS
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles-private/.aws "$HOME"

## Google Drive
read -r STDIN'?Please setup Google Drive. [ENTER]: '
if [ "$MODE" = "hobby" ]; then
  mkdir "$HOME"/Desktop/hobby
  ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/00_Engineering "$HOME"/Desktop/hobby
  ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife "$HOME"/Desktop/hobby
elif [ "$MODE" = "work" ]; then
  mkdir "$HOME"/Desktop/work
fi
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/00_Profile "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/01_Wallpapers "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/02_Geeks "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/03_IconsForMac "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/04_SlackStamps "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/05_Works "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/99_Others "$HOME"/Pictures
