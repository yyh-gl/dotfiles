#!/bin/zsh

# Reverse of bin/base.sh and bin/link.sh.
# Copies current $HOME configs back into the dotfiles repository,
# so they can be reviewed via `git diff` and committed.

set -eu

DOTFILES="$HOME/workspaces/github.com/yyh-gl/dotfiles"
PRIVATE_DOTFILES="$DOTFILES/depended-repositories/dotfiles-private"

# --- Counterpart of bin/base.sh ---

## Zsh configs
cp -f "$HOME"/.zlogin     "$DOTFILES"/.zlogin
cp -f "$HOME"/.zlogout    "$DOTFILES"/.zlogout
cp -f "$HOME"/.zpreztorc  "$DOTFILES"/.zpreztorc
cp -f "$HOME"/.zprofile   "$DOTFILES"/.zprofile
cp -f "$HOME"/.zshenv     "$DOTFILES"/.zshenv
cp -f "$HOME"/.zshrc      "$DOTFILES"/.zshrc

## SSH (private)
cp -rf "$HOME"/.ssh/. "$PRIVATE_DOTFILES"/.ssh/

## Emacs (tracked files only)
cp -f  "$HOME"/.emacs.d/init.el "$DOTFILES"/.emacs.d/init.el
cp -rf "$HOME"/.emacs.d/lang    "$DOTFILES"/.emacs.d/

# --- Counterpart of bin/link.sh ---

## .config
cp -rf "$HOME"/.config/karabiner/* "$DOTFILES"/.karabiner/
cp -f  "$HOME"/.config/gh/config.yml "$DOTFILES"/.gh-config.yml
cp -rf "$HOME"/.config/git/* "$DOTFILES"/.git-config/
cp -f  "$HOME"/.config/ghostty/config "$DOTFILES"/ghostty-config

## Claude
cp -f  "$HOME"/.claude/settings.json    "$DOTFILES"/.claude/settings.json
cp -f  "$HOME"/.claude/statusline.sh    "$DOTFILES"/.claude/statusline.sh
cp -f  "$HOME"/.claude/keybindings.json "$DOTFILES"/.claude/keybindings.json
cp -rf "$HOME"/.claude/rules   "$DOTFILES"/.claude/
cp -rf "$HOME"/.claude/agents  "$DOTFILES"/.claude/
cp -rf "$HOME"/.claude/skills  "$DOTFILES"/.claude/
cp -rf "$HOME"/.claude/hooks   "$DOTFILES"/.claude/

## k8s (private)
cp -f "$HOME"/.kube/config "$PRIVATE_DOTFILES"/.kube-config

## AWS (private)
cp -rf "$HOME"/.aws/. "$PRIVATE_DOTFILES"/.aws/

## k1LoW/deck (private)
cp -f "$HOME"/.local/share/deck/credentials.json "$PRIVATE_DOTFILES"/.deck/credentials.json

echo "Snapshot complete. Review changes with 'git diff'."
