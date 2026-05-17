---
name: codex-review
description: Collaborative review skill that pairs Claude's independent analysis with Codex's independent perspective, then synthesizes findings into a final report. Use this skill whenever the user asks for a review, audit, analysis, or feedback on code, documents, or any content — especially when thoroughness matters. Activate even if the user doesn't mention "Codex" or "collaborative": trigger on phrases like "review this", "please check", "audit", "what do you think of this code", "is this document clear", "security review", "code review", "performance review". The two-AI synthesis approach is particularly valuable for catching issues that a single reviewer might miss.
---

# Codex Collaborative Review

Claude と Codex が独立してレビューを行い、両者の視点を統合した最終レビューを提示するスキル。

## 入力の確認

ユーザーから以下を受け取る：

1. **レビュー対象**: ファイルパス、コードスニペット、またはドキュメント内容
2. **レビュー観点**: 何に着目するか（例: セキュリティ、パフォーマンス、可読性、正確性、アーキテクチャ）

観点が明示されていない場合は確認する：
> 「どの観点でレビューしますか？（例: セキュリティ、パフォーマンス、可読性、設計、正確性）」

## ワークフロー

### Step 1: 対象を読み込む

ファイルパスが指定された場合は `Read` ツールで読み込む。インラインで貼られた場合はそのまま使用する。
大規模なコードベースの場合は、関連する主要ファイルに絞って対象を明示する。

### Step 2: Claude による独立レビュー

指定された観点で徹底的にレビューする。この段階では結果をユーザーに見せない。以下の構造でメモしておく：

```
【Claudeのレビュー（内部用）】

総評: [2〜3文の全体評価]

指摘事項:
- Critical（致命的）: ...
- Major（重要）: ...
- Minor（軽微）: ...
- Positive（良い点）: ...

推奨事項: [具体的なアクション]
```

### Step 3: Codex による独立レビュー

`mcp__codex__codex` を使い、Codex に同じ観点でレビューを依頼する。

**Codex へのプロンプト例：**

```
以下の[コード/ドキュメント]を「[観点]」の観点でレビューしてください。

---
[レビュー対象の全文をここに貼る]
---

以下の構造でレビュー結果を教えてください：
1. 総評（2〜3文）
2. 指摘事項（Critical / Major / Minor / Positive に分類）
3. 推奨事項（具体的なアクション）
```

Codex の回答を受け取り、追加の確認が必要な場合は `mcp__codex__codex-reply` で続ける。

### Step 4: 両者の結果を比較・統合

Claude と Codex の指摘を突き合わせる：

| 分類 | 意味 | 扱い |
|------|------|------|
| **両者一致** | 両方が同じ問題を指摘 | 最優先・高信頼度 |
| **Claude のみ** | Claude だけが指摘 | 記載（出典: Claude） |
| **Codex のみ** | Codex だけが指摘 | 記載（出典: Codex） |
| **見解の相違** | 深刻度や推奨が異なる | 両視点を併記 |

### Step 5: 最終レビューを提示

以下のフォーマットでユーザーに提示する：

---

## レビュー結果: `[対象ファイル名 or 対象の概要]`

**観点**: [レビュー観点]  
**レビュアー**: Claude + Codex

### 総評

[両者の評価を統合した 3〜4 文のサマリー。全体的な品質と最重要ポイントを伝える]

### コンセンサス指摘（両者一致）

> 信頼度が高い。優先的に対処を推奨。

[両者が独立して指摘した問題を列挙]

### 追加指摘（一方のみ）

[どちらか一方のみが指摘した内容。出典を明示]

### 推奨アクション

[優先度順の具体的なアクションリスト。"何を・どこで・どう直すか" を明示]

### 各レビュアーの視点

- **Claude**: [Claudeの全体的な評価・着目点を 1〜2 文で]
- **Codex**: [Codexの全体的な評価・着目点を 1〜2 文で]

---

## 注意事項

- Codex が応答を返さない・エラーになる場合は、Claude 単独のレビュー結果を提示し、その旨を明記する。
- 対象が大きすぎる場合、最も重要なファイル・セクションに絞ってレビュー範囲を明示する。
- 総合レビューは「網羅的なリスト」ではなく「何が最も重要か」を伝えることを優先する。
