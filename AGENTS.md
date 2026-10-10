# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, etc.) when working with code in this repository.

## Overview

macOS dotfiles repository. Manages shell configs, tool settings, and setup scripts. Most files are symlinked into `$HOME` through Nix home-manager (`home.file`); files that the apps rewrite themselves (Karabiner, Rectangle, the Claude mods, and `~/.claude/settings.json` in work mode) are copied as regular files by activation scripts.

## Key Commands

```sh
# Initial setup (run once on a fresh machine, after installing Xcode Command Line Tools and cloning this repo over HTTPS)
make init-hobby # Install Homebrew, 1Password, Nix, then the first nix-darwin switch (hobby mode)
make init-work  # Same for work mode

# Full setup
make build-hobby  # Apply Nix then show the manual steps (hobby mode)
make build-work   # Apply Nix then show the manual steps (work mode)

# Nix
make nix-apply-hobby # Apply Nix configuration (hobby mode)
make nix-apply-work  # Apply Nix configuration (work mode)
make nix-cleanup     # Garbage collect Nix store
```

## Architecture

### Setup Flow

`make init-hobby` or `make init-work` (`bin/init.sh` → `bin/install-nix.sh` → first nix-darwin switch) → `make build-hobby` or `make build-work` → runs in order:

1. `make nix-apply-hobby` or `make nix-apply-work` — Apply Nix configuration
2. `bin/manual.sh` — Print the remaining manual steps

Secrets and SSH configs are managed separately via Nix + 1Password (see below).

### Config Copy Strategy

All config files live here and are managed by **Nix home-manager** (`nix/home/dotfiles.nix`).

Key configs managed by Nix home-manager (`nix/home/dotfiles.nix`):

- `wezterm.lua` → `$HOME/.config/wezterm/wezterm.lua`
- `.git-config/` → `$HOME/.config/git/`
- `aws/config` → `$HOME/.aws/config`
- `karabiner.json` → `$HOME/.config/karabiner/karabiner.json`（Karabiner-Elementsは設定変更のたびにこのファイルをwrite-temp-then-renameで書き換え、symlinkを実ファイルに置き換えてしまう。Rectangleと同様の理由で`home.file`ではなくactivation scriptで実ファイルとしてコピーしている）
- `laminate/config.yaml` → `$HOME/.config/laminate/config.yaml`
- `hunk/config.toml` → `$HOME/.config/hunk/config.toml`
- `RectangleConfig.json` → `$HOME/Library/Application Support/Rectangle/RectangleConfig.json`（Rectangle起動時に自動インポートされる。Rectangleはsymlinkを拒否するため`home.file`ではなくactivation scriptで実ファイルとしてコピーしている）

Secrets managed by Nix home-manager via 1Password (`nix/home/secrets.nix`):

- `op-templates/ssh-config.tpl` → `$HOME/.ssh/config`
- `op-templates/aws-credentials.tpl` → `$HOME/.aws/credentials`
- `op-templates/kube-config.tpl` → `$HOME/.kube/config`
- `op-templates/deck-credentials.tpl` → `$HOME/.local/share/deck/credentials.json`

### Claude・Codexの設定

sandbox・permissionsなどの設定は、Claude Code（`claude/managed-settings.json`）とCodex（`codex/requirements.toml`・`codex/managed_config.toml`）の両方に置いている。**ClaudeまたはCodexの設定を変更するときは、必ず両方について変更する**。対応関係と、揃えられない点（意図的な差分）は`docs/codex-sandbox.md`を参照。

### 1Password Secrets Management

機密ファイルは`op inject`で1Passwordから展開する。`make nix-apply-hobby/work`実行時に自動適用される。

1Passwordに以下のアイテムを作成する（vault: `PC`）:

| Item名             | カテゴリ       | フィールド                             |
| ------------------ | -------------- | -------------------------------------- |
| `ssh-config`       | Secure Note    | notesPlain（`~/.ssh/config`の全内容）  |
| `aws-credentials`  | Secure Note    | notesPlain（`~/.aws/credentials`の全内容） |
| `k8s-config`       | Secure Note    | notesPlain（`~/.kube/config`の全内容） |
| `deck-credentials` | Secure Note    | notesPlain（credentials.jsonの全内容） |

テンプレートファイルは`op-templates/`ディレクトリに配置。`op://Vault/Item/Field`形式で参照。

SSH秘密鍵は`op inject`ではなく`op read`で1Passwordから直接ローカルファイルへ書き出す運用のものもある（`nix/home/secrets.nix`の`sshKeysImport`・`gitSigningKeyImport`、vaultは既存の`ssh-config`等と同じ`PC`）。これらはhobbyモードだけで配置する。commit署名の設定も別ファイル（`.git-config/signing`）に分けていて、hobbyモードだけ`~/.config/git/signing`に置く。workモードでemailなどを変えたいときは、Nix管理外の`~/.config/git/local`に書く:

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
│   ├── default.nix    # nix-darwin設定 (キーボード, PAM, zshのシステム側設定)
│   ├── defaults.nix   # system.defaults と macOS の defaults / pmset
│   ├── homebrew.nix   # Homebrewのtaps / brews / casks / masApps
│   ├── claude-code.nix # Claude Codeのmanaged settingsを/Library/Application Supportへ配置
│   └── codex.nix      # Codexのrequirements / managed_configを/etc/codexへ配置
└── home/
    ├── default.nix    # home-manager設定 (パッケージ, モード別のimport)
    ├── dotfiles.nix   # 各種設定ファイルの配置 (wezterm, git, karabiner, rectangleなど)
    ├── zsh.nix        # programs.zsh (起動速度の工夫は下の「Zsh起動速度」)
    ├── emacs.nix      # Emacs本体とtree-sitterの文法
    ├── claude.nix     # ~/.claude 配下 (CLAUDE.md, agents, skills, hooks, mods)
    ├── gh.nix         # programs.gh
    └── secrets.nix    # 1Password連携 (hobbyモードのみ)
```

**初回セットアップ手順:**

```sh
# 1. Xcode Command Line Toolsを入れ、このリポジトリをHTTPSでcloneしてcdする
xcode-select --install
git clone https://github.com/yyh-gl/dotfiles.git ~/workspaces/github.com/yyh-gl/dotfiles

# 2. 初回セットアップ。Homebrew・1Password・Nixを入れ、/etc/zshrc・/etc/bashrcを
#    .before-nix-darwinへ退避して（nix-darwinが管理するため）、最初のswitchまで行う
git add nix/ flake.nix flake.lock   # Nixはgit追跡ファイルのみ読み込む
make init-hobby                     # または make init-work

# 3. 以降は make nix-apply-hobby または make nix-apply-work で適用
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
