{ dotfiles, lib, config, ... }: {
  home.file.".config/ghostty/config".source = "${dotfiles}/ghostty-config";
  home.file.".config/starship.toml".source = "${dotfiles}/starship.toml";
  home.file.".config/git/config".source = "${dotfiles}/.git-config/config";
  home.file.".config/git/ignore".source = "${dotfiles}/.git-config/ignore";

  home.activation.karabiner = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dotfiles="${config.home.homeDirectory}/workspaces/github.com/yyh-gl/dotfiles"
    mkdir -p "${config.home.homeDirectory}/.config/karabiner"
    ln -sf "$dotfiles/karabiner.json" \
      "${config.home.homeDirectory}/.config/karabiner/karabiner.json"
  '';
}
