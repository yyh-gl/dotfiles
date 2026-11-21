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
- `wezterm-work.lua` → `$HOME/.config/wezterm/work.lua`（workモードのみ。TUIアプリのマウスキャプチャ中もテキスト選択を優先するバインディング。`wezterm.lua`があれば読み込む）
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

### Pi

`pi/skills/*`・`pi/extensions/*`の各ディレクトリは、`nix/home/pi.nix`が`builtins.readDir`で列挙して`~/.pi/agent/{skills,extensions}/<名前>`へ個別にsymlinkする。ディレクトリを追加・削除しても`pi.nix`自体は変更しなくてよい。

`~/.pi/agent/settings.json`はPiが`lastChangelogVersion`などを自分で書き換えるため、Nixでは管理しない。

`ask_user_question`（`pi/extensions/ask-user-question/`）は、Piに組み込みの質問UIがないためClaude CodeのAskUserQuestionの代わりとして自作したExtensionである。Claude版のskillをPiへ移すときは、ツール名（`AskUserQuestion` → `ask_user_question`）と、Piにない機能（Agentツールへの調査委譲・`plansDirectory`）の書き換えが必要になる。`model`・`effort`のfrontmatterはそのままPiでも使える（下記の`skill-subagent`拡張）。

`skill-subagent`（`pi/extensions/skill-subagent/`）は、SKILL.mdのfrontmatterに`model`（`provider/model-id`形式。例: `anthropic/claude-opus-5-5`）または`effort`（`ThinkingLevel`の文字列。例: `xhigh`）があるskillを`/skill:<name> <args>`で明示的に呼び出したとき、そのskillを別プロセス（`pi --mode rpc --no-session`）のサブエージェントとして実行する汎用の仕組みである。他のskillをPiへ移植するときも、この2フィールドを足すだけで同じ仕組みに乗れる（最初の利用者は`pi/skills/ponder/SKILL.md`）。モデルが未解決・未認証のときは通常呼び出しにフォールバックする。決定事項・調査結果は`docs/plans/pi-skill-subagent.md`を参照。

`ask-user-question`・`skill-subagent`とも、端末・子プロセスの起動を伴わない純粋関数部分（`/skill:`構文解析、NDJSON行分割・パース、frontmatterの`model`/`effort`抽出・検証、選択肢・回答の組み立てなど）は`bun test pi/extensions/skill-subagent pi/extensions/ask-user-question`で自動テストできる（`make test-mods`はClaude Code mods専用でこちらは対象外）。一方、TUI・子プロセスとの実際のやりとりを伴う結合部分（`ask-user-question/ui.ts`のTUI描画、`skill-subagent/index.ts`・`process.ts`）は自動テストの対象外で、引き続き手動確認が必要。Piを更新したら、`pi -e`・`pi --skill`での手動確認に加えて、配備後に`-e`・`--skill`なしで起動し、`ask-user-question`の読み込みエラーがないこと・`/skill:ponder`が一覧にあることも確かめる（skillは読み込めなくてもエラーを出さず一覧から消えるだけなので、一覧表示の確認が欠かせない）。

Piにはsandboxやツール実行ごとの承認の仕組みがなく、上の「Claude・Codexの設定」にある「両方を変える」ルールの対象外である。

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

SSH秘密鍵は`op inject`ではなく`op read`で1Passwordから直接ローカルファイルへ書き出す運用のものもある（`nix/home/secrets.nix`の`sshKeysImport`・`gitSigningKeyImport`、vaultは既存の`ssh-config`等と同じ`PC`）。これらはhobbyモードだけで配置する。commit署名の設定も別ファイル（`.git-config/signing`）に分けていて、hobbyモードだけ`~/.config/git/signing`に置く。workモードでemailなどを変えたいときは、Nix管理外の`~/.config/git/local`に書く（雛形は`bin/init.sh`が、ファイルがないときだけ作る）:

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
    ├── pi.nix         # ~/.pi/agent 配下 (skills, extensions)
    ├── gh.nix         # programs.gh
    └── secrets.nix    # 1Password連携 (hobbyモードのみ)
```

初回セットアップの手順は[README.md](README.md)にある（Xcode Command Line Tools → HTTPSでclone → `make init-hobby` / `make init-work`）。`/etc/zshrc`・`/etc/bashrc`はnix-darwinが管理するため、`init`が`.before-nix-darwin`へ退避する。

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
- `scripts/celebrate-anniversary.sh`は`.zlogin`から毎回`source`されるため、プロセスもサブシェルもforkしない関数にしている。`.zlogin`のバナー類は対話シェルのときだけ出す（IDEの`zsh -l -c`に出力を混ぜない）。`CELEBRATE_TODAY=YYYY-MM-DD`で「今日」を差し替えられる。
- `/usr/local`はApple Silicon専用構成のため含めない。NixとHomebrewで同じツールは入れない前提のため、PATH上の優先順位は特に調整していない。
- `LANG`は`ja_JP.UTF-8`で固定している（`defaults read`を毎回実行すると起動が遅くなる）。

### Build Mode

Nixのflake設定名でモードを指定する（`.env.public`でのMODE指定は廃止済み）:

- `yyh-gl-mac-hobby` (`make nix-apply-hobby`) — 1password/tailscaleをインストール、Google DriveへのSymlinkを`$HOME/Desktop/hobby`と`$HOME/Pictures`に作成
- `yyh-gl-mac-work` (`make nix-apply-work`) — `$HOME/Desktop/work`ディレクトリを作成、WezTermに`work.lua`（`wezterm-work.lua`）を配置
