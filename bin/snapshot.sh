#!/bin/zsh

# Reverse of bin/base.sh and bin/link.sh.
# Copies current $HOME configs back into the dotfiles repository,
# so they can be reviewed via `git diff` and committed.

set -eu

DOTFILES="$HOME/workspaces/github.com/yyh-gl/dotfiles"
PRIVATE_DOTFILES="$DOTFILES/depended-repositories/dotfiles-private"

# --- Counterpart of bin/base.sh ---

## SSH (private)
cp -rf "$HOME"/.ssh/. "$PRIVATE_DOTFILES"/.ssh/

# --- Counterpart of bin/link.sh ---

## .config
cp -rf "$HOME"/.config/karabiner/* "$DOTFILES"/.karabiner/
cp -f "$HOME"/.config/gh/config.yml "$DOTFILES"/.gh-config.yml

## Claude
cp -f "$HOME"/.claude/CLAUDE.md "$DOTFILES"/.claude/CLAUDE.md
cp -f "$HOME"/.claude/settings.json "$DOTFILES"/.claude/settings.json
cp -f "$HOME"/.claude/statusline.sh "$DOTFILES"/.claude/statusline.sh
cp -f "$HOME"/.claude/keybindings.json "$DOTFILES"/.claude/keybindings.json
cp -rf "$HOME"/.claude/rules "$DOTFILES"/.claude/
cp -rf "$HOME"/.claude/agents "$DOTFILES"/.claude/
cp -rf "$HOME"/.claude/skills "$DOTFILES"/.claude/
cp -rf "$HOME"/.claude/hooks "$DOTFILES"/.claude/

## k8s (private)
cp -f "$HOME"/.kube/config "$PRIVATE_DOTFILES"/.kube-config

## AWS (private)
cp -rf "$HOME"/.aws/. "$PRIVATE_DOTFILES"/.aws/

## k1LoW/deck (private)
cp -f "$HOME"/.local/share/deck/credentials.json "$PRIVATE_DOTFILES"/.deck/credentials.json

echo "Snapshot complete. Review changes with 'git diff'."
