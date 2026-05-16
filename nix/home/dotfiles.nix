{ dotfiles, ... }: {
  home.file.".config/ghostty/config".source = "${dotfiles}/ghostty-config";
  home.file.".config/starship.toml".source = "${dotfiles}/starship.toml";
  home.file.".config/git/config".source = "${dotfiles}/.git-config/config";
  home.file.".config/git/ignore".source = "${dotfiles}/.git-config/ignore";
}
