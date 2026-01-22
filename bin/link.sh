#!/bin/zsh

# Depend on init.sh

# Link to config
## .config
mkdir -p "$HOME"/.config
mkdir -p "$HOME"/workspaces
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.karabiner "$HOME"/.config/karabiner
mkdir -p "$HOME"/.config/gh
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.gh-config.yml "$HOME"/.config/gh/config.yml
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.git-config "$HOME"/.config/git
mkdir -p "$HOME"/.config/ghostty
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/ghostty-config "$HOME"/.config/ghostty/config

## Claude
mkdir -p "$HOME"/.claude
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.claude/settings.json "$HOME"/.claude/settings.json
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.claude/rules "$HOME"/.claude/rules
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.claude/agents "$HOME"/.claude/agents
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.claude/skills "$HOME"/.claude/skills

## k8s
mkdir -p "$HOME"/.kube
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.kube-config "$HOME"/.kube/config

## AWS
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.aws "$HOME"

## Google Drive
read -r STDIN'?Please setup Google Drive. [ENTER]: '
if [ "$MODE" = "hobby" ]; then
  mkdir -p "$HOME"/Desktop/hobby
  ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/00_Engineering "$HOME"/Desktop/hobby
  ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife "$HOME"/Desktop/hobby
elif [ "$MODE" = "work" ]; then
  mkdir -p "$HOME"/Desktop/work
fi
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/00_Profile "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/01_Wallpapers "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/02_Geeks "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/03_IconsForMac "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/04_SlackStamps "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/05_Works "$HOME"/Pictures
ln -s "$HOME"/Google\ Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/99_Others "$HOME"/Pictures

## k1LoW/deck
mkdir -p "$HOME"/.local/share/deck
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.deck/credentials.json "$HOME"/.local/share/deck/
