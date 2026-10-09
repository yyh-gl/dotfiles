# dotfiles敵対的レビューとリファクタリング提案

対象: `fde9818`時点のリポジトリ全体（Nix・Makefile・bin・zsh・Claude/Codex設定・hooks・mods・skills/agents・各種アプリ設定・CI）。
このファイルはプランであり、コードは変更していない。各項目は「問題 → 起きること → 対応案」の順に書いている。

重大度:

- **P0**: 設定が効いていない、または意図した防御を破れる
- **P1**: 特定の条件（workモード・初回セットアップなど）で壊れる、または防御に穴がある
- **P2**: ドキュメントと実装のずれ、死んだ設定、保守性の問題
- **R**: 動作は正しいがより良い書き方がある（リファクタリング提案）

「要検証」は実機での確認が必要なもの。確認方法を併記している。

---

## P0

### P0-1 `defaults.nix`のactivation scriptが一度も実行されていない

- 場所: `nix/darwin/defaults.nix:44`（`system.activationScripts.customDefaults`）、`:86`（`system.activationScripts.powerManagement`）
- 問題: `nix/darwin/claude-code.nix:5-6`自身が「`system.activationScripts.<任意の名前>.text`はnix-darwinの実行リストに含まれず呼ばれない」と書いているのに、`defaults.nix`は任意の名前を使っている。nix-darwinは`preActivation`・`postActivation`・`extraActivation`など決まった名前しか実行しない。
- 起きること: HIToolboxのimport（入力ソース設定）、コントロールセンターのBluetooth/サウンド/バッテリー%表示、入力ソース切替ショートカットの無効化、Command+`の割り当て、`pmset -c sleep 0`のどれも適用されていない。新しいMacで再現しない。
- 追加の問題: 仮に`postActivation`へ移しても、nix-darwinのactivationはrootで動くため、`defaults write`はrootのドメインに書かれ、PlistBuddyはユーザーのplistをroot所有で書き戻す可能性がある。
- 対応案:
  - コントロールセンター系はnix-darwinのオプション（`system.defaults.controlcenter.BatteryShowPercentage`・`.Bluetooth`・`.Sound`）へ移す
  - symbolichotkeys・HIToolboxは`system.defaults.CustomUserPreferences`（`system.primaryUser`として書かれる）へ移す。HIToolboxのplistはNixの属性セットに展開する。`.defaults/com.apple.HIToolbox.plist`には`AppleInputSourceHistory`のような履歴（毎回変わる状態）も入っているので、`AppleEnabledInputSources`など意図した設定だけを残す
  - `pmset`は`power.sleep.computer`等のnix-darwinオプションを検討する。AC電源限定（`-c`）が必要なら`postActivation`に残す
  - 残すものは`postActivation`に`lib.mkAfter`で追記し、ユーザー領域は`sudo -u ${username}`で実行する
- 検証: `darwin-rebuild switch`後に`defaults read com.apple.controlcenter`・`pmset -g custom`で反映を確認する。activationのログに該当コマンドの出力が出ないことで現状の未実行も確認できる

### P0-2 pre-push hookがpushされるコミットをスキャンしていない

- 場所: `hooks/pre-push:2`
- 問題: `gitleaks protect --staged`はindex（ステージ済みの変更）をスキャンする。pre-pushの時点で秘密情報はすでにコミットに入っており、indexは通常空か無関係。
- 起きること: 秘密情報を含むコミットをpushしても止まらない。CIのgitleaks（`.github/workflows/gitleaks.yml`）が拾うのは**push後**で、公開リポジトリなら手遅れ。
- 対応案: 次のどちらか（両方でもよい）。
  - pre-commit hookへ移す（`gitleaks git --staged`。v8.19以降の`protect`は非推奨）
  - pre-pushに残すなら、stdinで渡される`<local sha> <remote sha>`からレンジを作り、`gitleaks git --log-opts="<remote>..<local>"`でpush対象のコミットをスキャンする（新規ブランチはremote shaが0なので`--not --remotes`を使う）
- Makefileの`gitleaks detect`/`protect`も`gitleaks git`へ移行する
- pre-commitへ移す場合、`Bash(git commit*)`のallowが`git commit --no-verify`・`git commit -n`にも一致するので、Claudeがhookを飛ばせる。`Bash(git commit *--no-verify*)`と`-n`をdenyに足す（Codexも同様）

### P0-3 `gh`がsandbox外で動くため、ask/denyにない書き込み系サブコマンドが素通りする

- 場所: `claude/managed-settings.json:412-416`（`excludedCommands`の`gh *`）、`:118-133`（ask）
- 問題: askは`pr create`・`api`など一部の列挙で、次のような書き込み・認証系が抜けている。これらはsandbox外で、ルール上は確認なしで実行できる（auto modeの分類器だけが頼り）。
  - `gh auth token` / `gh auth status -t`: トークンを平文でClaudeのコンテキストに出す
  - `gh ssh-key add` / `gh gpg-key add`: 攻撃者の鍵をアカウントに登録できる
  - `gh extension install`: 任意コードをsandbox外で実行する経路になる
  - `gh repo edit|rename|archive|fork|sync|deploy-key`・`gh pr comment|review|ready|reopen`・`gh issue comment|delete|transfer`・`gh release edit|delete|upload`・`gh run cancel|rerun|delete`・`gh variable *`・`gh label *`・`gh cache delete`・`gh codespace *`・`gh poi`（ローカルブランチ削除）
- 起きること: `gh auth token`で得たトークンを`git push https://x:<token>@github.com/...`に埋め込むと、`github.com`は許可ドメインなので、`git push*`のdenyを`git -C . push`の形で回避したうえでpushできる。`docs/codex-sandbox.md`が書く「実質の防御はsandbox」の前提が崩れる。
- 対応案:
  - `Bash(gh auth *)`・`Bash(gh ssh-key *)`・`Bash(gh gpg-key *)`・`Bash(gh extension *)`は**deny**にする（Claudeに使わせる理由がない）
  - 上の書き込み系サブコマンドをaskに追加する。Codexの`prefix_rules`にも同じものを足す（AGENTS.mdのルール）
  - 中長期では、列挙をやめてPreToolUse hookで「`gh`の参照系だけallow、それ以外はask」を実装する（R-6）

