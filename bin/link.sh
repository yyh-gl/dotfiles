#!/bin/zsh

# Depend on init.sh

DOTFILES="$HOME/workspaces/github.com/yyh-gl/dotfiles"

# Copy config files
## .config
mkdir -p "$HOME"/.config
mkdir -p "$HOME"/workspaces
cp -rf "$DOTFILES"/.karabiner/. "$HOME"/.config/karabiner
mkdir -p "$HOME"/.config/gh
cp -f "$DOTFILES"/.gh-config.yml "$HOME"/.config/gh/config.yml
mkdir -p "$HOME"/.config/git
cp -rf "$DOTFILES"/.git-config/. "$HOME"/.config/git
mkdir -p "$HOME"/.config/ghostty
cp -f "$DOTFILES"/ghostty-config "$HOME"/.config/ghostty/config

## Claude
mkdir -p "$HOME"/.claude
cp -f "$DOTFILES"/.claude/settings.json "$HOME"/.claude/settings.json
cp -f "$DOTFILES"/.claude/statusline.sh "$HOME"/.claude/statusline.sh
cp -f "$DOTFILES"/.claude/keybindings.json "$HOME"/.claude/keybindings.json
cp -rf "$DOTFILES"/.claude/rules "$HOME"/.claude/
cp -rf "$DOTFILES"/.claude/agents "$HOME"/.claude/
cp -rf "$DOTFILES"/.claude/skills "$HOME"/.claude/
cp -rf "$DOTFILES"/.claude/hooks "$HOME"/.claude/

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
