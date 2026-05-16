{ pkgs, ... }: {
  system.defaults = {
    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.trackpad.scaling" = 3.0;
    };
    trackpad.Clicking = true;
  };

  # nix-darwinが対応していない設定をactivationScriptsで対応
  system.activationScripts.customDefaults.text = ''
    defaults import com.apple.HIToolbox ${toString ./../../.defaults/com.apple.HIToolbox.plist}
    defaults write com.apple.controlcenter 'NSStatusItem Visible Bluetooth' -bool true
    defaults write com.apple.controlcenter 'NSStatusItem Visible Sound' -bool true
    killall SystemUIServer 2>/dev/null || true
  '';
}