---

## P1

### P1-1 sandboxから書き込めるキャッシュ経由で、sandbox外のビルドを汚染できる

- 場所: `claude/managed-settings.json:345-352`、`codex/requirements.toml:24-29`
- 問題: `~/Library/Caches/go-build`（GOCACHE）・`~/go/pkg/mod`・`~/.gradle`をsandbox内から書き込み可能にしている。
  - GOCACHEのエントリはビルド時に再検証されないため、改ざんしたオブジェクトが後でsandbox外（IDE・ターミナル）の`go build`にリンクされる
  - `~/go/pkg/mod`の展開済みファイルもダウンロード時にしか検証されない
  - `~/.gradle/init.d/*.gradle`はすべてのGradleビルドで実行される。sandbox内から置けばIDEからのビルドで任意コードが動く。`~/.gradle/gradle.properties`にはトークンが入りがちで、denyもされていない
- 起きること: プロンプトインジェクションを受けたエージェントが、sandboxの外で動く永続的な足場を作れる。
- 対応案（どれを採るかはトレードオフ）:
  - sandbox用に`GOCACHE`・`GOMODCACHE`・`GRADLE_USER_HOME`を別ディレクトリへ向ける（`env`で`$TMPDIR`配下など）。共有キャッシュには書かせない
  - 少なくとも`~/.gradle/init.d`・`~/.gradle/init.gradle`・`~/.gradle/gradle.properties`をdenyWrite（Claude: `Edit(...)`のdeny、Codex: 該当パスを`read`に）する
  - 採らない場合は、リスクを受け入れた旨を`docs/codex-sandbox.md`に書く

### P1-2 認証情報のdenyリストが実際に入れているツールに追いついていない

- 場所: `claude/managed-settings.json:98-117,354-411`、`codex/requirements.toml:37-56`
- 問題: Nix/Homebrewで入れているツールの認証情報が読める。
  - `~/.config/gcloud/`（`google-cloud-sdk`。`application_default_credentials.json`・`credentials.db`）
  - `~/.docker/config.json`（`docker-desktop`。レジストリ認証）
  - `~/.terraform.d/credentials.tfrc.json`（`terraform`）
  - `~/.npmrc`・`~/.netrc`・`~/.git-credentials`・`~/.pypirc`・`~/.gradle/gradle.properties`
  - `~/.config/op/`（1Password CLI）
- 対応案: 上記を`sandbox.credentials.files`・`permissions.deny`の`Read(...)`・Codexの`deny_read`の3か所に足す。3か所の手作業同期そのものはR-1で解消する

### P1-3 `.env`を全シェルに`set -a`で読み込んでおり、秘密がすべての子プロセスに渡る

- 場所: `nix/home/zsh.nix:80-87`、`claude/hooks/slack-notify.sh:68`
- 問題: dotfilesの`.env`（`AI_AGENTS_SLACK_WEBHOOK_URL`など）をexportしてから`claude`・`codex`を起動するため、sandbox内のコマンドが`env`で読める。`sandbox.credentials.envVars`・Codexの`exclude`は名前の列挙で、`*_URL`のような名前は漏れる（Codexのdefault excludesもKEY・SECRET・TOKENだけ）。
- 対応案:
  - `.env`を全シェルにexportするのをやめ、使う場面（slack-notifyなど）でだけ読む
  - 続けるなら、`.env`に置く変数名をenvVarsのdenyとCodexの`exclude`に足す。Codexは`exclude`がglobを受け付けるなら`*_WEBHOOK_URL`のように書く

### P1-4 HTTPS経由の`git push`が`gh`のcredential helperで通る可能性がある（要検証）

- 場所: `nix/home/gh.nix`（`programs.gh`。home-managerの`gitCredentialHelper.enable`は既定でtrue）、`.git-config/config`
- 問題: home-managerは`github.com`のcredential helperに`gh auth git-credential`を登録する。`gh`のトークンは現在の既定でmacOSのキーチェーンに入り、`~/.config/gh/hosts.yml`には入らない。`hosts.yml`のdenyでは守れていない可能性がある。`github.com`は許可ドメインなので、HTTPSのremoteを持つリポジトリでは`git -C . push`（`git push*`のdenyにかからない）が通るかもしれない。
- 検証: HTTPS remoteのテスト用リポジトリで、Claudeのsandbox内から`git -C . push --dry-run`を実行する
- 対応案: 通るなら`programs.gh.gitCredentialHelper.enable = false`にするか、sandboxで`git push`系を実際に止める手段（`git config --global`の`pushurl`無効化は不可なので、PreToolUse hookで`git`の引数を解析して`push`をdeny）を入れる

