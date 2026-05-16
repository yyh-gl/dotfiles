{ ... }: {
  home.username = "yyh-gl";
  home.homeDirectory = "/Users/yyh-gl";
  home.stateVersion = "26.05";

  imports = [
    ./dotfiles.nix
    ./zsh.nix
  ];
}
