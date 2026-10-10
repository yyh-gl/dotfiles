# Upstream

Vercel Engineeringが公開しているスキル（SKILL.mdのfrontmatter: author `vercel`、version `1.0.0`、license MIT）をそのまま取り込んだコピー。

- 変更点は、存在しないファイルを指していた`rules/_sections.md`の参照行を`SKILL.md`から削除したことだけ
- ルールの内容は第三者のものなので、このリポジトリではレビュー・修正しない
- Anthropicの公式marketplace（`extraKnownMarketplaces`に登録済みの`claude-plugins-official`・`anthropic-agent-skills`）にはこのスキルが見つからなかったため、プラグイン化はしていない。プラグインとして配布されていることを確認できたら、このディレクトリを削除してプラグインに置き換える
- 更新するときは、upstreamの最新版でディレクトリごと置き換え、この変更点（上記の参照行）が必要か確認する
