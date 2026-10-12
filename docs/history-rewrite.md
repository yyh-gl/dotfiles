# 公開履歴から個人情報を消す手順（`mn`エイリアス（自宅の物件名と市区町村を含む`cd`先）は、旧履歴の`feat(Zsh): add mn alias`（`3fcdd92`）で入り、`nix/home/zsh.nix`に載っていた。

## 現在の状態

- **main**: 履歴の書き換えは実施済み。該当の文字列は`REDACTED`に置換され、`chore(Zsh): remove unused mn alias`でエイリアス自体も削除されている。全履歴・現在のツリー・コミットメッセージのどこにも文字列は残っていない（`git log -S`で確認済み）
- **旧履歴を持つブランチ**: 書き換え前の`claude/adversarial-review-plan`には、文字列を含むコミットが残っている。書き換え後のmainにこのブランチを`merge`すると、旧履歴ごと文字列がmainに戻るため、`merge`せず、新しいmainの上に付け替えたブランチ（`claude/adversarial-review-plan-rebased`）を使う。旧ブランチはリモートから削除する（下の手順6）
- **GitHub側**: `refs/pull/*`とキャッシュされたビューに旧コミットが残る可能性がある。GitHubサポートへの削除依頼は、まだ必要

以下は、同じ作業をもう一度する必要が出たとき（別の文字列を消したいときなど）の手順。

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
   - 書き換え前の履歴を持つブランチ（`claude/*`など）は、`git rebase --onto origin/main <旧mainの先頭>`で書き換え後のmainの上に付け替えてから、旧ブランチをリモートから削除する（`git push origin --delete <旧ブランチ>`）。`merge`すると旧履歴が戻る

## 再発防止

住居・勤務先などの個人情報は、リポジトリに載せず`~/.zshrc.local`（Nix管理外）に書く。`zsh.nix`は`~/.zshrc.local`があれば読み込む。