### P1-5 `docker`の前置オプションでaskを迂回できる

- 場所: `claude/managed-settings.json:134-179`、`codex/requirements.toml:105-150`
- 問題: askは前方一致のため、`docker compose -f x.yml up`・`docker compose --profile p run`・`docker -H tcp://... run`・`docker --context c exec`はどれにも一致しない。`docker *`はsandbox外で動く。
- 対応案: `docker * run *`のような中間ワイルドカードがClaudeで使えるかを確認し、使えれば足す。使えなければPreToolUse hookで`docker`の引数からオプションを読み飛ばしてサブコマンドを判定する（R-6と同じ仕組み）

### P1-6 workモードで`~/.claude/settings.json`を毎回上書きし、Claude Codeが書く可変設定を消す

- 場所: `nix/home/claude.nix:49-54`
- 問題: `install`で`managed-settings.json`をそのまま`~/.claude/settings.json`に置くため、CLAUDE.mdが「`~/.claude/settings.json`側に残す」と書いている`enabledPlugins`・`effortLevel`などがapplyのたびに消える。
- 追加の問題: user層はproject層（`.claude/settings.json`）に上書きされる。workモードでは、クローンしたリポジトリの`.claude/settings.json`が`sandbox.enabled: false`・広い`allow`・任意の`hooks`を持ち込める。managedとuserでは強さがまったく違うが、CLAUDE.mdにはその記述がない。
- 対応案:
  - `jq -s '.[0] * .[1]'`で既存の`settings.json`と`managed-settings.json`をマージし、managed側のキーだけを上書きする
  - workモードでは保護がuser層止まりであることをCLAUDE.mdに明記する

### P1-7 darwin側のmanaged settings配置がworkモードでも無条件に走る

- 場所: `nix/darwin/claude-code.nix:7-15`
- 問題: CLAUDE.mdは「仕事PCでは`/Library/Application Support/`への書き込みがMDMでブロックされることが多い」と書くが、配置は`mode`を見ずに必ず実行される。nix-darwinのactivationは`set -e`で動くので、`mkdir`/`cp`の失敗で`postActivation`の残り（`codex.nix`の配置を含む）が止まる。
- 対応案: 失敗したら警告だけ出して続ける（`if ! mkdir ...; then echo warning >&2; else ...; fi`）か、`mode == "work"`では試みてダメなら飛ばす。`specialArgs`で`mode`はdarwin側にも渡っている

### P1-8 commit署名鍵がhobbyモードでしか配置されず、workモードの全コミットが失敗する

- 場所: `.git-config/config:4,37-38`、`nix/home/default.nix:57`（`secrets.nix`はhobbyのみ）、`nix/home/secrets.nix:37-42`
- 問題: `commit.gpgsign = true`と`user.signingkey = ~/.config/git/github_signing_ed25519`は両モード共通だが、鍵を置く`gitSigningKeyImport`はhobbyのみ。`user.email`も両モードで個人のアドレス。
- 起きること: work機では`git commit`が`error: Load key ... No such file`で失敗する（手動で鍵を置いていなければ）。
- 対応案: 署名・email設定をモード別にする（home-managerの`programs.git`へ移し、workでは`signing.signByDefault = false`やwork用のemailを`includeIf "gitdir:~/workspaces/github.com/<org>/"`で切り替える）

### P1-9 初回セットアップの流れがworkモード・新しいMacで壊れる

- 場所: `Makefile:7-12`、`bin/init.sh`、`nix/darwin/homebrew.nix:7,43`
- 問題:
  1. `make init`はhobbyのflakeを固定で`switch`する。work機でもhobby用のcask（Discord・Godot・1Password・Tailscale）とmasAppsが入り、`secrets.nix`の`op`が未サインインで失敗して、home-managerのactivationが止まる
  2. `init.sh`は1Passwordをcaskで入れ、SSH Agentでcloneするが、workのbrew設定は`cleanup = "zap"`で1Passwordを持たないため、`make nix-apply-work`で1Passwordが**zap（アンインストール＋データ削除）**される
  3. `make init`はリポジトリの中で実行するのに、`init.sh`が同じリポジトリを`~/workspaces/...`へcloneし直す。READMEの手順（先にclone）と組み合わせると二重cloneか、既存ディレクトリで`git clone`が失敗する。`init.sh`に`set -e`がないので失敗しても続く
  4. `init.sh:36`は`.../yyh-gl/config`を作るが使っていない（`dotfiles`の誤記と思われる）。`:39`は存在しない`make build`を案内している
  5. `init.sh:29`の`sudo rm -rf /Library/Developer/CommandLineTools`は「ディレクトリがない」分岐の中にあり、意味がない。`xcodebuild -license accept`はCommand Line Toolsだけでは失敗する（Xcode本体が必要）
  6. `bin/install-nix.sh:17`は完了後に`make nix-apply-hobby`/`work`を案内するが、その時点では`darwin-rebuild`がまだない（最初の`nix run nix-darwin -- switch`が必要）。`Makefile:10-11`の`brew tap songmu/tap`は`homebrew.nix`の`taps`と重複している
