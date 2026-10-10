# CLAUDE.md

@AGENTS.md

This file provides guidance specific to Claude Code (claude.ai/code). Rules that apply to every agent are in AGENTS.md.

## Claude Code

### Managed Settings

- `claude/managed-settings.json`は`nix/darwin/claude-code.nix`のactivation scriptで`/Library/Application Support/ClaudeCode/managed-settings.d/50-dotfiles.json`（root所有、Claude Codeからは書き込み不可）に配置する。絶対に保持したい設定（permissions・hooks・sandbox・envなど。ステータスラインはmod `claude/mods/statusline`）はここに置く。`/model`・`/effort`・plugin installが`~/.claude/settings.json`を丸ごと再生成する既知バグ（[claude-code#22659](https://github.com/anthropics/claude-code/issues/22659)）で消えるため
- `enabledPlugins`・`effortLevel`のようなClaude Code自身が書き換える設定は`~/.claude/settings.json`側に残し、Nixでは管理しない（`extraKnownMarketplaces`は例外でmanaged側）
- 旧配置の`managed-settings.json`は、中身がdotfilesの過去版（`nix/darwin/claude-code.nix`のsha256一覧）と一致するときだけapplyが消す。手で編集されたものは残して警告するので、不要なら`sudo rm "/Library/Application Support/ClaudeCode/managed-settings.json"`で消す（残るとdrop-inとマージされ、消したルールが効き続ける）
- 仕事PCでは`/Library/Application Support/`への書き込みがMDMで拒否されることがあり、その場合は警告だけ出してapplyを続ける。代わりにworkモードに限り`nix/home/claude.nix`が同じ内容を`~/.claude/settings.json`へjqで上書きマージする。user層なので、クローンしたリポジトリの`.claude/settings.json`に上書きされうる（managed層ほど強くない）
- `sandbox.excludedCommands`のパターンは`"gh *"`のように`*`の前にスペースを入れる（`"gh*"`は効かない）。`gh`・`docker`・`hunk session *`はsandbox内で動かせないため除外が必須。1回の呼び出しに含まれるすべてのコマンドが一致したときだけsandbox外になるので、パイプ・`;`・`$(...)`・リダイレクト・`cd`を付けると丸ごとsandbox内で動き失敗する。ClaudeにHunk・`gh`・`docker`を操作させる際は単体コマンドにする（`claude/CLAUDE.md`に指示がある）
- permissionsは「deny→ask→allow」の順に評価され、具体性は関係ない。広い`ask`（`Bash(docker*)`など）は具体的な`allow`を打ち消すため、dockerのaskは書き込み・実行系サブコマンドの列挙にしている。`chmod`はdenyだと作業が止まるため`ask`
- ClaudeとCodexの設定は`make check-policy`で突き合わせる。意図的な差分は`scripts/check-agent-policy.py`に理由つきで書く

経緯・実機で確認した挙動・hunkの除外の詳細は`docs/claude-settings.md`を参照。

### WezTermタブへの待ち状態アイコン表示

`claude/hooks/wezterm-state.sh`が`PermissionRequest`・`PreToolUse`（AskUserQuestion/ExitPlanMode）・`Notification`（elicitation系）で`waiting`、`Stop`/`StopFailure`で`done`、`PostToolUse`系・`UserPromptSubmit`・`SessionStart`・`SessionEnd`で`none`をOSC 1337 SetUserVar（`claude_state`）としてペインのttyへ書き込み、`wezterm.lua`の`format-tab-title`がそれを読んでタブのアイコン・背景色を切り替える。`hooks`に項目を追加・変更する際は、この状態遷移（特に`none`へ戻す経路）を壊さないよう注意する。`find_tty`は`claude/hooks/lib/wezterm-tty.sh`に定義し、`wezterm-notify.sh`と`wezterm-state.sh`が読み込んで共有している。

### mod（`claude/mods/`）

`claude/mods/<名前>/`の各modは`nix/home/claude.nix`の`claudeMods`で`~/.claude/mods/<名前>`へ実ファイルとしてコピーされ、`claude/managed-settings.json`の`env.CLAUDE_CODE_PLUGIN_DIRS`（`:`区切り。例: `~/.claude/mods/statusline:~/.claude/mods/prompt-highlight-md`）に並べたものが読み込まれる。modを足すときは配備のループは変えずに、この環境変数へ追記する。`~/.claude/mods`全体は消さないので、手動で置いたmodは残る。

テストは`make test-mods`で回す（`bun test`・`claude plugin validate`・`claude plugin test`）。`hooks/lib/*.spec.ts`がbun用、`hooks/register.test.ts`が`claude plugin test`用で、`claude plugin test`は`*.test.ts`だけを拾う。`bun test`は`.spec.ts`と`.test.ts`の両方を拾い、`register.test.ts`はbunでは動かないため、必ず`bun test claude/mods/prompt-highlight-md/hooks/lib`のようにパスで絞る。CIの`.github/workflows/test-mods.yml`はclaude CLIの導入と認証が要るため`bun test`だけを回す。

modはClaude Code固有の仕組みでCodexに対応する設定はないので、`docs/codex-sandbox.md`は変更していない（意図的な差分）。

### Codex MCPサーバー

`codex-review`スキルは`mcp__codex__codex`を使う。サーバーの登録はNixでは管理していないため、新しいマシンでは一度だけ`claude mcp add codex -s user -- codex mcp-server`で登録する（`codex`はHomebrewのcaskで入る）。
