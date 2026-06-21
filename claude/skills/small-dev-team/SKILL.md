---
name: small-dev-team
description: トークン節約版の開発チームスキル。Lead・Planner・Implementerの最小構成でプランニングと実装のみを行い、テストとレビューはユーザーが担当する。「small-dev-teamで実装して」「小さいチームで実装して」「テストとレビューは自分でやるので実装だけエージェントに任せたい」などの依頼が来たら必ずこのスキルを使用すること。個人プランや低トークン予算での開発タスクに適用する。
---

# Small Dev Team 共通ルール

このスキルはチーム全メンバーが読み込む共通ルール。

## コンセプト

**実装まで**をエージェントが担当し、**テスト品質監査とコードレビュー**はユーザーが担当する最小構成チーム。
Testerエージェントによる独立監査とReviewerエージェントは起動しない。

## 実装方針

ImplementerはCanon TDDに従って実装する（詳細は `claude/skills/tdd/SKILL.md` を参照）。

- Implementer自身がテストリストを作成してからTDDサイクルを開始する
- red-green-refactorサイクルを**1サイクル1テスト**で回す
- テストコードとプロダクションコードの両方を書く

TDDの鉄則（全員が遵守）:

- テストを書いたら**必ずRed（失敗）を自分の目で確認**してから実装する
- 1サイクルで扱うテストは常に1つだけ。気づいた追加ケースはテストリストに追記して後回し
- Greenの後にRefactorの余地を探す（任意。全テスト緑を保ったまま進める）

## チーム起動手順（Leadが実行）

### Step 1: チームを作成する

TeamCreateツールでチームを作成する:

- `team_name`: `small-dev-team`
- `description`: ユーザーのタスク概要

### Step 2: タスクを登録する

TaskCreateでタスクを登録する（subject・descriptionを設定）。
依存関係がある場合はTaskUpdateでblockedByを設定する。

### Step 3: メンバーを起動する

Agentツールで必要なメンバーのみを起動する。**`team_name: "small-dev-team"` と `name` パラメータを必ず指定する**:

- Implementer: `subagent_type: "implementer"`, `name: "Implementer"`, `team_name: "small-dev-team"`
- Planner（Largeタスクのみ）: `subagent_type: "planner"`, `name: "Planner"`, `team_name: "small-dev-team"`

**TesterとReviewerは起動しない。**

### Step 4: タスクを割り当てる

SendMessageでメンバーにタスクを割り当てる（`to` はメンバーの `name`）:

```json
{
  "to": "Implementer",
  "message": "タスク詳細（対象ファイル・期待する成果物・コンテキスト・TDD指示を含む）",
  "summary": "タスク名（5-10語）"
}
```

Implementerへの割当時は必ず以下を明記する:
- 「Canon TDD（`claude/skills/tdd/SKILL.md`）に従い、テスト先行・1サイクル1テスト・Red確認を徹底すること」
- 「**テストリストはImplementer自身が作成してからサイクルを開始すること**」

TaskUpdateで `owner` をメンバー名に設定してタスクのオーナーを明示する。

### Step 5: 進捗を管理する

- メンバーからの報告はSendMessageで自動配信される（手動確認不要）
- 完了報告を受けたらTaskUpdateでステータスを `completed` に更新する
- 次のタスクがunblockされたらSendMessageで該当メンバーに割り当てる

### Step 6: チームをシャットダウンする

全タスク完了後、各メンバーにSendMessageでシャットダウンを要求する:

```json
{
  "to": "Implementer",
  "message": { "type": "shutdown_request", "reason": "全タスク完了" },
  "summary": "シャットダウン要求"
}
```

全メンバーのシャットダウン確認後、ユーザーへ最終報告を行う。

## ワークフロー（複雑度別）

**Small（単一ファイル変更、明確な仕様）:**
- Implementerに直接TDDで実装を割当

**Medium（複数ファイル、中程度の仕様）:**
1. Implementerにテストリスト作成 + TDDサイクルを割当

**Large（多ファイル、複雑な仕様）:**
1. Plannerに調査・プラン作成を依頼
2. Plannerのプランをもとに、Implementerにテストリスト作成 + TDDサイクルを割当

Plannerのプランフォーマット:

```
## 実装プラン: [機能名]

### 概要
[2-3行の要約]

### 要件
- [要件1]

### アーキテクチャ変更
- [変更1: ファイルパスと説明]

### 実装フェーズ

#### Phase 1: [フェーズ名]
1. [ステップ名]（ファイル: path/to/file.ts）
   - 内容: 具体的なアクション
   - 依存: なし / ステップXが必要
   - リスク: Low / Medium / High

### テスト戦略（参考）
- Unit: [対象]
- Integration: [対象]
```

## ファイル所有権

- **Lead**: ファイル変更なし。Bashは読み取り専用コマンドのみ
- **Planner**: ファイル変更なし。Bashは読み取り専用コマンドのみ
- **Implementer**: インフラ設定（`.github/`, `.claude/`）以外のすべてのファイル。テストコードとプロダクションコードの両方を書く

## コミュニケーション規約

### 完了報告フォーマット

タスク完了時、**SendMessageツール**を使ってLeadへ報告する（プレーンテキストはLeadに届かない）:

```
## 完了報告
- タスク: [タスク名]
- 状態: 完了 / 一部完了 / ブロック
- 変更ファイル: [一覧]
- テストリスト: [作成したテストケース一覧]
- テスト実行結果: [pass/fail サマリー]
- 概要: [何をしたか]
- 注意点: [あれば]
```

### ブロック報告

作業がブロックされた場合、**SendMessageツール**で即座にLeadへ報告する:

```
## ブロック報告
- タスク: [タスク名]
- 原因: [何がブロックしているか]
- 必要なアクション: [何が必要か]
```

## 最終報告フォーマット（Leadがユーザーへ）

```
## 実装完了報告

### 概要
[何を実装したか]

### 変更内容
- [変更ファイルと変更内容の一覧]

### テスト実行結果
- [pass/fail サマリー]
- [Implementerが作成したテストケース一覧]

### 設計判断
- [重要な判断があれば、トレードオフと根拠]

---

**次のステップ（ユーザー担当）:**
- [ ] テスト品質の監査（エッジケースの不足がないか確認）
- [ ] コードレビュー（品質・セキュリティの確認）
```

## コミット規約

- 1コミット = 1論理変更（bisect commit原則）
- **Implementer**: TDDサイクルのred-greenペア（失敗テスト + それを通す最小実装）を1論理変更としてコミットしてよい。リファクタリングは別コミットに分ける
- **Lead / Planner**: コミットしない

## プロジェクト情報

各プロジェクトの情報は `docs` ディレクトリ配下を参照すること。

## 品質基準

- すべてのコードはビルド・lintを通過すること
- TDD準拠で実装すること（Redを必ず確認、1サイクル1テスト、テスト先行）

## チーム構成

| Agent | 役割 | 書き込み権限 | モデル |
|-------|------|------------|--------|
| Lead | オーケストレーター | なし（読み取り専用） | opus |
| Planner | 実装計画作成（Largeタスク向け） | なし（読み取り専用） | opus |
| Implementer | TDDドライバー（テストリスト作成 + テスト + 実装） | プロダクションコード + `tests/` | sonnet |

## Agent定義ファイル

- `claude/agents/lead.md` — Leadエージェント定義
- `claude/agents/planner.md` — Plannerエージェント定義
- `claude/agents/implementer.md` — Implementerエージェント定義