- 対応案:
  - `make init`を`make init-hobby`/`init-work`に分けるか、`MODE`変数を受け取る
  - 1Passwordを両モードのcasksへ移す（init.shが前提にしているため）。または`cleanup = "uninstall"`にする
  - `init.sh`にbootstrap用であることを明記し、`curl ... | zsh`で実行する前提にするか、cloneを削る。`set -euo pipefail`相当（zshなら`setopt err_exit pipe_fail`）を入れる

### P1-10 シェルのPATHでHomebrewがNixより優先され、`git`などがbrew版になる

- 場所: `nix/home/zsh.nix:39,61,74-76`、`bin/init.sh:16`
- 問題: `profileExtra`で`/usr/local/{bin,sbin}`と`/opt/homebrew/bin`を先頭に足し、`initContent`でも`/opt/homebrew/bin`をもう一度先頭に足している。`init.sh`が`brew install git`しているので、`home.packages`の`pkgs.git`は使われない。どちらのバージョンが動くかがインストール履歴で変わる。
- 対応案: PATHの方針を1つに決める（Nix優先なら`/opt/homebrew/bin`を後ろに置く）。`/usr/local`はApple Silicon専用構成なら削る。`init.sh`の`brew install git`はXcode CLTのgitで足りるなら削る

### P1-11 `less`の設定がinteractiveシェルで壊れている

- 場所: `nix/home/zsh.nix:41,43-45,99-100`
- 問題: `initContent`の`export LESS='-R'`が`profileExtra`の`-F -g -i -M -R -S -w -X -z-4`を上書きする。`LESSOPEN`は`/usr/local/Cellar/source-highlight/3.1.8_5/...`という、Intel版Homebrewの固定バージョンのパスを指していて存在しない。
- 起きること: `less`のオプションが意図と違う。LESSOPENのコマンドが毎回失敗する（出力がないので元のファイルにフォールバックするが、stderrに出る環境もある）。
- 対応案: `initContent`の2行を削除する。シンタックスハイライトが欲しいなら`pkgs.source-highlight`をNixで入れ、`${pkgs.source-highlight}/bin/src-hilite-lesspipe.sh`で参照する

### P1-12 `smart-commit`スキルが対話専用の`git add -p`を指示している

- 場所: `claude/skills/smart-commit/SKILL.md:42,176,185`
- 問題: ClaudeのBashはTTYを持たないので`git add -p`は動かない。ハンク単位の分割が必要なケースで失敗するか、Claudeが場当たり的な回避をする。
- 対応案: 「分割したいハンクだけのpatchをscratchpadに書き、`git apply --cached <patch>`でステージする」手順に置き換える

### P1-13 subagentの`tools`と、dev-teamスキルが求める操作が合っていない（要検証）

- 場所: `claude/agents/{lead,planner,reviewer,implementer,tester}.md`の`tools`、`claude/skills/dev-team/SKILL.md:22-35,40-45`
- 問題:
  - Planner・Reviewer・Leadは`tools`にWrite/Editがないのに、`.dev-team/`へ成果物を書くよう指示されている。書けるのはBash経由だけで、それは同じスキルの「Bashは読み取り系のみ」と矛盾する
  - どのagentも`tools`にSendMessage・TaskUpdateを含まない。agent teamsのteammateにはチーム用ツールが常に付与される仕様なら問題ないが、通常のsubagentとして起動された場合は報告手段がない
  - `planner.md:14`は不明点があれば「例外なく`AskUserQuestion`」と求めるが、subagentやteammateから`AskUserQuestion`が使えない場合、Plannerは止まるか推測で進む（どちらも同じファイルで禁止している挙動）
  - `small-dev-team/SKILL.md:131`はPlannerを「ファイル変更なし」とする一方、`:97`はImplementerに「プランのファイルパス」を渡すよう求めており、Plannerがファイルを書かないと成り立たない。`planner.md`は`.dev-team/plan.md`に書く前提で、プランの書式も`small-dev-team`の版（`:101-`）と`planner.md`の版で違う
- 検証: `/agents`か実行ログで各agentが実際に使えるツールを確認する。subagentから`AskUserQuestion`を呼べるかも同時に確認する
- 対応案: Planner・ReviewerにWriteを付けて「書き込みは`.dev-team/`のみ」とする。SendMessage等が自動付与されないなら`tools`へ明記する。`AskUserQuestion`が使えないなら、Plannerは「質問をLeadへSendMessageで返し、Leadがユーザーに聞く」形に変える。プラン書式は`planner.md`の1か所にまとめ、`small-dev-team`からは参照だけにする

---

## P2

### P2-1 README・AGENTS.md・CLAUDE.mdが実装とずれている

