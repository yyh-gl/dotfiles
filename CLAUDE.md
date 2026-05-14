# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS dotfiles repository. Manages shell configs, tool settings, and setup scripts via file copies to `$HOME`.

## Key Commands

```sh
# Initial setup (run once on a fresh machine)
make init       # Install Homebrew, Git, Xcode, clone repo

# Full setup
make build      # Run all setup scripts sequentially

# Partial builds
make build-go   # Install Go (version from .env.public)
make build-jvm  # Install JVM (version from .env.public)

# Apply config files to $HOME (without full build)
make apply      # Run base.sh + link.sh only

# Sync $HOME configs back to dotfiles
make snapshot   # Reverse of apply — copy $HOME configs back for git diff/commit
```

## Architecture

### Setup Flow

`bin/init.sh` → `make build` → runs these scripts in order:
1. `bin/base.sh` — Edit `.env.public`, copy Zsh configs, setup SSH, copy Emacs configs
2. `bin/brew.sh` — Install Homebrew packages from `.brewfile-base` (and `.brewfile-hobby` if `MODE=hobby`)
3. `bin/gh.sh` — GitHub CLI setup
4. `bin/link.sh` — Copy all tool configs (Claude settings, karabiner, k8s, AWS, Google Drive)
5. `bin/defaults.sh` — Apply macOS system defaults from `.defaults/`
6. `bin/mas.sh` — Install Mac App Store apps
7. `bin/go.sh` / `bin/jvm.sh` — Install language runtimes
8. `bin/manual.sh` — Final manual steps

### Config Copy Strategy

All config files live here and are **copied** (`cp`) into `$HOME` or `$HOME/.config/` by `bin/base.sh` and `bin/link.sh`. Only Google Drive directories use actual symlinks (`ln -sf`).

Key copies performed by `bin/base.sh`:
- `.zlogin`, `.zlogout`, `.zpreztorc`, `.zprofile`, `.zshenv`, `.zshrc` → `$HOME/`
- `depended-repositories/prezto/` → `$HOME/.zprezto/`
- `depended-repositories/dotfiles-private/.ssh/` → `$HOME/.ssh/`
- `.emacs.d/` → `$HOME/.emacs.d/`

Key copies performed by `bin/link.sh`:
- `.karabiner/` → `$HOME/.config/karabiner/`
- `.gh-config.yml` → `$HOME/.config/gh/config.yml`
- `.git-config/` → `$HOME/.config/git/`
- `ghostty-config` → `$HOME/.config/ghostty/config`
- `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/statusline.sh`, `.claude/keybindings.json` → `$HOME/.claude/`
- `.claude/rules`, `.claude/agents`, `.claude/skills`, `.claude/hooks` → `$HOME/.claude/`
- `depended-repositories/dotfiles-private/.kube-config` → `$HOME/.kube/config`
- `depended-repositories/dotfiles-private/.aws/` → `$HOME/.aws/`

To sync changes made directly in `$HOME` back to this repo, run `make snapshot`.

### Submodules (`depended-repositories/`)

| Submodule | Purpose |
|-----------|---------|
| `dotfiles-private` | Private configs (SSH, AWS, kubeconfig, credentials) |
| `go-installer` | Go version installer script |
| `prezto` | Zsh framework |
| `scripts` | Utility scripts |

### Build Mode

`MODE` env var (set in `.env.public`) controls conditional logic in scripts:
- `hobby` — Links personal Google Drive directories to `$HOME/Desktop/hobby` and `$HOME/Pictures`
- `work` — Creates `$HOME/Desktop/work` directory
