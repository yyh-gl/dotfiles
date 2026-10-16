{ dotfiles, lib, config, mode, pkgs, ... }:
let
  hd = config.home.homeDirectory;
in {
  home.file.".claude/CLAUDE.md".source = "${dotfiles}/claude/CLAUDE.md";
  home.file.".claude/keybindings.json".source = "${dotfiles}/claude/keybindings.json";
  home.file.".claude/agents".source = "${dotfiles}/claude/agents";
  home.file.".claude/rules".source = "${dotfiles}/claude/rules";
  # Hunk同梱のスキルをactivation scriptでコピーするため、ディレクトリ丸ごとのsymlink（nix store上で読み取り専用）ではなくファイル単位でsymlinkする
  home.file.".claude/skills" = {
    source = "${dotfiles}/claude/skills";
    recursive = true;
  };
  home.file.".claude/hooks".source = "${dotfiles}/claude/hooks";

  # `hunk skill path`が返すSKILL.mdのあるディレクトリを~/.claude/skills/hunk-reviewへコピーする（applyのたびに上書き）
  # Homebrewのアップグレードに追従させるため、パスは固定せず毎回`hunk skill path`で解決する
  home.activation.claudeHunkSkill = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # sudo経由のapplyではPATHにHomebrewが含まれず、hunkが見つからないため先頭に足す
    export PATH="/opt/homebrew/bin:$PATH"
    if ! command -v hunk >/dev/null; then
      echo "warning: hunk command not found (PATH=$PATH), skipping" >&2
    elif ! skill_file="$(hunk skill path)" || [ ! -f "$skill_file" ]; then
      echo "warning: 'hunk skill path' failed or returned a missing file: '$skill_file', skipping" >&2
    else
      dest="${hd}/.claude/skills/hunk-review"
      rm -rf "$dest"
      cp -R "$(dirname "$skill_file")" "$dest"
      chmod -R u+w "$dest"
    fi
  '';

  # claude/mods/*の各modを~/.claude/mods/<名前>へ実ファイルとしてコピーする（applyのたびに上書き）
  # nix storeへのsymlinkだと、engineが「Path escapes plugin directory」で拒否するためsymlinkは使えない。
  # engineが読み込みのたびに.claude-plugin/types/を書き込むため、コピー後にu+wを付与する。
  # ~/.claude/mods全体は消さないので、手動で置いたmodは残る
  home.activation.claudeMods = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "${hd}/.claude/mods"
    for mod in "${dotfiles}"/claude/mods/*/; do
      dest="${hd}/.claude/mods/$(basename "$mod")"
      rm -rf "$dest"
      cp -R "$mod" "$dest"
      chmod -R u+w "$dest"
    done
  '';

  # 仕事PCではMDM等により/Library/Application Support/配下への書き込みがブロックされることが多いため、
  # workモードに限りclaude/managed-settings.jsonの内容を~/.claude/settings.jsonへ配備する（Rectangle同様、symlinkだと書き込みできないため実ファイルにする）
  # Claude Codeが書く可変設定（enabledPlugins・effortLevelなど）を消さないよう、既存のsettings.jsonへmanaged側のキーを上書きマージする
  # user層なので、クローンしたリポジトリの.claude/settings.jsonにsandbox無効化などで上書きされうる（managed層と違い強制力はない）
  home.activation.claudeManagedSettingsAsUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.optionalString (mode == "work") ''
      mkdir -p "${hd}/.claude"
      settings="${hd}/.claude/settings.json"
      managed="${dotfiles}/claude/managed-settings.json"
      if [ -s "$settings" ] && merged="$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" "$managed")"; then
        printf '%s\n' "$merged" > "$settings.tmp" && mv "$settings.tmp" "$settings"
      else
        install -m 644 "$managed" "$settings"
      fi
    ''}
  '';
}
