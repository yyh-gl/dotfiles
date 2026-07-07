# hooksのSlack通知をMCP経由に移行するプラン

## 背景・現状

- `claude/hooks/slack-notify.sh`がSlack Incoming Webhook（`curl`+`$AI_AGENTS_SLACK_WEBHOOK_URL`）でBlock Kitメッセージを送信している
- `claude/managed-settings.json`のhooks（`Notification`/`Stop`/`SubagentStop`）から呼び出される（timeout: 10秒）
- スクリプトはNix home-manager（`nix/home/claude.nix`）で`~/.claude/hooks/`に配置される
- `AI_AGENTS_SLACK_WEBHOOK_URL`はリポジトリ外（ローカルのシェル環境）で定義されている

これをSlack公式のホスト型MCPサーバー（<https://docs.slack.dev/ai/slack-mcp-server>、エンドポイント: `https://mcp.slack.com/mcp`）の`slack_send_message`ツール経由に変更する。

## 前提となる制約（重要）

**Claude CodeのhooksはシェルコマンドでありMCPツールを直接呼び出せない。**
MCPツールを呼べるのはセッション内のモデルだけなので、hookからMCP送信するには「hookの中でMCPクライアントを動かす」必要がある。実現方式は以下の2択。

## 方式比較

### 方式A: hookから`claude -p`（headlessモード）を起動する【推奨】

hookスクリプトが`claude -p`を起動し、Slack公式プラグインのMCPツール`slack_send_message`で送信させる。

- 利点: 公式サポートされた仕組みだけで完結する。OAuth認証・トークン更新はClaude Code本体が管理する
- 欠点: 通知1回ごとにLLM呼び出しが発生する（レイテンシ数秒〜数十秒、少額のトークンコスト）。`--model haiku`とバックグラウンド実行で緩和する

### 方式B: 自前MCPクライアントで`mcp.slack.com/mcp`を直接叩く

hookから`mcp-remote`（OAuthとトークンキャッシュを代行するプロキシ）+小さなNodeスクリプトでJSON-RPCの`tools/call`を直接送る。

- 利点: LLMを介さないので高速・トークンコストゼロ
- 欠点: 非公式な組み合わせで壊れやすい。初回のブラウザOAuthフロー、トークン失効時の再認証、`mcp-remote`のバージョン追従を自前で面倒見る必要がある

→ **方式Aを採用する。** 通知はfire-and-forgetなのでレイテンシは体感に影響せず、保守性を優先する。

> 補足: そもそもチャンネル固定の一方向通知はIncoming Webhookの設計上の適材でもある。MCP化の主な利得は「webhook URLというシークレットの管理を廃止し、OAuthに一本化できること」と「メッセージ内容をモデルに柔軟に組み立てさせられること」。

## 実施手順

### 1. 事前準備（手動・1回のみ）

1. Slackワークスペース管理者がMCP統合を承認する（Slack側の必須要件）
2. Claude Codeで公式Slackプラグインをインストールする:

   ```
   /plugin install slack@claude-plugins-official
   ```

   マーケットプレイス`claude-plugins-official`は`managed-settings.json`の`extraKnownMarketplaces`に登録済み。`enabledPlugins`はClaude Code自身が書き換える設定なので、CLAUDE.mdの方針どおりNix管理にはしない
3. 初回ツール使用時にOAuthでワークスペース認証する（対話セッションで一度実行しておく）
4. 通知先チャンネルのIDを控える（webhookと違いMCPでは送信先チャンネルの指定が必要）

### 2. `claude/hooks/slack-notify.sh`の書き換え

```bash
#!/bin/bash

# 再帰ガード: headlessのclaude自身が発火させるStop hookで無限ループしないようにする
# （managed-settings.jsonのhooksは--settingsでは無効化できないため環境変数で防ぐ）
if [ -n "$CLAUDE_SLACK_NOTIFY_ACTIVE" ]; then
  exit 0
fi
export CLAUDE_SLACK_NOTIFY_ACTIVE=1

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

MESSAGE="${1}"
AGENT_NAME="${2:-main}"
CHANNEL="${SLACK_NOTIFY_CHANNEL:?SLACK_NOTIFY_CHANNEL is not set}"

claude -p --model haiku \
  --allowedTools "mcp__slack__slack_send_message" \
  "次の内容をSlackのチャンネル${CHANNEL}にslack_send_messageで送信して。
見出し: ${MESSAGE}
Agent: ${AGENT_NAME}
Project: ${PROJECT_NAME}
Host: ${HOSTNAME}
Path: ${PROJECT_DIR}
Datetime: ${TIMESTAMP}" \
  >/dev/null 2>&1
```

注意点:

- MCPツール名のプレフィックス（`mcp__slack__…`）はプラグイン導入後に`claude mcp list`や`/mcp`で実名を確認して合わせる
- Block Kitの`fields`レイアウト相当は`slack_send_message`が受け付ける形式（mrkdwnテキスト）に落とす
- `SLACK_NOTIFY_CHANNEL`（例: `C0123456789`）は`AI_AGENTS_SLACK_WEBHOOK_URL`と同様にローカルのシェル環境で定義する。webhook URLと違い秘匿性は低い

### 3. `claude/managed-settings.json`の変更

- 3つのhookの`timeout`を`10`から`60`に引き上げる（headless起動+MCP呼び出しのレイテンシ対策）
- hookコマンド自体は変更不要（引数インターフェースを維持するため）

### 4. 動作確認

1. `git add`してから`make nix-apply-hobby`（または`-work`）で`~/.claude/hooks/`へ反映する
2. `bash ~/.claude/hooks/slack-notify.sh 'テスト通知' 'main'`を手動実行し、チャンネルに届くことを確認する
3. 実セッションでStop hookを発火させ、無限ループが起きないこと（再帰ガードの動作）を確認する
4. OAuthトークン失効時の挙動（サイレント失敗になること）を確認する

### 5. 後片付け

- ローカルシェル環境から`AI_AGENTS_SLACK_WEBHOOK_URL`の定義を削除する
- Slack App設定からIncoming Webhookを無効化する

## リスクと対策

| リスク | 対策 |
|---|---|
| headless claudeのStop hook発火による無限ループ | `CLAUDE_SLACK_NOTIFY_ACTIVE`環境変数による再帰ガード（子プロセスに継承される） |
| 通知のレイテンシ増（数秒〜数十秒） | timeoutを60秒に拡大。fire-and-forget通知なので体感影響なし |
| トークンコスト | `--model haiku`を指定。通知1回あたりごく少額 |
| OAuthトークン失効による送信失敗 | webhookと同様にサイレント失敗を許容。気づいたら対話セッションで`/mcp`から再認証 |
| ワークスペースのMCP統合が未承認 | 事前準備の手順1で管理者承認を先に済ませる |
