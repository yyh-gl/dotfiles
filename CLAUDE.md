# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS dotfiles repository. Manages shell configs, tool settings, and setup scripts via file copies to `$HOME`.

## Key Commands

```sh
# Initial setup (run once on a fresh machine)
make init       # Install Homebrew, Git, Xcode, clone repo, install Nix

# Full setup
make build      # Run all setup scripts sequentially

# Partial builds
make build-go   # Install Go (version from .env.public)
make build-jvm  # Install JVM (version from .env.public)

# Apply config files to $HOME (without full build)
make apply      # Run base.sh + link.sh only

# Sync $HOME configs back to dotfiles
make snapshot   # Reverse of apply — copy $HOME configs back for git diff/commit

# Nix
make nix-switch # Apply Nix configuration (darwin-rebuild switch)
make nix-update # Update flake.lock to latest inputs
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

### Nix Setup

`nix/` ディレクトリで nix-darwin + home-manager による宣言的管理を段階的に導入中。

```
nix/
├── flake.nix          # entrypoint (nixpkgs-unstable + nix-darwin + home-manager)
├── darwin/
│   └── default.nix    # nix-darwin設定 (system.defaults, Homebrew管理など)
└── home/
    └── default.nix    # home-manager設定 (dotfile管理, programs.zshなど)
```

**初回セットアップ手順:**

```sh
# 1. Nixをインストール (make init に含まれているが、単独実行も可)
./bin/install-nix.sh

# 2. /etc/zshrc と /etc/bashrc を削除 (nix-darwinが管理するため)
sudo rm /etc/zshrc /etc/bashrc

# 3. シェルを再起動後、初回ビルド (nix-darwin未インストールの場合)
git add nix/   # Nixはgit追跡ファイルのみ読み込む
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ./nix#yyh-gl-mac

# 4. 以降は make nix-switch で適用
make nix-switch
```

**注意事項:**
- `nix/` 配下のファイルを変更したら `git add` してから `make nix-switch` を実行する（未追跡ファイルはNixに読み込まれない）
- `darwin-rebuild switch` はシステム設定変更のため `sudo` が必要
- `services.nix-daemon.enable` は最新nix-darwinで廃止済み（`nix.enable` が自動管理）

### Build Mode

`MODE` env var (set in `.env.public`) controls conditional logic in scripts:
- `hobby` — Links personal Google Drive directories to `$HOME/Desktop/hobby` and `$HOME/Pictures`
- `work` — Creates `$HOME/Desktop/work` directory
