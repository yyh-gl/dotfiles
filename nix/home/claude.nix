{ dotfiles, ... }: {
  home.file.".claude/CLAUDE.md".source = "${dotfiles}/claude/CLAUDE.md";
  home.file.".claude/settings.json".source = "${dotfiles}/claude/settings.json";
  home.file.".claude/keybindings.json".source = "${dotfiles}/claude/keybindings.json";
  home.file.".claude/statusline.sh" = {
    source = "${dotfiles}/claude/statusline.sh";
    executable = true;
  };
  home.file.".claude/agents".source = "${dotfiles}/claude/agents";
  home.file.".claude/rules".source = "${dotfiles}/claude/rules";
  home.file.".claude/skills".source = "${dotfiles}/claude/skills";
  home.file.".claude/hooks".source = "${dotfiles}/claude/hooks";
}
