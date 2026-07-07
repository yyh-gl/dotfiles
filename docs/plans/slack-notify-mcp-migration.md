# hooksのSlack通知をMCP経由に移行するプラン

## 背景・現状

- `claude/hooks/slack-notify.sh`がSlack Incoming Webhook（`curl`+`$AI_AGENTS_SLACK_WEBHOOK_URL`）でBlock Kitメッセージを送信している
- `claude/managed-settings.json`のhooks（`Notification`/`Stop`/`SubagentStop`）から呼び出される（timeout: 10秒）
- スクリプトはNix home-manager（`nix/home/claude.nix`）で`~/.claude/hooks/`に配置される
- `AI_AGENTS_SLACK_WEBHOOK_URL`はリポジトリ外（ローカルのシェル環境）で定義されている

これをSlack公式のホスト型MCPサーバー（<https://docs.slack.dev/ai/slack-mcp-server>、エンドポイント: `https://mcp.slack.com/mcp`）の`slack_send_message`ツール経由に変更する。

## 前提となる制約（重要）

**Claude CodeのhooksはシェルコマンドでありMCPツールを直接呼び出せない。**
MCPツールを呼べるのはセッション内のモデルだけなので、hookからMCP送信するには「hookの中でMCPクライアントを動かす」必要がある。

### 検討した方式

