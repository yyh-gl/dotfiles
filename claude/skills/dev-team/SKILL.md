---
name: dev-team
description: devチームを起動するスキル。Lead・Planner・Implementer・Tester・Reviewerの5 agentが協調して機能実装・テスト・レビューを実行する。「開発チームを作成して」「dev teamで実装して」「チームで開発したい」「エージェントチームで〇〇を実装して」などの依頼が来たら必ずこのスキルを使用すること。開発タスク全般（機能追加・バグ修正・リファクタリング）でチームを組んで作業する場合に適用する。
---

# Dev Team 共通ルール

チーム全メンバーが読み込む共通ルール。各自の役割に必要なファイルだけを読み、メッセージは簡潔に保つこと。

## 実装方法論: Canon TDD

本チームは**Canon TDD**（`~/.claude/skills/tdd/SKILL.md`）に準拠する。方法論はそこを参照し、再記述しない。Implementerは実装着手時に読み込む（`references/`は必要時のみ）。

役割分担: **Tester**がテストリスト（自然言語の箇条書き）を作成 → **Implementer**がred-green-refactorサイクルを1サイクル1テストで回す（テストとプロダクションコードの両方を書く）→ **Tester**が全サイクル完了後に品質監査・エッジケース追加 → **Reviewer**が品質・セキュリティレビュー。

TDDの鉄則（全員が遵守）:

1. テストを書いたら必ず実行してRed（失敗）を自分の目で確認してから実装する
2. 1サイクル1テスト。気づいた追加ケースはテストリストに追記して後回し
3. Greenの後にRefactorの余地を探す（任意。全テスト緑を保ったまま進める）

## 成果物の受け渡し（トークン規律）

- 実装プラン・テストリスト等の成果物は`.dev-team/`配下のファイルに書き、SendMessageには**ファイルパスと5行以内の要約のみ**を載せる。全文をメッセージに貼らない
- `.dev-team/`は全メンバーが書き込み可（読み取り専用ロールの唯一の例外）。コミットしない
- メッセージ・報告にはコード全文や長いログを貼らず、パスと要点のみを書く
- 一度読んだスキル・agent定義を再読み込みしない

## チーム起動手順（Leadが実行）

1. **TeamCreate**でチーム作成: `team_name: "dev-team"`、`description`にタスク概要
2. **TaskCreate**でタスク登録（subject・description）。依存関係はTaskUpdateでblockedBy設定
3. **Agentツールでメンバー起動**。`team_name: "dev-team"`と`name`を必ず指定する（指定しないとチームに参加できない）。例: `subagent_type: "implementer"`, `name: "Implementer"`, `team_name: "dev-team"`（tester/reviewer/plannerも同様）。**複雑度に応じて必要なメンバーのみ起動する**（判断基準は`~/.claude/agents/lead.md`）
4. **SendMessage**でタスク割当（`to`=メンバー名、`message`=対象ファイル・期待成果物・コンテキスト、`summary`=タスク名5-10語）。TaskUpdateで`owner`を設定
5. 進捗管理: メンバーの報告はSendMessageで自動配信される。完了報告を受けたらTaskUpdateで`completed`に更新し、unblockされたタスクを次のメンバーに割当
6. 全タスク完了後、各メンバーに`{"type": "shutdown_request", "reason": "全タスク完了"}`をSendMessageし、全員の確認後にユーザーへ最終報告

## ファイル所有権

| ロール | 書き込み範囲 |
|---|---|
| Lead / Planner / Reviewer | なし（読み取り専用。Bashも`git log`等の読み取り系コマンドのみ）。`.dev-team/`のみ書き込み可 |
| Implementer | インフラ設定（`.github/`, `.claude/`）以外のすべて。TDDサイクル中はテストも書く |
| Tester | テストコード・テスト設定のみ（`tests/`, `test/`, `__tests__/`, `*.test.*`, `*.spec.*`, `jest.config.*`等） |

`tests/`はImplementerとTesterの**逐次所有**（同時編集禁止）: ImplementerのTDDサイクル完了後にTesterが監査・追記に入る。

## 報告フォーマット

完了・ブロック時は**SendMessageで**Leadへ報告する（プレーンテキスト出力はLeadに届かない）:

```
## 完了報告（またはブロック報告）
- タスク: [名前] / 状態: 完了・一部完了・ブロック
- 変更ファイル: [パスのみ列挙]
- 概要・注意点: [簡潔に。成果物はパス参照]
（ブロック時: 原因と必要なアクション）
```

役割固有のセクション（テスト結果・レビュー判定等）は追加してよい。

## タスク管理

- **Lead**: TaskCreate・TaskUpdate・TaskListでタスク・依存・オーナーを管理
- **メンバー**: 着手時に`in_progress`、完了時に`completed`へTaskUpdateしてから報告。手が空いたらTaskListで次の未割当タスクを確認して申し出る

## コミット規約

- コミットは**smart-commitスキル**（`~/.claude/skills/smart-commit/SKILL.md`）を使用する。コミットする直前に読み込めばよい
- 1コミット=1論理変更（bisect commit原則）。Implementerはred-greenペア（失敗テスト+最小実装）を1コミットとし、リファクタリングは別コミット。Testerは追加・修正したテストをコミット。Lead・Reviewerはコミットしない
- `.dev-team/`はコミットに含めない

## 品質基準

- すべてのコードはビルド・lintを通過すること
- TDD準拠（Red確認・1サイクル1テスト・テスト先行）
- テストカバレッジ90%以上を目標（TDDの結果として検証する指標）
- セキュリティ上のCRITICAL issueがある場合はマージしない

## チーム構成

| Agent | 役割 | モデル | 定義ファイル |
|---|---|---|---|
| Lead | オーケストレーター（読み取り専用） | fable | `~/.claude/agents/lead.md` |
| Planner | 実装計画作成（Largeタスクのみ） | fable | `~/.claude/agents/planner.md` |
| Implementer | TDDドライバー（テスト+実装） | sonnet | `~/.claude/agents/implementer.md` |
| Tester | テストリスト作成・品質監査 | sonnet | `~/.claude/agents/tester.md` |
| Reviewer | 品質・セキュリティレビュー（読み取り専用） | fable | `~/.claude/agents/reviewer.md` |

各プロジェクトの情報は`docs/`配下を参照すること。
