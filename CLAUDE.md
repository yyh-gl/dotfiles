# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS dotfiles repository. Manages shell configs, tool settings, and setup scripts via file copies to `$HOME`.

## Key Commands

```sh
# Initial setup (run once on a fresh machine)
make init       # Install Homebrew, Git, Xcode, clone repo, install Nix

# Full setup
make build-hobby  # Run manual steps then apply Nix (hobby mode)
make build-work   # Run manual steps then apply Nix (work mode)

# Nix
make nix-apply-hobby # Apply Nix configuration (hobby mode)
make nix-apply-work  # Apply Nix configuration (work mode)
make nix-cleanup     # Garbage collect Nix store
```

## Architecture

### Setup Flow

`bin/init.sh` → `make build-hobby` or `make build-work` → runs these scripts in order:

1. `bin/manual.sh` — Final manual steps
2. `make nix-apply-hobby` or `make nix-apply-work` — Apply Nix configuration

Secrets and SSH configs are managed separately via Nix + 1Password (see below).

### Config Copy Strategy

All config files live here and are managed by **Nix home-manager** (`nix/home/dotfiles.nix`).

Key configs managed by Nix home-manager (`nix/home/dotfiles.nix`):

- `wezterm.lua` → `$HOME/.config/wezterm/wezterm.lua`
- `.git-config/` → `$HOME/.config/git/`
- `aws/config` → `$HOME/.aws/config`
- `.dictionary.txt` → `$HOME/.dictionary.txt`
- `karabiner.json` → `$HOME/.config/karabiner/karabiner.json`

Secrets managed by Nix home-manager via 1Password (`nix/home/secrets.nix`):

- `op-templates/ssh-config.tpl` → `$HOME/.ssh/config`
- `op-templates/aws-credentials.tpl` → `$HOME/.aws/credentials`
- `op-templates/kube-config.tpl` → `$HOME/.kube/config`
- `op-templates/deck-credentials.json.tpl` → `$HOME/.local/share/deck/credentials.json`

### 1Password Secrets Management

機密ファイルは`op inject`で1Passwordから展開する。`make nix-apply-hobby/work`実行時に自動適用される。

1Passwordに以下のアイテムを作成する（vault: `Personal`）:

| Item名              | カテゴリ           | フィールド                                |
|--------------------|----------------|--------------------------------------|
| `ssh-config`       | Secure Note    | notesPlain（`~/.ssh/config`の全内容）      |
| `aws-credentials`  | API Credential | `access_key_id`, `secret_access_key` |
| `k8s-config`       | Secure Note    | notesPlain（`~/.kube/config`の全内容）     |
| `deck-credentials` | Secure Note    | notesPlain（credentials.jsonの全内容）     |

テンプレートファイルは`op-templates/`ディレクトリに配置。`op://Vault/Item/Field`形式で参照。

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

# 4. 以降は make nix-apply-hobby または make nix-apply-work で適用
make nix-apply-hobby
```

**注意事項:**

- ファイルを変更したら `git add` してから `make nix-apply-hobby` / `make nix-apply-work` を実行する（未追跡ファイルはNixに読み込まれない）
- `darwin-rebuild switch` はシステム設定変更のため `sudo` が必要
- `services.nix-daemon.enable` は最新nix-darwinで廃止済み（`nix.enable` が自動管理）

### Build Mode

Nixのflake設定名でモードを指定する（`.env.public`でのMODE指定は廃止済み）:

- `yyh-gl-mac-hobby` (`make nix-apply-hobby`) — 1password/tailscaleをインストール、Google DriveへのSymlinkを`$HOME/Desktop/hobby`と`$HOME/Pictures`に作成
- `yyh-gl-mac-work` (`make nix-apply-work`) — `$HOME/Desktop/work`ディレクトリを作成
