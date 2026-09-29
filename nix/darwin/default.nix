{ username, homeDirectory, ... }: {
  imports = [
    ./homebrew.nix
    ./defaults.nix
    ./claude-code.nix
  ];

  system.stateVersion = 6;
  system.primaryUser = username;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.keyboard.userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 30064771301; # Right Shift (0x7000000E5)
      HIDKeyboardModifierMappingDst = 30064771302; # Right Option (0x7000000E6)
    }
  ];

  nixpkgs.config.allowUnfree = true;

  # /etc/zshrcのcompinit・bashcompinit・promptinit（prompt suse）は使わない。
  # compinitはhome-manager側（nix/home/zsh.nix）で1回だけ実行し、プロンプトはstarshipが担う。
  # enableCompletionはtrueのまま残す（/etc/zshenvのfpath設定を維持するため）。
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.enableBashCompletion = false;
  programs.zsh.promptInit = "";

  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.${username} = {
    name = username;
    home = homeDirectory;
  };
}
