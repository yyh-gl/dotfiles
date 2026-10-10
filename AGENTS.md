# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, etc.) when working with code in this repository.

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
- `karabiner.json` → `$HOME/.config/karabiner/karabiner.json`（Karabiner-Elementsは設定変更のたびにこのファイルをwrite-temp-then-renameで書き換え、symlinkを実ファイルに置き換えてしまう。Rectangleと同様の理由で`home.file`ではなくactivation scriptで実ファイルとしてコピーしている）
- `laminate/config.yaml` → `$HOME/.config/laminate/config.yaml`
- `hunk/config.toml` → `$HOME/.config/hunk/config.toml`
- `RectangleConfig.json` → `$HOME/Library/Application Support/Rectangle/RectangleConfig.json`（Rectangle起動時に自動インポートされる。Rectangleはsymlinkを拒否するため`home.file`ではなくactivation scriptで実ファイルとしてコピーしている）

Secrets managed by Nix home-manager via 1Password (`nix/home/secrets.nix`):

- `op-templates/ssh-config.tpl` → `$HOME/.ssh/config`
- `op-templates/aws-credentials.tpl` → `$HOME/.aws/credentials`
- `op-templates/kube-config.tpl` → `$HOME/.kube/config`
- `op-templates/deck-credentials.json.tpl` → `$HOME/.local/share/deck/credentials.json`

### Claude・Codexの設定

sandbox・permissionsなどの設定は、Claude Code（`claude/managed-settings.json`）とCodex（`codex/requirements.toml`・`codex/managed_config.toml`）の両方に置いている。**ClaudeまたはCodexの設定を変更するときは、必ず両方について変更する**。対応関係と、揃えられない点（意図的な差分）は`docs/codex-sandbox.md`を参照。

### 1Password Secrets Management

機密ファイルは`op inject`で1Passwordから展開する。`make nix-apply-hobby/work`実行時に自動適用される。

1Passwordに以下のアイテムを作成する（vault: `Personal`）:

| Item名             | カテゴリ       | フィールド                             |
| ------------------ | -------------- | -------------------------------------- |
| `ssh-config`       | Secure Note    | notesPlain（`~/.ssh/config`の全内容）  |
| `aws-credentials`  | API Credential | `access_key_id`, `secret_access_key`   |
| `k8s-config`       | Secure Note    | notesPlain（`~/.kube/config`の全内容） |
| `deck-credentials` | Secure Note    | notesPlain（credentials.jsonの全内容） |

テンプレートファイルは`op-templates/`ディレクトリに配置。`op://Vault/Item/Field`形式で参照。

SSH秘密鍵は`op inject`ではなく`op read`で1Passwordから直接ローカルファイルへ書き出す運用のものもある（`nix/home/secrets.nix`の`sshKeysImport`、vaultは既存の`ssh-config`等と同じ`PC`）:

| Item名           | カテゴリ | フィールド                                                                                                       |
| ---------------- | -------- | ---------------------------------------------------------------------------------------------------------------- |
| `GitHub`         | SSH Key  | private_key（GitHub認証用。`~/.ssh/keys/github_yyh-gl`に配置）                                                   |
| `GitHub Signing` | SSH Key  | private_key（commit署名専用。`~/.config/git/github_signing_ed25519`に配置。GitHubにはSigning Keyとして登録する） |

commit署名鍵を認証鍵と分けているのは、Claude CodeとCodexのsandboxが`~/.ssh/keys`の読み取りを拒否しているため。署名専用鍵は`~/.ssh`の外に置いてsandbox内の`git commit`から読めるようにしており、漏れても被害は署名偽造に限られる（pushはできない）。正本は1Passwordで、ローカルのファイルはapplyのたびに上書きされる派生コピー。鍵のファイル名に`.key`・`.pem`の拡張子は付けない（sandboxの`**/*.key`・`**/*.pem`のdenyと`Read(**/*.key)`に該当するため）。

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

### Zsh起動速度

zsh-benchで計測して、起動（first_prompt_lag）を短くするために次の構成にしている。戻さないこと。

- `compinit`は`nix/home/zsh.nix`の`completionInit`で1回だけ、`-C`付きで実行する。nix-darwin側（`nix/darwin/default.nix`）で`enableGlobalCompInit`・`enableBashCompletion`・`promptInit`を無効化しているのは、`/etc/zshrc`側で`compinit`が重複して走るのを防ぐため。
- `-C`は補完の追加を自動検知しないので、`home.activation.resetZcompdump`でapplyのたびに`~/.zcompdump*`を削除している。applyを介さず`brew install`した補完は、`rm ~/.zcompdump`するまで反映されない。
- `brew shellenv`は`profileExtra`に静的に展開している（evalするとbrewの起動分だけ遅くなる）。`export FPATH`は、`.zprofile`を読まないネストしたシェルにbrewの補完ディレクトリを引き継ぐために必須。
- `starship init zsh`はビルド時に生成している（`starshipInit`）。`RPROMPT`（`right_format`未使用なのに毎プロンプトstarshipを起動する）と`PROMPT2`を静的化している。`starship.toml`で`right_format`か`continuation_prompt`を設定する場合は、この置き換えを見直す。
- `scripts/celebrate-anniversary.sh`は`.zlogin`から毎回呼ばれるため、外部コマンドをforkしないzshスクリプトにしている。`CELEBRATE_TODAY=YYYY-MM-DD`で「今日」を差し替えられる。
- PATHはNixで入れたツールをHomebrewより優先する（`profileExtra`でHomebrewを後ろに足す。`initContent`で先頭に戻さない）。`/usr/local`はApple Silicon専用構成のため含めない。
- `LANG`は`ja_JP.UTF-8`で固定している（`defaults read`を毎回実行すると起動が遅くなる）。

### Build Mode

Nixのflake設定名でモードを指定する（`.env.public`でのMODE指定は廃止済み）:

- `yyh-gl-mac-hobby` (`make nix-apply-hobby`) — 1password/tailscaleをインストール、Google DriveへのSymlinkを`$HOME/Desktop/hobby`と`$HOME/Pictures`に作成
- `yyh-gl-mac-work` (`make nix-apply-work`) — `$HOME/Desktop/work`ディレクトリを作成
