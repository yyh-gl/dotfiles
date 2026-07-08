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
  home.file.".claude/skills".source = "${dotfiles}/claude/skills";
  home.file.".claude/hooks".source = "${dotfiles}/claude/hooks";

  # 仕事PCではMDM等により/Library/Application Support/配下への書き込みがブロックされることが多いため、
  # workモードに限りclaude/managed-settings.jsonの内容を~/.claude/settings.jsonとして配備する（Rectangle同様、symlinkだと書き込みできないため実ファイルとしてコピー）
  home.activation.claudeManagedSettingsAsUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.optionalString (mode == "work") ''
      mkdir -p "${hd}/.claude"
      install -m 644 "${dotfiles}/claude/managed-settings.json" "${hd}/.claude/settings.json"
    ''}
  '';
}
