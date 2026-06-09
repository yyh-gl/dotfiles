---
name: create-pr
description: カレントブランチの変更を確認したうえでGitHubにPRを作成する。「PRを作成して」「プルリクを作って」「PR出して」「create a PR」「open a pull request」など、ユーザーがPR作成の意図を示したら必ずこのスキルを使用すること。「create pr」と明示されなくても、現ブランチの変更をPRにしたい意図が見えたら迷わず起動する。
---

## 目的

現ブランチ（feature/topicブランチ）の変更を確認し、レビュー可能な**Draft PR**を`gh`コマンドで作成する。

PRはチームに公開されるレビュー依頼であり、コミットと違って後からの作り直しコストが高い。
そのため**作成前に必ずタイトル・本文をユーザーに提示して承認を得る**。

タイトル・本文は**日本語**が基本。ユーザーが言語を明示指定した場合はその言語に従う。

## Step 1: 前提とブランチの把握

PRは「あるブランチから別のブランチへの変更提案」なので、まずhead/baseを確定させる。

```bash
git branch --show-current                                  # head（現ブランチ）
gh repo view --json defaultBranchRef -q .defaultBranchRef.name  # base（デフォルトブランチ）
```

- **現ブランチがデフォルトブランチ（main等）の場合は中断**する。デフォルトブランチからは
  PRを作れないため、「先にfeatureブランチを切ってください」とユーザーに伝える。
- 既に同じheadのPRが存在しないか確認する:
  ```bash
  gh pr list --head "$(git branch --show-current)" --state open
  ```
  既存のオープンPRがあれば新規作成せず、そのPR番号・URLを報告して終了する。

## Step 2: 変更内容の把握

base..HEADの全差分を読み、「このブランチは一言で言うと何を変えるPRか」を掴む。
これが後のタイトル・概要の土台になる。

```bash
git log <base>..HEAD --oneline   # このブランチに含まれるコミット
git diff <base>...HEAD --stat     # 変更ファイルの俯瞰（3点リーダーで分岐点からの差分）
git diff <base>...HEAD            # 全差分
```

複数の目的が混ざっている場合でも、PRは1つにまとめる前提で「主目的」と「副次的な変更」を
整理しておく（本文の構成に使う）。

## Step 3: push状態の確認

PR作成にはheadブランチがリモートにpush済みである必要がある。
このスキルは`git push`を実行しない方針なので、未pushを検知したら**作成を中断してユーザーに依頼**する。

```bash
git status -sb                # ahead/behind とupstream設定の有無を確認
git log @{u}..HEAD --oneline  # upstream未設定ならこのコマンドはエラーになる
```

未pushコミットがある、またはupstreamが未設定の場合は、以下の形式で報告して終了する:

```
⚠️ 未pushのコミットがあります

未push: <件数> 件
<コミット一覧>

PR作成にはリモートへのpushが必要です。
`git push -u origin <branch>` を実行してから、再度PR作成を依頼してください。
```

## Step 4: PRテンプレートの確認

リポジトリにPRテンプレートがあれば、本文の見出し・章立てをそれに準拠させる
（テンプレートはチームが求めるPRの書式なので尊重する）。

確認する場所:

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE/`（複数テンプレート）配下のファイル
- リポジトリ直下の `PULL_REQUEST_TEMPLATE.md`

テンプレートが見つかれば、その各セクションを変更内容で埋める。
無ければStep 6のデフォルト構成を使う。

## Step 5: セキュリティチェック

PRはコードを外部に公開するため、差分に**Git/GitHubに載せるべきでない情報**が含まれていないか確認する。

| カテゴリ | 具体例 |
|----------|--------|
| 認証情報 | パスワード、APIキー、シークレットキー、トークン |
| 証明書・鍵 | 秘密鍵（`-----BEGIN ... KEY-----`）、`.pem`/`.key`/`.p12` |
| クラウド認証情報 | AWS Access Key ID/Secret、GCP service account JSON |
| 個人情報 | コードに埋め込まれたメールアドレス・電話番号・住所 |
| 環境固有の設定 | `.env`、本番DBの接続文字列 |
| 内部URL | 社内ホスト名、プライベートIPアドレス |

該当するものが見つかった場合は**PRを作成せず**、ファイル名・該当箇所・理由をユーザーに報告する。

## Step 6: タイトルと本文の生成

### タイトル

簡潔に1行で。`<type>(<scope>): <subject>` 形式を基本とする（`smart-commit`のtype/scope規約と整合）。

- subjectは本文の言語（デフォルト日本語）。
- 単一コミットのブランチなら、そのコミットの主旨を要約する。
- 例: `feat(auth): リフレッシュトークン対応を追加`

### 本文（テンプレートが無い場合のデフォルト構成）

```markdown
## 概要

<なぜこの変更をするのか・背景。レビュアーが最初に読む部分>

## 変更内容

- <主な変更点を箇条書き>

## 動作確認

- <どう検証したか。未検証なら「未検証」と明記する>

## 補足

<任意。レビュー時の注意点・既知の制約・関連Issueなど>
```

「概要」は差分の列挙ではなく**目的・背景**を書く。「何を変えたか」は変更内容に、
「なぜ変えるか」は概要に分けると、レビュアーが意図を掴みやすい。

## Step 7: ユーザーへの提示と確認

`gh pr create`を実行する**前に**、以下をまとめて提示し承認を得る:

```
作成するPR（Draft）:

base ← head: <base> ← <head>
タイトル: <title>

本文:
---
<本文全文>
---

この内容で作成してよいですか？
```

ユーザーが修正を求めたら反映して再提示する。**承認が取れるまで`gh pr create`は実行しない。**

## Step 8: PR作成

本文は改行・整形を保つため一時ファイル経由で渡す:

```bash
tmpfile=$(mktemp)
cat > "$tmpfile" <<'EOF'
<本文全文>
EOF
gh pr create --draft --base <base> --title "<title>" --body-file "$tmpfile" --assignee @me
rm -f "$tmpfile"
```

作成後、`gh`が返すPRのURLをユーザーに報告する。

## 注意事項

- `git push`は実行しない。未pushがあればStep 3でユーザーにpushを依頼する。
- **ユーザー承認なしにPRを作成しない**（`smart-commit`と異なり確認は必須）。
- デフォルトブランチ上では実行しない。
- 同じheadのオープンPRが既にあれば新規作成しない。
- **assigneeは常に作成者自身（`--assignee @me`）を指定する。**
- reviewer/labelは付与しない。ユーザーが明示的に指定した場合のみ
  `--reviewer` `--label` を追加する。assigneeを追加で指定したい場合も同様に追加する。
- 常にDraft（`--draft`）で作成する。Ready化はユーザーの判断に委ねる。
