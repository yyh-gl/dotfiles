---
name: smart-commit
description: カレントブランチの差分を分析し、適切な粒度で自動的にgitコミットを作成する。「コミットして」「差分をコミット」「変更をコミット」「commit the changes」「commit the diff」など、ユーザーが変更をコミットしたいと伝えてきた場合は必ずこのスキルを使用すること。「smart commit」と明示されなくても、未ステージ/ステージ済みの変更をコミットしたい意図が見えたら迷わず起動する。
---

## 目的

作業ディレクトリの全変更を分析し、**論理的な変更単位ごとに**1コミットを作成する。
コミットメッセージはすべて英語のSemantic Commit Messages形式に従う。

「論理的な変更単位」とは、1つの目的・意図のこと。
「この変更群を一文で説明できるか？」という問いに答えられるなら1コミット。
説明が「〜、かつ〜」と続くなら2つに分ける。

## Step 1: 全差分を把握する

以下のコマンドで変更の全体像を確認する：

```bash
git status
git diff HEAD
git log --oneline -5
```

ステージング状態は無視し、常にHEADからの全差分を対象にする。

## Step 2: 変更を論理単位でグルーピングする

差分を読み込み、**目的が共通するファイル/ハンク**をひとまとめにする。
「ファイルの場所」ではなく「何をしているか」で判断する。

**グルーピングの例：**
- 新機能 + そのテスト → 1コミット（同じ意図で追加されたため）
- バグ修正 + 無関係なフォーマット修正 → 2コミット
- 認証ミドルウェアの書き直し + それを支えるDBスキーマ変更 → 1コミット（同一機能）
- 同じファイル内に2つの別機能の変更 → `git add -p` で分割して2コミット

**判断に迷ったときは分割を優先する。**

## Step 3: 各グループのコミットメッセージを決定する

フォーマット: `<type>(<scope>): <subject>`

### type — ユーザー/コードベースへの影響で選ぶ

| type | 使いどころ |
|------|-----------|
| `feat` | ユーザー向けの新機能 |
| `fix` | ユーザー向けのバグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | フォーマット・空白・セミコロンなど（ロジック変更なし） |
| `refactor` | 振る舞いを変えないコードの整理 |
| `test` | テストの追加・修正のみ |
| `chore` | ビルドスクリプト・ツール・依存関係（本番コード変更なし） |

### scope — 必ず付ける

ファイルパスをそのまま使うのではなく、変更が**意味的に属するシステム・機能・概念**を表す単語を選ぶ。

- `auth` … 認証・認可
- `user` … ユーザープロフィール・アカウント
- `api` … APIレイヤー
- `db` … データベース・スキーマ
- `ui` … 画面・コンポーネント
- `config` … 設定ファイル

変更が複数の無関係なドメインにまたがり、1語で表現できない場合のみスコープを省略する: `feat: implement X`

### subject — 命令形・現在形・英語

- "add JWT refresh token support" ✓
- "added JWT refresh token support" ✗（過去形NG）
- "adds JWT refresh token support" ✗（三単現NG）
- 72文字以内

**例:**

```
feat(auth): add JWT refresh token support
fix(api): handle nil pointer in user lookup
refactor(db): extract query builder into separate package
test(auth): add coverage for token expiry edge cases
chore(deps): upgrade go.mod dependencies
docs(api): document rate limiting behavior
style(ui): fix inconsistent button spacing
```

## Step 4: グループごとにステージ＆コミットする

各論理グループについて順番に：

1. `git add <files>` または `git add -p`（ハンク単位の場合）で対象をステージ
2. `git commit -m "<message>"` でコミット
3. 次のグループに進む前に `git status` で確認

コミット順は依存関係を考慮する（スキーマ・設定などの基盤変更を先に、機能変更を後に）。

## 注意事項

- 無関係な変更をまとめてコミット数を減らすことはしない
- 1ファイルに2つの異なる変更がある場合は `git add -p` で分割する
- ユーザーへの確認は不要 — 全グループを自動的にコミットする
- 全コミット完了後、`git log --oneline -10` を実行して結果を表示する