- `README.md:13-21,31-34`: 存在しない`.brewfile-base`・`.karabiner`・`.rectangle-config.json`・`.iterm2-profiles.json`・`.zshrc`・`.zpreztorc`・`bin/brew.sh`・`bin/defaults.sh`を説明している。Nix移行前の内容
- `AGENTS.md:29-32`: 実行順を「manual.sh → nix-apply」と書くが、Makefileは逆（`Makefile:18-21`）
- `AGENTS.md:56`: `deck-credentials.json.tpl`と書くが、実ファイルは`op-templates/deck-credentials.tpl`
- `AGENTS.md:66-73`: vaultを`Personal`、`aws-credentials`をAPI Credential（`access_key_id`等のフィールド）と書くが、テンプレートはvault `PC`・全アイテムが`notesPlain`（`op-templates/*.tpl`）
- `nix/home/secrets.nix:21-22`: 「GitHub鍵は認証とcommit署名の両方に使う」は、署名鍵を分けた後の現状と矛盾する。`:46-50`のアイテム名（"SSH Config"・"AWS"など）も実際の`ssh-config`・`aws-credentials`と違う
- `AGENTS.md:96-105`: `nix/`のツリーが`default.nix`だけで、実在する`claude-code.nix`・`codex.nix`・`defaults.nix`・`homebrew.nix`・`claude.nix`・`zsh.nix`などが載っていない
- `CLAUDE.md:23`: 参照先の`docs/plans/wezterm-claude-state-tab-icon.md`はリポジトリに存在しない（グローバルignoreの`**/docs/plans/*.md`で追跡されない）。また「`find_tty`は`wezterm-notify.sh`と`lib/wezterm-tty.sh`で共有」は誤りで、定義が`lib/wezterm-tty.sh`、利用者が`wezterm-notify.sh`と`wezterm-state.sh`
- `AGENTS.md:45`: `.dictionary.txt` → `$HOME/.dictionary.txt`を管理対象として挙げているが、ファイルもNixの配置もない（辞書は`bin/manual.sh:8`で1Passwordから手動importする運用になっている）
- `bin/manual.sh:5`: iTerm2のプロファイルimportを案内しているが、ターミナルはWezTermで、ファイルも存在しない
- 対応案: まとめて現状に合わせる。WezTermの設計メモは`docs/`配下の追跡されるパスへ移すか、参照を消す

### P2-2 死んだ設定・未使用のファイル

| 対象 | 状態 | 対応案 |
| --- | --- | --- |
| `flake.nix:14-17,32`の`nix-vscode-extensions` | overlayを入れているが、どこからも使っていない（VS Codeはcask） | inputごと削除。eval時間と`flake.lock`の更新が減る |
| `claude/hooks/slack-notify.sh` | どのhookからも呼ばれていない。JSONを文字列連結で組んでおり、`"`や改行を含むと壊れる | 削除するか、使うなら`jq -n --arg`で組み、`curl -fsS`と空URLのガードを入れる |
| `.emacs.d/lang/nesc.el` | `init.el:46`の読み込みリストにない | 削除 |
| `ghostty-config`・`zed/*` | 配置しているがGhostty・Zedはどこでもインストールしていない | 使うならcaskに足す、使わないなら削除 |
| `.idea/` | リポジトリに追跡されている。`copilot.data.migration.*.xml`は自分のグローバルignoreでも除外対象 | 削除して`.gitignore`へ |
| `Makefile:44,48`の`.PHONY` | `gitleaks-detect`/`gitleaks-protect`を宣言しているが、ターゲット名は`gitleaks-all`/`gitleaks-staged` | 名前を揃える |
| `nix/home/default.nix:49` | `_module.args = { inherit mode; }`は`extraSpecialArgs`で渡済み | 削除 |
| `init.el:36-37` | Emacs 29以降は`use-package`が組み込み | 削除（Emacsは`emacs-nox`の最新なので常に29以上） |
| `pkgs.hub` | `gh`へ移行済みでupstreamもアーカイブ済み | 削除 |
| `.emacs.d/lang/{java,kotlin,vue}.el` | `eglot-ensure`で`jdtls`・`kotlin-language-server`・`vue-language-server`を起動するが、どれもNix/Homebrewで入れていない（入れているのは`gopls`・`typescript-language-server`だけ）。該当ファイルを開くたびにeglotがサーバーなしのエラーを出す | `pkgs.jdt-language-server`・`pkgs.kotlin-language-server`・`pkgs.vue-language-server`を`home.packages`に足すか、`eglot-ensure`のhookを外す |
| `claude/skills/vercel-react-best-practices/SKILL.md:114` | 参照している`rules/_sections.md`がvendoringの際に抜けていて存在しない | 参照を消すか、upstreamから取り直す（P2-7のプラグイン化も検討） |
| `zsh.nix`の`fix`・`fixe`・`fixs` | 対象（`.zshrc`・`init.el`はnix storeへのsymlink、`~/.ssh/config`は`op inject`で毎回上書き）を編集しても反映されない、または消える | dotfilesの元ファイルを開くエイリアスに変える |
| `flake.nix:33-46`のpandas-stubs回避 | 「一時的」とあるが、外す条件の確認方法がない | upstreamのissue/PRのURLをコメントに残し、`nix-update`のタイミングで外せるか試す |
| `laminate/config.yaml` | `mmdc`（mermaid-cli）と`convert`（ImageMagick）をどこでもインストールしていない。ImageMagick 7では`convert`は非推奨で`magick` | Nixで入れるか、該当コマンドを削る |

### P2-3 `celebrate-anniversary.sh`は「forkしない」設計になっていない

