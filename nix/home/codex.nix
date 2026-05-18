{ dotfiles, ... }: {
  home.file.".codex/config.toml".source = "${dotfiles}/codex/config.toml";
}
