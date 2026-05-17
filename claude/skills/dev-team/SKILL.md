---
name: dev-team
description: devチームを起動するスキル。Lead・Planner・Implementer・Tester・Reviewerの5 agentが協調して機能実装・テスト・レビューを実行する。「開発チームを作成して」「dev teamで実装して」「チームで開発したい」「エージェントチームで〇〇を実装して」などの依頼が来たら必ずこのスキルを使用すること。開発タスク全般（機能追加・バグ修正・リファクタリング）でチームを組んで作業する場合に適用する。
---

# Dev Team 共通ルール

このスキルはチーム全メンバーが読み込む共通ルール。

## チーム起動手順（Leadが実行）

### Step 1: チームを作成する

TeamCreate ツールでチームを作成する:

- `team_name`: `dev-team`
- `description`: ユーザーのタスク概要

### Step 2: タスクを登録する

TaskCreate でタスクを登録する（subject・description を設定）。
依存関係がある場合は TaskUpdate で blockedBy を設定する。

### Step 3: メンバーを起動する

Agent ツールで各メンバーを起動する。**`team_name: "dev-team"` と `name` パラメータを必ず指定する**（指定しないとチームに参加できない）:

- Implementer: `subagent_type: "implementer"`, `name: "Implementer"`, `team_name: "dev-team"`
- Tester: `subagent_type: "tester"`, `name: "Tester"`, `team_name: "dev-team"`
- Reviewer: `subagent_type: "reviewer"`, `name: "Reviewer"`, `team_name: "dev-team"`
- Planner（Largeタスクのみ）: `subagent_type: "planner"`, `name: "Planner"`, `team_name: "dev-team"`

複雑度に応じた判断は `teams/dev/agents/lead.md` のワークフローを参照。

### Step 4: タスクを割り当てる

SendMessage でメンバーにタスクを割り当てる（`to` はメンバーの `name`）:

```json
{
  "to": "Implementer",
  "message": "タスク詳細（対象ファイル・期待する成果物・コンテキストを含む）",
  "summary": "タスク名（5-10語）"
}
```

TaskUpdate で `owner` をメンバー名に設定してタスクのオーナーを明示する。

### Step 5: 進捗を管理する

- メンバーからの報告は SendMessage で自動配信される（手動確認不要）
- 完了報告を受けたら TaskUpdate でステータスを `completed` に更新する
- 次のタスクが unblock されたら SendMessage で該当メンバーに割り当てる

### Step 6: チームをシャットダウンする

全タスク完了後、各メンバーに SendMessage でシャットダウンを要求する:

```json
{
  "to": "Implementer",
  "message": { "type": "shutdown_request", "reason": "全タスク完了" },
  "summary": "シャットダウン要求"
}
```

全メンバーのシャットダウン確認後、ユーザーへ最終報告を行う。

## ファイル所有権

ファイル競合を防ぐため、各agentは担当領域のみ変更する:

- **Lead**: ファイル変更なし。タスク管理とメッセージングのみ。Bashは読み取り専用コマンド（`git log`, `git status`, `ls` 等）にのみ使用
- **Planner**: ファイル変更なし。コード調査と実装プラン作成のみ。Bashは読み取り専用コマンドにのみ使用
- **Implementer**: テストディレクトリとインフラ設定以外のすべてのファイル。具体的には `tests/`, `test/`, `__tests__/`, `*.test.*`, `*.spec.*`, `.github/`, `.claude/` 以外
- **Tester**: テストコードとテスト設定のみ（`tests/`, `test/`, `__tests__/`, `*.test.*`, `*.spec.*`, テスト設定ファイル `jest.config.*`, `vitest.config.*` 等）
- **Reviewer**: ファイル変更なし。`git diff` とコード読解のみ。Bashは読み取り専用コマンドにのみ使用

## コミュニケーション規約

### 完了報告フォーマット

タスク完了時、**SendMessage ツール**を使って Lead へ報告する。プレーンテキストの出力は Lead に届かない点に注意すること。各agentは役割固有のセクション（テスト結果、レビュー判定等）を追加してよい:

```
## 完了報告
- タスク: [タスク名]
- 状態: 完了 / 一部完了 / ブロック
- 変更ファイル: [一覧]
- 概要: [何をしたか]
- 注意点: [あれば]

（以下、役割固有のセクションを追加可）
```

### ブロック報告

作業がブロックされた場合、**SendMessage ツール**で即座にLeadへ報告する:

```
## ブロック報告
- タスク: [タスク名]
- 原因: [何がブロックしているか]
- 必要なアクション: [何が必要か]
```

## タスク管理

### Leadの責務
- TaskCreate: タスク登録（subject・description・blockedBy を設定）
- TaskUpdate: ステータス更新・オーナー割当・依存関係設定
- TaskList: タスク一覧確認（完了確認・次のタスク特定）

### メンバーの責務
- TaskList: 割当可能なタスクの確認（各タスク完了後に実行）
- TaskUpdate: 自タスクのステータスを `in_progress` → `completed` に更新してから Lead に報告
- タスクを複数こなせる場合、TaskList で次の未割当タスクを確認して申し出る

## コミット規約

- 1コミット = 1論理変更（bisect commit原則）
- コミットメッセージは変更内容を簡潔に記述
- 複数の変更を1コミットにまとめない
- **Implementer**: プロダクションコードの変更をコミット
- **Tester**: テストコードの変更をコミット
- **Lead / Reviewer**: コミットしない

## プロジェクト情報

各プロジェクトの情報は `docs` ディレクトリ配下を参照すること。

## 品質基準

- すべてのコードはビルド・lintを通過すること
- テストカバレッジ90%以上を目標
- セキュリティ上のCRITICAL issueがある場合はマージしない

## チーム構成

| Agent | 役割 | 書き込み権限 | モデル |
|-------|------|------------|--------|
| Lead | オーケストレーター | なし（読み取り専用） | opus |
| Planner | 実装計画作成（Large タスク向け） | なし（読み取り専用） | opus |
| Implementer | プロダクションコード実装 | プロダクションコード | sonnet |
| Tester | テスト作成・実行 | テストコードのみ | sonnet |
| Reviewer | 品質・セキュリティレビュー | なし（読み取り専用） | sonnet |

## Agent定義ファイル

各agentの詳細なワークフロー・指示は以下を参照:

- `teams/dev/agents/lead.md` — Leadエージェント定義
- `teams/dev/agents/planner.md` — Plannerエージェント定義
- `teams/dev/agents/implementer.md` — Implementerエージェント定義
- `teams/dev/agents/tester.md` — Testerエージェント定義
- `teams/dev/agents/reviewer.md` — Reviewerエージェント定義
