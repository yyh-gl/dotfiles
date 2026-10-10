# 公開履歴から個人情報を消す手順（`mn`エイリアス）

`mn`エイリアス（自宅の物件名と市区町村を含む`cd`先）は、`feat(Zsh): add mn alias`（`3fcdd92`）で入り、`origin/main`の`nix/home/zsh.nix`に今も残っている。`claude/adversarial-review-plan`ブランチでは削除済み（`~/.zshrc.local`へ移す運用）だが、**mainに取り込まれるまでmainには残る**し、**過去のコミットには残り続ける**。このドキュメントは、履歴ごと消したくなったときにユーザー自身が実行するための手順で、実行は自動化していない。

## 先に知っておくこと

- 履歴を書き換えてforce pushしても、公開済みの情報は完全には消えない。すでにクローン・fork・検索エンジンやアーカイブに取られた分は戻せない
- 書き換えると、全コミットのハッシュが変わる。他のブランチ、オープン中のPR、他のマシンのクローンはすべて古い履歴を指したままになる
- GitHubのPR用の参照（`refs/pull/*`）とキャッシュされたビューには古いコミットが残る。完全に消すにはGitHubサポートへの削除依頼が要る
- 効果と手間が釣り合わないと判断したら、やらないのも妥当。HEADから消してあれば、これ以上は増えない

## 手順

`git-filter-repo`が必要（Nixでは入れていない）: `brew install git-filter-repo`

1. 作業用にミラークローンを作る（普段のクローンでは実行しない）

   ```sh
   git clone --mirror git@github.com:yyh-gl/dotfiles.git /tmp/dotfiles-rewrite.git
   cd /tmp/dotfiles-rewrite.git
   ```

2. 置き換え対象を、リポジトリの外のファイルに書く。**消したい文字列そのものは、このリポジトリにコミットしない**

   ```sh
   # 1行1パターン。左が消したい文字列（物件名・市区町村・パスの一部など）、右が置換後
   printf '%s\n' '<消したい文字列>==>REDACTED' > /tmp/replace.txt
   ```

3. 書き換える

   ```sh
   git filter-repo --replace-text /tmp/replace.txt
   ```

4. 残っていないことを確認する（何も出なければよい）

   ```sh
   git log --all -S'<消したい文字列>' --oneline
   ```

5. mainなど保護ブランチの保護を一時的に外し、書き換えた履歴をforce pushする

   ```sh
   git remote add origin git@github.com:yyh-gl/dotfiles.git   # filter-repoはoriginを外す
   git push --force --all origin
   git push --force --tags origin
   ```

6. 後始末
   - 他のマシンのクローンは捨てて、クローンし直す（`git pull`ではつながらない）
   - オープン中のPRと他のブランチ（`claude/*`など）は、書き換え後の履歴に作り直すか閉じる
   - GitHubサポートに、古いコミットとキャッシュ、`refs/pull/*`の削除を依頼する
   - 保護ブランチの保護を元に戻す
   - 消したあとにこのブランチ（`claude/adversarial-review-plan`）をmainに取り込む場合は、書き換え後の履歴に対してやり直す

## 再発防止

住居・勤務先などの個人情報は、リポジトリに載せず`~/.zshrc.local`（Nix管理外）に書く。`zsh.nix`は`~/.zshrc.local`があれば読み込む。