- 場所: `nix/home/zsh.nix:175`、`scripts/celebrate-anniversary.sh`
- 問題: `.zlogin`から実行ファイルとして呼んでいるので、zshプロセスがまるごと1つfork/execされる。スクリプト内の`$(printf ...)`もサブシェルをforkする。AGENTS.mdの「外部コマンドをforkしない」の意図が半分しか達成されていない。同じ`.zlogin`で`ipconfig`・`df`・`uptime`・`figlet`もforkしている。
- 追加の問題: `fortune`以外（IPアドレス・`df`・`uptime`・記念日・`figlet`のバナー）は対話シェルかどうかを見ていない。IDEやツールが`zsh -l -c '...'`でlogin shellを起動すると、その出力にバナーが混ざり、毎回`ipconfig`などが走る
- 対応案: 関数としてautoload（または`source`）し、`printf -v`相当の`print -v var -f ...`で日付文字列を組む。`.zlogin`のほかのコマンドも、起動時間を気にするなら削るか非同期にする。`loginExtra`全体を`if [[ -o interactive ]]; then ... fi`で囲む

### P2-4 statuslineのmodに例外処理・テスト・型チェックがない

- 場所: `claude/mods/statusline/hooks/register.tsx:59-71,74-90`、`Makefile:52-55`、`.github/workflows/test-mods.yml`
- 問題:
  - `refresh`が`$.session.usage()`などで例外を投げると、`session.measure`のたびに失敗通知が出る（`prompt-highlight-md`は`safeDecorate`で対策済み）
  - `session.measure`のたびに`git branch --show-current`を起動する
  - `make test-mods`とCIは`prompt-highlight-md`しか見ておらず、statuslineは`claude plugin validate`もされない。tsconfigもない
- 対応案: `refresh`をtry/catchで包む。`usage`・`cwd`・`model`・branchを`Promise.all`で並行に取る。branchは`turn.complete`と`session.start`のときだけ取り直す。Makefile/CIは`claude/mods/*/`をループしてvalidateする

### P2-5 hooksの細かい問題

- `claude/hooks/wezterm-notify.sh:85`: タイトル・本文をOSC 777にそのまま埋め込む。ディレクトリ名に`;`があるとフィールドがずれ、制御文字（ESC）があればエスケープシーケンスを注入できる。`tr -d '\000-\037;'`で落とす
- `claude/hooks/wezterm-state.sh`だけファイルモードが`100644`（ほかは`100755`）。`bash`経由で呼ぶので動くが揃える
- `claude/managed-settings.json:188`: `idle_prompt`でも「Claude Code has questions」と通知するので、Stopの「free now」通知の約60秒後に同じ状態で質問通知が来る。`idle_prompt`を外すか文言を分ける

### P2-6 zsh関数の小さな問題

- 場所: `nix/home/zsh.nix:103-145`
- `gla`: `default_branch`が`local`でない。`git remote show origin`は毎回ネットワークに出る（`git symbolic-ref --short refs/remotes/origin/HEAD`で足りる）。未コミットの変更があっても`reset --hard`する
- `back`: `head~`（小文字）は大文字小文字を区別するファイルシステムやworktreeで失敗する。`git reset --soft ... && git restore --staged .`は`git reset HEAD~`（mixed）と同じ
- `giad`・`gico`: パスに空白があると壊れる（`awk '{print $2}'`・未クォートの展開）。リネーム行も`$2`が元のパスになる
- `dsh`・`ksh`: fzfでヘッダー行を選べてしまう（`--header-lines=1`）
- `mn`エイリアス: 住居の物件名と市区町村がコミットされている。このリポジトリはPublic（`claude/skills/writing-voice/references/voice-profile.md`末尾にも明記）なので、`.env`か非公開の設定ファイルに移し、必要なら履歴からも消す

### P2-7 その他

- `.github/workflows/gitleaks.yml`: `permissions:`がなく、既定のトークン権限で動く。`contents: read`を明記する。サードパーティのaction（`gitleaks/gitleaks-action`・`oven-sh/setup-bun`）はタグ参照なので、コミットSHAで固定し、Renovateの`helpers:pinGitHubActionDigests`で更新する
- `renovate.json:3`: `config:base`は非推奨で`config:recommended`に置き換え
- `nix/darwin/homebrew.nix:5-6`: `autoUpdate`・`upgrade`がtrueなので、applyのたびにHomebrewが更新され、同じflake.lockでも結果が変わる。applyも遅くなる。`make brew-upgrade`を別に用意して既定はfalseにすることを検討
- `codex-review`スキルは`mcp__codex__codex`を前提にしているが、Codex MCPサーバーの登録（`claude mcp add codex ...`）がNixにもドキュメントにもない
- `claude/skills/vercel-react-best-practices/`: 50ファイルのvendoringでupstreamと乖離していく。`extraKnownMarketplaces`経由のプラグインで入れられるならそちらへ
- `.emacs.d/lang/go.el:43`: `thing-at-point`がnilのとき`go test -run nil .`になる。`-run '^Name$'`で完全一致にする
- `.git-config/config:20`: `core.editor = vim`だが`EDITOR=emacs`。どちらかに揃える
- `.git-config/config`: `gpg.ssh.allowedSignersFile`がないので`git log --show-signature`で検証できない
- `claude/agents/architect.md:3`: descriptionに「Use PROACTIVELY」とあり、opusのsubagentが自動で呼ばれやすい。ほかのagentは日本語でdev-team専用だが、これだけ英語の汎用定義でどのスキルからも参照されていない。使っていないなら削除、使うなら「明示的に頼まれたときだけ」にする
- `nix/home/dotfiles.nix:34-42`: Karabiner・Rectangleの設定はapplyのたびに`install`で上書きされる。GUIで変えた設定は警告なしで消えるので、apply前に`diff`して差分があれば警告を出す（またはdotfilesへ書き戻す手順をAGENTS.mdに書く）

