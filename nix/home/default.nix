{ pkgs, username, homeDirectory, mode, ... }: {
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.awscli2
    pkgs.delta
    pkgs.figlet
    pkgs.fzf
    pkgs.gibo
    pkgs.git
    pkgs.gopls
    pkgs.gradle
    pkgs.helmfile
    pkgs.hub
    pkgs.hugo
    pkgs.jq
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kubernetes-helm
    pkgs.nodejs
    pkgs.pnpm
    pkgs.silicon
    pkgs.starship
    pkgs.tree
  ] ++ pkgs.lib.optionals (mode == "hobby") [
    pkgs.bun
    pkgs.deno
  ];

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

  _module.args = { inherit mode; };

  imports = [
    ./dotfiles.nix
    ./zsh.nix
    ./vscode.nix
    ./emacs.nix
    ./claude.nix
    ./gh.nix
  ];
}
