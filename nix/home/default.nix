{ pkgs, ... }: {
  home.username = "yyh-gl";
  home.homeDirectory = "/Users/yyh-gl";
  home.stateVersion = "26.05";

  home.packages = [ pkgs.gopls ];

  programs.go = {
    enable = true;
    package = pkgs.go_1_26;
    env.GOPATH = "$HOME/go";
    env.GOBIN  = "$HOME/go/bin";
  };

  programs.java = {
    enable = true;
    package = pkgs.jdk25;
  };

  imports = [
    ./dotfiles.nix
    ./zsh.nix
    ./vscode.nix
    ./emacs.nix
    ./claude.nix
    ./gh.nix
  ];
}