### P2-8 skills・agentsの間で指示が矛盾している

- **書き出し先がスキルごとにばらばら**で、多くがプロジェクト直下に作業ファイルを残す。`smart-commit`は未追跡ファイルも含めて全変更をコミットするので、作業中のプロジェクトに紛れ込む
  - `ponder`: `plansDirectory`（`docs/plans/`。グローバルignore済み）
  - `spec-driven-dev/SKILL.md:100`: 仕様書と同じディレクトリの`<仕様書名>.plan.md`
  - `goal-prompt-builder/SKILL.md:42,67`: プロジェクト直下の`goal-prompts/`と`goal-progress.md`
  - `claude-config-check/SKILL.md`のStep 4・`service-launch-check/SKILL.md:73`: プロジェクト直下の`*-report.md`
  - 対応案: 作業ファイルは`docs/plans/`（または`.claude/`配下のignore済みディレクトリ）に統一する。残すべき成果物（spec-driven-devのプラン）だけ例外として明記する
- `implementer.md:15-17`は「コメントは書かない（Why notだけ）」だが、`reviewer.md:45`は「public APIのドキュメント」欠如を指摘対象にしている。ReviewerがImplementerの方針どおりのコードをBLOCK/WARNINGにする
- `tester.md:19`は「カバレッジ90%以上を目標」とするが、`tdd/SKILL.md`は「カバレッジ率は目的ではない」としている。数値目標は外すか、「参考値」と明記する
- `implementer.md:29`はコミットを`smart-commit`に任せるが、`smart-commit`は作業ツリーの**全差分**を目的別にまとめ直すので、「red-greenペアで1コミット」という同じファイルの規約どおりにならない。Testerなど他メンバーの未コミットの変更も巻き込む。Implementerは対象ファイルを明示して`git add <files>`→`git commit`する手順にする
- `reviewer.md:21`の`govulncheck`・`pip-audit`は`vuln.go.dev`・`api.osv.dev`へ通信するが、どちらも`allowedDomains`にないのでsandbox内で失敗する。ドメインを足すか、失敗したら「未実施」と報告するよう書く
- `smart-commit/SKILL.md:11`はコミットメッセージを常に英語にするが、このリポジトリの直近のコミット（`fde9818`など）は日本語。`writing-voice`はコミットメッセージを対象に含めつつ英語は対象外としている。どちらの言語を正とするかを決め、`smart-commit`は「リポジトリの過去のコミットに合わせる」にする
- `init2/SKILL.md:185`は「CLAUDE.mdに不可逆操作を列挙すればClaudeは自動的に一時停止する」と書くが、CLAUDE.mdの指示は強制されない。`claude-config-check`自身の原則（「必ず/禁止」はhookで強制）とも矛盾する。permissionsの`ask`/hookで強制するよう案内を直す。同ファイルのテンプレートは` \`\`\` `とエスケープしたフェンスを含み、そのまま書き出すとバックスラッシュが残る
- `writing-voice/references/grammar-checklist.md:16-17`は「サンプルがなければ敬体がデフォルト」と書いた直後のOK例が常体（「〜を修正した。原因は〜である。」）になっている。例を敬体にそろえる
- `explain-diff/SKILL.md:109`の`open <file>`は、sandbox内からLaunchServicesを呼べず失敗する可能性がある（要検証。失敗する場合は`excludedCommands`に`open *`を足すのではなく、パスを表示してユーザーに開いてもらう）

---

## R: リファクタリング提案

### R-1 Claude/Codexの共通設定を1つのソースから生成する

- 現状: 許可ドメイン・`allowWrite`・deny・envVars・ask/promptの列挙を`claude/managed-settings.json`と`codex/requirements.toml`・`codex/managed_config.toml`に手で二重に書き、`docs/codex-sandbox.md`で対応を説明している。P1-2のように追加漏れが起きやすい
- 案: `nix/lib/agent-policy.nix`に共通の属性セット（`allowedDomains`・`writablePaths`・`denyRead`・`secretEnvVars`・`askCommands`）を置き、`builtins.toJSON`/`pkgs.formats.toml`で両方のファイルを生成する。Claude固有の項目（hooks・env・excludedCommands）は別の属性で足す
- 生成をやめたくない場合の最小案: CIで「JSONのallowedDomains == TOMLのdomains」などを比較するスクリプトを回す

### R-2 activation scriptの書き方を揃える

- `claude-code.nix`は`cp -f`→`chmod`→`chown`、`codex.nix`は`install -m -o -g`。`install`に揃えると、権限が一瞬緩む窓もなくなる
- darwin側は`${toString ./../../...}`、home側は`${dotfiles}/...`で参照している。darwinにも`specialArgs`で`dotfiles = self`を渡して揃える
- 旧ファイルの扱いが`codex.nix`は自動削除、Claudeは手動削除（CLAUDE.md）と分かれている。`cmp -s`で「旧`managed-settings.json`の中身がdotfilesの過去版と一致するときだけ消す」ようにすれば、手順を覚えておく必要がなくなる

