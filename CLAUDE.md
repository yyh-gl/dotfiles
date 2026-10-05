# CLAUDE.md

@AGENTS.md

This file provides guidance specific to Claude Code (claude.ai/code). Rules that apply to every agent are in AGENTS.md.

## Claude Code

### Managed Settings

`claude/managed-settings.json`は`nix/darwin/claude-code.nix`のactivation scriptで`/Library/Application Support/ClaudeCode/managed-settings.json`（root所有、Claude Codeからは書き込み不可）に配置している。Claude Codeは`/model`・`/effort`・plugin installなどの操作で`~/.claude/settings.json`を手動追加フィールドごと丸ごと再生成してしまう既知バグ（[claude-code#22659](https://github.com/anthropics/claude-code/issues/22659)）があり、home-manager経由のsymlink配置では設定が消えてしまうため、絶対に保持したい設定（permissions・hooks・sandbox・statusLineなど）はこちらに置く。`enabledPlugins`・`effortLevel`のようなClaude Code自身が書き換える可変設定は`~/.claude/settings.json`側に残し、Nixでは管理しない（`extraKnownMarketplaces`は公式marketplaceの登録を固定するためmanaged-settings.json側に置いている）。

仕事PCではMDM等により`/Library/Application Support/`配下への書き込みがブロックされていることが多いため、`nix/home/claude.nix`のactivation scriptで、workモードに限り同じ`claude/managed-settings.json`の内容を実ファイルとして`~/.claude/settings.json`にも配置している（前述の再生成バグにより上書きされうるフォールバック的な配置）。

`sandbox.excludedCommands`のパターンは`"gh *"`のように`*`の前にスペースを入れる（公式ドキュメントの記法。`"gh*"`は効かず、`gh`がsandbox内で`~/.config/gh/hosts.yml`を読めず失敗した）。`gh`・`docker`はsandbox内で動かせないため除外が必須。`git commit`は署名専用鍵がsandbox内で読めるので除外していない。

`"hunk session *"`も除外している。Hunkのdaemonは`127.0.0.1:47657`でlistenしているが、sandbox内からのloopback接続はseatbeltに拒否される（`nc`が`Operation not permitted`）。sandboxのproxyは`NO_PROXY`にloopbackを含み、そもそもloopback宛を扱わないため、`allowedDomains`等のドメイン許可リストでは開けられない。`allowLocalBinding`は全sandboxedコマンドに全loopbackポート（認証情報入りURLを持つproxyの`52001`を含む）を開くため採用していない。`hunk *`ではなく`hunk session *`に絞っているのは、`hunk session`が`--extension`を受け付けず、extension経由の任意コード実行の経路にならないため。この除外がカバーしない点として、`hunk session reload --source <path>`は任意のディレクトリでレビューコマンドを実行するためsandbox外に出る（read-onlyのgit操作なので影響は小さい）。複数単語のパターン（`hunk session *`）は実機で有効なことを確認済み。ただし除外が効くのは`hunk session list`のような単体コマンドのみで、`hunk session list 2>&1; echo "exit=$?"`のように`;`を付けた複合コマンドはsandbox内で実行され、接続に失敗して「No active Hunk sessions」と誤った結果を返す。原因は公式仕様で、1回の呼び出しに含まれるすべてのコマンドがexcludedCommandsに一致したときだけsandbox外になる（`echo`が一致しないので全体がsandbox内）。ファイルへのリダイレクト・`cd`・`$(...)`を含む呼び出しも丸ごとsandbox内になる。`gh`・`docker`にも同じことが当てはまり、パイプや`$(...)`付きの`gh`は`hosts.yml`を読めず失敗する。ClaudeにHunk・`gh`・`docker`を操作させる際は単体コマンドにする（`claude/CLAUDE.md`に指示がある）。

permissionsは「deny→ask→allow」の順に評価され、ルールの具体性は関係ない。広い`ask`（例: `Bash(docker*)`）は、具体的な`allow`（`docker ps`など）を打ち消してしまう。そのためdockerのaskは、書き込み・実行系サブコマンドの列挙にしている（`*`の前のスペースで`docker rm *`が`docker rmi`に、`docker image *`が`docker images`に一致しないようにしている）。`chmod`はdenyだと作業が止まってユーザーに戻されるため`ask`にしている。

### WezTermタブへの待ち状態アイコン表示

`claude/hooks/wezterm-state.sh`が`PermissionRequest`・`PreToolUse`（AskUserQuestion/ExitPlanMode）・`Notification`（elicitation系）で`waiting`、`Stop`/`StopFailure`で`done`、`PostToolUse`系・`UserPromptSubmit`・`SessionStart`・`SessionEnd`で`none`をOSC 1337 SetUserVar（`claude_state`）としてペインのttyへ書き込み、`wezterm.lua`の`format-tab-title`がそれを読んでタブのアイコン・背景色を切り替える（詳細は`docs/plans/wezterm-claude-state-tab-icon.md`）。`hooks`に項目を追加・変更する際は、この状態遷移（特に`none`へ戻す経路）を壊さないよう注意する。`find_tty`は`claude/hooks/wezterm-notify.sh`と`claude/hooks/lib/wezterm-tty.sh`で共有している。
