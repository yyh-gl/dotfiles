{ dotfiles, lib, config, mode, ... }:
let
  hd = config.home.homeDirectory;
in {
  home.file.".claude/CLAUDE.md".source = "${dotfiles}/claude/CLAUDE.md";
  home.file.".claude/keybindings.json".source = "${dotfiles}/claude/keybindings.json";
  home.file.".claude/statusline.sh" = {
    source = "${dotfiles}/claude/statusline.sh";
    executable = true;
  };
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

  # 仕事PCではMDM等により/Library/Application Support/配下への書き込みがブロックされることが多いため、
  # workモードに限りclaude/managed-settings.jsonの内容を~/.claude/settings.jsonとして配備する（Rectangle同様、symlinkだと書き込みできないため実ファイルとしてコピー）
  home.activation.claudeManagedSettingsAsUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.optionalString (mode == "work") ''
      mkdir -p "${hd}/.claude"
      install -m 644 "${dotfiles}/claude/managed-settings.json" "${hd}/.claude/settings.json"
    ''}
  '';
}
