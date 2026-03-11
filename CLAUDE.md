# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS dotfiles repository. Manages shell configs, tool settings, and setup scripts via symlinks to `$HOME`.

## Key Commands

```sh
# Initial setup (run once on a fresh machine)
make init       # Install Homebrew, Git, Xcode, clone repo

# Full setup
make build      # Run all setup scripts sequentially

# Partial builds
make build-go   # Install Go (version from .env.public)
make build-jvm  # Install JVM (version from .env.public)
```

## Architecture

### Setup Flow

`bin/init.sh` → `make build` → runs these scripts in order:
1. `bin/base.sh` — Edit `.env.public`, link Zsh configs, setup SSH via anyenv/Emacs symlinks
2. `bin/brew.sh` — Install Homebrew packages from `.brewfile-base` (and `.brewfile-hobby` if `MODE=hobby`)
3. `bin/gh.sh` — GitHub CLI setup
4. `bin/link.sh` — Create all symlinks (tool configs, Claude settings, k8s, AWS, Google Drive)
5. `bin/defaults.sh` — Apply macOS system defaults from `.defaults/`
6. `bin/mas.sh` — Install Mac App Store apps
7. `bin/go.sh` / `bin/jvm.sh` — Install language runtimes
8. `bin/manual.sh` — Final manual steps

### Symlink Strategy

All config files live here and are symlinked into `$HOME` or `$HOME/.config/`. Key links created by `bin/link.sh`:
- `.zshrc`, `.zshenv`, `.zprofile`, etc. → `$HOME/`
- `.claude/settings.json`, `.claude/rules`, `.claude/agents`, `.claude/skills`, `.claude/hooks` → `$HOME/.claude/`
- `.karabiner` → `$HOME/.config/karabiner`
- `.gh-config.yml` → `$HOME/.config/gh/config.yml`
- `.git-config` → `$HOME/.config/git`
- `ghostty-config` → `$HOME/.config/ghostty/config`

### Submodules (`depended-repositories/`)

| Submodule | Purpose |
|-----------|---------|
| `dotfiles-private` | Private configs (SSH, AWS, kubeconfig, credentials) |
| `go-installer` | Go version installer script |
| `prezto` | Zsh framework |
| `scripts` | Utility scripts |

### Build Mode

`MODE` env var (set in `.env.public`) controls conditional logic in scripts:
- `hobby` — Links personal Google Drive directories
- `work` — Links work-specific directories
