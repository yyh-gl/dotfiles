{ pkgs, ... }: {
  imports = [
    ./homebrew.nix
    ./defaults.nix
  ];

  system.stateVersion = 6;
  system.primaryUser = "yyh-gl";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.keyboard.userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 0x7000000E5;
      HIDKeyboardModifierMappingDst = 0x7000000E6;
    }
  ];

  nixpkgs.config.allowUnfree = true;

  users.users.yyh-gl = {
    name = "yyh-gl";
    home = "/Users/yyh-gl";
  };
}