- **方式A: hookから`claude -p`（headless）を起動してMCPツールを呼ばせる** → **不採用。** 通知のたびにLLM呼び出しが発生し従量課金コストがかかる
- **方式B: 自前MCPクライアントで`mcp.slack.com/mcp`を直接叩く** → **採用。** LLMを介さないためコストゼロ・高速。OAuthの面倒な部分（Dynamic Client Registration・ブラウザ認証・トークンのキャッシュとリフレッシュ）は[`mcp-remote`](https://www.npmjs.com/package/mcp-remote)に任せる

### 方式Bの構成

```
hooks (managed-settings.json)
  └─ slack-notify.sh                     # 既存の引数インターフェースを維持
       └─ node slack-notify.mjs          # 依存ゼロの小さなMCPクライアント
            └─ npx mcp-remote https://mcp.slack.com/mcp   # stdio⇔remoteプロキシ+OAuth代行
                 └─ slack_send_message ツールをtools/callで実行
```

`mcp-remote`はOAuthトークンを`~/.mcp-auth/`にキャッシュし、リフレッシュも自動で行う。初回のみブラウザでのワークスペース認証が必要。

## 実施手順

### 1. 事前準備（手動・1回のみ）

1. Slackワークスペース管理者がMCP統合を承認する（Slack側の必須要件）
2. 初回OAuth認証を済ませる。ターミナルで以下を実行するとブラウザが開くので、対象ワークスペースで承認する:

   ```sh
   npx -y mcp-remote@latest https://mcp.slack.com/mcp
   ```

   認証完了後、トークンが`~/.mcp-auth/`にキャッシュされる（以降はヘッドレスで動作）
3. 通知先チャンネルのIDを控える（webhookと違いMCPでは送信先チャンネルの指定が必要）
4. `slack_send_message`ツールの正確な引数スキーマを確認する（`tools/list`の結果を見る。チャンネル指定の引数名が`channel_id`か`channel`か等）

### 2. MCPクライアントスクリプトの新規作成: `claude/hooks/slack-notify.mjs`

npm依存ゼロのNodeスクリプト。`mcp-remote`を子プロセスとして起動し、stdio上でJSON-RPC（`initialize`→`notifications/initialized`→`tools/call`）を直接話す。

```js
#!/usr/bin/env node
// usage: node slack-notify.mjs <channel_id> <text>
import { spawn } from "node:child_process";

const [channel, text] = process.argv.slice(2);
const MCP_REMOTE_VERSION = "0.1.29"; // 動作確認したバージョンに固定する

const proc = spawn("npx", ["-y", `mcp-remote@${MCP_REMOTE_VERSION}`, "https://mcp.slack.com/mcp"], {
  stdio: ["pipe", "pipe", "ignore"],
});

const send = (msg) => proc.stdin.write(JSON.stringify(msg) + "\n");
let buf = "";
const responses = {};
proc.stdout.on("data", (chunk) => {
  buf += chunk;
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i); buf = buf.slice(i + 1);
    try { const m = JSON.parse(line); if (m.id) responses[m.id]?.(m); } catch {}
  }
});
const request = (id, method, params) =>
  new Promise((resolve) => { responses[id] = resolve; send({ jsonrpc: "2.0", id, method, params }); });

await request(1, "initialize", {
  protocolVersion: "2025-06-18",
  capabilities: {},
  clientInfo: { name: "slack-notify-hook", version: "1.0.0" },
});
send({ jsonrpc: "2.0", method: "notifications/initialized" });
const result = await request(2, "tools/call", {
  name: "slack_send_message",
  arguments: { channel_id: channel, text }, // 引数名は手順1-4で確認したスキーマに合わせる
});
proc.kill();
process.exit(result.error || result.result?.isError ? 1 : 0);
```

タイムアウト（例: 30秒で`proc.kill()`して異常終了）も入れておく。

### 3. `claude/hooks/slack-notify.sh`の書き換え

引数インターフェース（`$1`=メッセージ、`$2`=エージェント名）と本文の情報量は現状を維持し、送信部分だけ差し替える:

```bash
#!/bin/bash

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

MESSAGE="${1}"
AGENT_NAME="${2:-main}"
CHANNEL="${SLACK_NOTIFY_CHANNEL:?SLACK_NOTIFY_CHANNEL is not set}"

TEXT="*${MESSAGE}*
• *Agent:* \`${AGENT_NAME}\`
• *Project:* \`${PROJECT_NAME}\`
• *Host:* \`${HOSTNAME}\`
• *Path:* \`${PROJECT_DIR}\`
• *Datetime:* ${TIMESTAMP}"

node "$HOME/.claude/hooks/slack-notify.mjs" "$CHANNEL" "$TEXT"
```

- Block Kitの`header`+`fields`レイアウトは、`slack_send_message`がBlock Kitを受け付けない場合に備えてmrkdwnテキストに落とす（スキーマ確認の結果、blocks指定が可能ならBlock Kitを維持する）
- `SLACK_NOTIFY_CHANNEL`（例: `C0123456789`）はローカルのシェル環境で定義する。webhook URLと違い秘匿情報ではない

### 4. Nix設定の変更

- `nix/home/`の`home.packages`にNode.js（`pkgs.nodejs_22`など）を追加する（`node`/`npx`がhook実行環境から見える必要がある。既にインストール済みなら不要）
- `claude/hooks/`ディレクトリは`nix/home/claude.nix`でまるごと配置されるため、`.mjs`追加による変更は不要

### 5. `claude/managed-settings.json`の変更

- 3つのhookの`timeout`を`10`から`30`に引き上げる（`npx`のコールドスタート+ネットワーク往復の余裕）
- hookコマンド自体は変更不要

### 6. 動作確認

1. `git add`してから`make nix-apply-hobby`（または`-work`）で`~/.claude/hooks/`へ反映する
2. `bash ~/.claude/hooks/slack-notify.sh 'テスト通知' 'main'`を手動実行し、チャンネルに届くことを確認する
3. 実セッションでNotification/Stop/SubagentStopの各hookを発火させて確認する
4. `~/.mcp-auth/`を退避してトークン未認証状態を作り、サイレント失敗（hookがブロックしない）ことを確認する

### 7. 後片付け

- ローカルシェル環境から`AI_AGENTS_SLACK_WEBHOOK_URL`の定義を削除する
- Slack App設定からIncoming Webhookを無効化する

## リスクと対策

| リスク | 対策 |
|---|---|
| OAuthトークンの完全失効（リフレッシュ不能）で送信失敗 | webhookと同様にサイレント失敗を許容。気づいたら手順1-2の`npx mcp-remote`を再実行して再認証 |
| `mcp-remote`の仕様変更・非互換 | バージョンを固定し、更新時に手動で動作確認する |
| `npx`のコールドスタートで遅延 | バージョン固定によりnpmキャッシュが効く。timeoutを30秒に拡大 |
| `slack_send_message`の引数スキーマが想定と異なる | 実装前に`tools/list`でスキーマを確認する（手順1-4） |
| ワークスペースのMCP統合が未承認 | 事前準備の手順1-1で管理者承認を先に済ませる |

## 補足

チャンネル固定の一方向通知はIncoming Webhookが設計上の適材ではある。本移行の実利は「webhook URLというシークレットをシェル環境変数で持ち回る運用を廃止し、OAuth（トークンは`~/.mcp-auth/`で自動管理）に一本化できること」。
