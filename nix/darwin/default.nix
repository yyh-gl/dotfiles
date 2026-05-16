{ pkgs, ... }: {
  imports = [ ./homebrew.nix ];

  system.stateVersion = 6;
  system.primaryUser = "yyh-gl";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  users.users.yyh-gl = {
    name = "yyh-gl";
    home = "/Users/yyh-gl";
  };
}