### R-3 `secrets.nix`の繰り返しをデータ化する

- 公開鍵のコピー（`:12-15`）と`op inject`の4ブロック（`:52-69`）を、`{ tpl; out; }`のリストと`lib.concatMapStrings`で生成する。`dotfiles.nix`の`hobbySymlinks`と同じ書き方になる
- 公開鍵は`cp -f`+`chmod 600`ではなく`home.file`で十分（秘密ではないのでsymlinkで問題ない）

### R-4 zshの設定を責務ごとに整理する

- PATH操作を`profileExtra`の1か所にまとめ、`typeset -U path`で重複を防ぐ（P1-10）
- `LESS`/`LESSOPEN`/`EDITOR`/`LANG`は`home.sessionVariables`へ移すと、zsh以外（launchd経由のGUIアプリなど）からも同じ値になる
- Git用の関数群は`programs.zsh.siteFunctions`か`~/.local/share/zsh/functions`へのautoloadにすると`.zshrc`が短くなり、起動時の定義コストも減る
- hobby/workの分岐（エイリアス・`.env`）は`lib.optionalAttrs`/`lib.optionalString`で書く（`if ... then ... else ""`より読みやすく、他ファイルの書き方とも揃う）

### R-5 Makefileを自己文書化し、modeを引数にする

- `help`が固定文言なので、各ターゲットの`# コメント`を`grep`して一覧表示する
- `nix-apply-%`・`build-%`のパターンルールにすると、hobby/workの重複が消える（`init`も同様。P1-9）
- `test-mods`は`claude/mods/*/`をループする（P2-4）

### R-6 `gh`・`docker`・`git`のコマンド判定をhookに寄せる

- 列挙型のask/denyは、前置オプション（P1-5）・`git -C`（docs/codex-sandbox.mdで既知）・新しいサブコマンド（P0-3）に弱い
- PreToolUse hook（Bash）でコマンドをトークン化し、グローバルオプションを読み飛ばしてからサブコマンドで判定する。`permissionDecision`で`allow`/`ask`/`deny`を返す。テストは`claude/mods`と同じbun testで書ける
- Codexは同じ判定をできないので、引き続き`prefix_rules`の列挙（＋意図的な差分としてドキュメント化）

### R-7 Emacsのパッケージ管理をNixへ寄せる

- `use-package :ensure t`で起動時にMELPAから取得しているため、新しいMacの初回起動が遅く、バージョンも固定されない。`programs.emacs.extraPackages = epkgs: [ epkgs.magit epkgs.company ... ]`で入れ、`init.el`は`:ensure nil`（または`use-package-always-ensure nil`）にする。tree-sitterの文法も`epkgs.treesit-grammars.with-grammars`にまとめられる

---

### R-8 常時読み込まれるCLAUDE.md/AGENTS.mdを索引に寄せる

- ルートの`CLAUDE.md`と`AGENTS.md`で合計約16KBあり、毎セッションのコンテキストに載る。中身の多くは「なぜそうしたか」の経緯と、一度きりの手順（`managed-settings.json`の旧配置からの移行・revert時の手動削除、Nixの初回セットアップ）
- `sandbox下でのコマンドの書き方`は`claude/CLAUDE.md`・ルート`CLAUDE.md`の`excludedCommands`の段落・`create-pr`スキルの3か所に同じ説明がある
- 案: 経緯と一度きりの手順は`docs/claude-settings.md`・`docs/setup.md`に移し、CLAUDE.md/AGENTS.mdには「変更時に守るルール」と参照先だけを残す。sandboxの書き方は`claude/CLAUDE.md`（全プロジェクトで読まれる）を正とし、ほかは参照にする

## 確認したが問題なしと判断したもの

- `prompt-highlight-md`のデコレーター: 境界・CRLF・サロゲート・最悪ケースのテストがそろっている。正規表現のバックトラックもテストで押さえている
- `wezterm.lua`のペイン幅均等化: 世代カウンタで並走ループを止めており、試行回数の上限もある
- `wezterm-state.sh`: stdoutを捨てる・常にexit 0・subagentの`none`を無視する、の3点がhookの仕様に沿っている
- Claude/Codexの許可ドメイン・envVarsのdeny・ask/promptの列挙は、現時点ではスクリプトで突き合わせて差分なし（`git push`のdeny/forbiddenは意図どおり）。R-1の最小案はこの突き合わせをCIにするもの
- `claude/skills/vercel-react-best-practices/rules/*.md`の本文は第三者（Vercel）のコンテンツなので、内容の正しさはレビュー対象外とした（参照切れのみP2-2に記載）
- `permissions`の`Read(.env)`などは、gitignore形式なので任意の深さに一致する（Codexの`/**/.env`と同じ範囲）

## 対応の順番（提案）

1. P0-2（pre-push）・P0-3（ghのdeny/ask）: 変更が小さく、効果が大きい
2. P0-1（defaults.nix）: 実機でapplyして確認が必要
3. P1-1〜P1-5（sandbox周り）: Claude/Codexの両方を直すので、先にR-1をやると楽になる
4. P1-6〜P1-11（workモード・初回セットアップ・シェル）
5. P2・残りのR
