# Codexのsandbox設定

Claudeの`claude/managed-settings.json`と同じルールをCodexにも適用している。`nix/darwin/codex.nix`のactivation scriptで、system層の`/etc/codex/`へ実ファイルとしてコピーする（Codexは`~/.codex/config.toml`を自分で書き換えるため）。ファイルごとの役割は次のとおり。仕組みの詳細は各ファイルの先頭コメントを参照。

- `codex/requirements.toml` → `/etc/codex/requirements.toml`。Claudeの`managed-settings.json`に相当し、ユーザーが上書きできず、CLIフラグでも外せない。permission profile `dotfiles`・network allowlist・filesystemのdeny・`forbidden`/`prompt`ルール・`allowed_*`の制限（`danger-full-access`やapproval policy `never`への切り替え禁止）を置く
- `codex/managed_config.toml` → `/etc/codex/managed_config.toml`。user層（`~/.codex/config.toml`）より優先される既定値（`approval_policy`・`shell_environment_policy`）。user層に同じ項目を書かない

Claudeの設定を変えたらCodex側も揃える。対応関係と注意点:

- `sandbox.filesystem.allowWrite` → `[permissions.dotfiles.filesystem]`の`write`
- `sandbox.credentials.files`・`permissions.deny`の`Read(...)` → `[permissions.filesystem]`の`deny_read`（ワークスペース外にも効く）
- `sandbox.network.allowedDomains` → `[experimental_network.domains]`（PyPIの`pypi.org`・`files.pythonhosted.org`も含む）。`managed_allowed_domains_only`は、Claudeのallowedが設定間で足し合わされるのに合わせて設定していない
- `sandbox.credentials.envVars` → `managed_config.toml`の`shell_environment_policy.exclude`。`ignore_default_excludes = false`はKEY・SECRET・TOKENを含む変数も除外する意味があるので削らない
- `permissions.deny`/`ask`のBash → requirementsの`[rules] prefix_rules`（`forbidden`/`prompt`）。requirementsのrulesは`allow`を書けない
- `chmod`はClaudeでもCodexでも確認（`ask`/`prompt`）にしている。denyだと作業が止まってユーザーに戻されるため
- `docker`のaskは、Claudeではサブコマンドの列挙（書き込み・実行系）にしている。Claudeの権限は「deny→ask→allow」の順に評価され具体性は関係ないため、`Bash(docker*)`のような広いaskは`docker ps`等のallowを打ち消してしまう。Codexのpromptも同じサブコマンドを列挙している
- `permissions.allow`のBash（`git commit`・`gh`の参照系など）は対応するルールを置いていない。Codexのsandbox内のコマンドは、もともと確認なしで実行される

Claudeに揃えられない点（意図的な差分）:

- `sandbox.excludedCommands`（`gh *`・`docker *`・`hunk session *`）: Codexにはコマンド単位でsandbox外へ出す仕組みがないため、これらはCodexでは使えない
- `defaultMode: auto`: `approvals_reviewer = "auto_review"`はmanaged側に置くと`-c`で上書きできず、デッドロックしたときに抜けられないため設定していない（既定の`user`）。使うなら`~/.codex/config.toml`に書く
- `git push`のforbiddenや`gh`・`docker`のpromptは前方一致なので、環境変数の前置（`GH_CONFIG_DIR=x gh ...`など）で迂回できる。Claudeの`Bash(git push*)`も同じ弱点を持ち、実質の防御はsandboxが担う
- `--dangerously-bypass-approvals-and-sandbox`などは、起動エラーにはならず、警告を出してrequirementsの値に戻される
