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

# Apply config files to $HOME (without full build)
make apply      # Run base.sh + link.sh only

# Sync $HOME configs back to dotfiles
make snapshot   # Reverse of apply — copy $HOME configs back for git diff/commit

# Nix
make nix-switch-hobby # Apply Nix configuration (hobby mode)
make nix-switch-work  # Apply Nix configuration (work mode)
make nix-update       # Update flake.lock to latest inputs
```

## Architecture

### Setup Flow

`bin/init.sh` → `make build` → runs these scripts in order:
1. `bin/base.sh` — Copy Zsh configs, setup SSH, copy Emacs configs
2. `bin/link.sh` — Copy all tool configs (Claude settings, karabiner, k8s, AWS)
3. `bin/mas.sh` — Install Mac App Store apps
4. `bin/manual.sh` — Final manual steps

### Config Copy Strategy

All config files live here and are **copied** (`cp`) into `$HOME` or `$HOME/.config/` by `bin/base.sh` and `bin/link.sh`. Only Google Drive directories use actual symlinks (`ln -sf`).

Key copies performed by `bin/base.sh`:
- `.zlogin`, `.zlogout`, `.zpreztorc`, `.zprofile`, `.zshenv`, `.zshrc` → `$HOME/`
- `depended-repositories/prezto/` → `$HOME/.zprezto/`
- `depended-repositories/dotfiles-private/.ssh/` → `$HOME/.ssh/`
- `.emacs.d/` → `$HOME/.emacs.d/`

Key copies performed by `bin/link.sh`:
- `.karabiner/` → `$HOME/.config/karabiner/`
- `.git-config/` → `$HOME/.config/git/`
- `ghostty-config` → `$HOME/.config/ghostty/config`
- `claude/` → `$HOME/.claude/` (Nix home-manager manages via `nix/home/claude.nix`)
- `depended-repositories/dotfiles-private/.kube-config` → `$HOME/.kube/config`
- `depended-repositories/dotfiles-private/.aws/` → `$HOME/.aws/`

To sync changes made directly in `$HOME` back to this repo, run `make snapshot`.

### Submodules (`depended-repositories/`)

| Submodule | Purpose |
|-----------|---------|
| `dotfiles-private` | Private configs (SSH, AWS, kubeconfig, credentials) |
| `prezto` | Zsh framework |
| `scripts` | Utility scripts |

### Nix Setup

`nix/` ディレクトリで nix-darwin + home-manager による宣言的管理を段階的に導入中。

```
flake.nix              # entrypoint (nixpkgs-unstable + nix-darwin + home-manager)
flake.lock             # 依存ロックファイル
nix/
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
git add nix/ flake.nix flake.lock   # Nixはgit追跡ファイルのみ読み込む
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#yyh-gl-mac-hobby
# または .#yyh-gl-mac-work

# 4. 以降は make nix-switch-hobby または make nix-switch-work で適用
make nix-switch-hobby
```

**注意事項:**
- ファイルを変更したら `git add` してから `make nix-switch-hobby` / `make nix-switch-work` を実行する（未追跡ファイルはNixに読み込まれない）
- `darwin-rebuild switch` はシステム設定変更のため `sudo` が必要
- `services.nix-daemon.enable` は最新nix-darwinで廃止済み（`nix.enable` が自動管理）

### Build Mode

Nixのflake設定名でモードを指定する（`.env.public`でのMODE指定は廃止済み）:
- `yyh-gl-mac-hobby` (`make nix-switch-hobby`) — 1password/tailscaleをインストール、Google DriveへのSymlinkを`$HOME/Desktop/hobby`と`$HOME/Pictures`に作成
- `yyh-gl-mac-work` (`make nix-switch-work`) — `$HOME/Desktop/work`ディレクトリを作成
