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

1. `bin/base.sh` — Copy Zsh configs, copy Emacs configs
2. `bin/link.sh` — Copy tool configs (Claude settings, karabiner)
3. `bin/manual.sh` — Final manual steps

Secrets and SSH configs are managed separately via Nix + 1Password (see below).

### Config Copy Strategy

All config files live here and are **copied** (`cp`) into `$HOME` or `$HOME/.config/` by `bin/base.sh` and `bin/link.sh`. Only Google Drive directories use actual symlinks (`ln -sf`).

Key copies performed by `bin/base.sh`:

- `.zlogin`, `.zlogout`, `.zpreztorc`, `.zprofile`, `.zshenv`, `.zshrc` → `$HOME/`
- `depended-repositories/prezto/` → `$HOME/.zprezto/`
- `.emacs.d/` → `$HOME/.emacs.d/`

Key configs managed by Nix home-manager (`nix/home/dotfiles.nix`):

- `ghostty-config` → `$HOME/.config/ghostty/config`
- `.git-config/` → `$HOME/.config/git/`
- `aws/config` → `$HOME/.aws/config`
- `.dictionary.txt` → `$HOME/.dictionary.txt`
- `karabiner.json` → `$HOME/.config/karabiner/karabiner.json`

Secrets managed by Nix home-manager via 1Password (`nix/home/secrets.nix`):

- `op-templates/ssh-config.tpl` → `$HOME/.ssh/config`
- `op-templates/aws-credentials.tpl` → `$HOME/.aws/credentials`
- `op-templates/kube-config.tpl` → `$HOME/.kube/config`
- `op-templates/deck-credentials.json.tpl` → `$HOME/.local/share/deck/credentials.json`

To sync changes made directly in `$HOME` back to this repo, run `make snapshot`.

### 1Password Secrets Management

機密ファイルは`op inject`で1Passwordから展開する。`make nix-switch-hobby/work`実行時に自動適用される。

1Passwordに以下のアイテムを作成する（vault: `Personal`）:

| Item名              | カテゴリ           | フィールド                                |
|--------------------|----------------|--------------------------------------|
| `ssh-config`       | Secure Note    | notesPlain（`~/.ssh/config`の全内容）      |
| `aws-credentials`  | API Credential | `access_key_id`, `secret_access_key` |
| `k8s-config`       | Secure Note    | notesPlain（`~/.kube/config`の全内容）     |
| `deck-credentials` | Secure Note    | notesPlain（credentials.jsonの全内容）     |

テンプレートファイルは`op-templates/`ディレクトリに配置。`op://Vault/Item/Field`形式で参照。

### Submodules (`depended-repositories/`)

| Submodule | Purpose         |
|-----------|-----------------|
| `prezto`  | Zsh framework   |
| `scripts` | Utility scripts |

`dotfiles-private`サブモジュールは1Password移行により削除済み。

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
