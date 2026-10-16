# Dotfiles

macOS向けのdotfiles。Nix（nix-darwin + home-manager）で宣言的に管理している。

## Setup

1. Xcode Command Line Toolsを入れ、リポジトリをHTTPSでcloneする（SSHの鍵は1Passwordのセットアップ後に使えるようになるため）

   ```sh
   xcode-select --install
   git clone https://github.com/yyh-gl/dotfiles.git ~/workspaces/github.com/yyh-gl/dotfiles
   cd ~/workspaces/github.com/yyh-gl/dotfiles
   ```

2. 初回セットアップ（最初の1回だけ）

   ```sh
   git add nix/ flake.nix flake.lock   # Nixはgit追跡ファイルだけを読む
   make init-hobby                     # 仕事用のMacなら make init-work
   ```

3. 設定を適用する

   ```sh
   make build-hobby                    # 仕事用のMacなら make build-work
   ```

使えるコマンドは`make help`で見られる。詳しい構成と運用上の注意は[AGENTS.md](AGENTS.md)を参照。

## Repository Structure

- `nix/`: nix-darwin（システム設定・Homebrew）とhome-manager（dotfileの配置・zsh・パッケージ）
- `bin/`: セットアップ用スクリプト（`init.sh`・`install-nix.sh`・`manual.sh`）
- `claude/`: Claude Codeの設定（managed settings・agents・skills・hooks・mods）
- `codex/`: Codexの設定（requirements・managed config）
- `docs/`: 設計メモ（`docs/codex-sandbox.md`など）
- `.git-config/`: Gitの設定とグローバルignore
- `.emacs.d/`: Emacsの設定
- `.ssh/keys/`: SSH公開鍵
- `op-templates/`: 1Passwordから展開する機密ファイルのテンプレート
- `hooks/`: このリポジトリのGit hooks（gitleaks）
- `scripts/`: シェルから呼ぶスクリプト（`~/.local/bin`に配置）
- `wezterm.lua`・`karabiner.json`・`RectangleConfig.json`・`starship.toml`など: 各アプリの設定
