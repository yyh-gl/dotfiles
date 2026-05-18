{ pkgs, ... }: {
  system.defaults = {
    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.trackpad.scaling" = 3.0;
      AppleInterfaceStyle = "Dark";
    };
    trackpad.Clicking = true;
  };

  # nix-darwinが対応していない設定をactivationScriptsで対応
  system.activationScripts.customDefaults.text = ''
    defaults import com.apple.HIToolbox ${toString ./../../.defaults/com.apple.HIToolbox.plist}
    defaults write com.apple.controlcenter 'NSStatusItem Visible Bluetooth' -bool true
    defaults write com.apple.controlcenter 'NSStatusItem Visible Sound' -bool true

    # [Menu bar] バッテリー残量をパーセントで表示（ByHost設定のため -currentHost が必要）
    defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

    # [Rectangle] 設定インポート
    defaults import com.knollsoft.Rectangle ${toString ./../../.defaults/com.knollsoft.Rectangle.plist}

    # [Key shortcut] 「入力メニューの次のソースを選択」を無効化（ID 60, 61）
    HOTKEY_PLIST="/Users/yyh-gl/Library/Preferences/com.apple.symbolichotkeys.plist"
    for id in 60 61; do
      /usr/libexec/PlistBuddy \
        -c "Set :AppleSymbolicHotKeys:''${id}:enabled false" \
        "$HOTKEY_PLIST" 2>/dev/null \
      || /usr/libexec/PlistBuddy \
        -c "Add :AppleSymbolicHotKeys:''${id}:enabled bool false" \
        "$HOTKEY_PLIST" 2>/dev/null || true
    done

    # [Key shortcut] 「次のウインドウを操作対象にする」をCommand+`にバインド（ID 27）
    # keyCode=50 (backtick), modifier=1048576 (Command)
    /usr/libexec/PlistBuddy \
      -c "Set :AppleSymbolicHotKeys:27:enabled true" \
      -c "Set :AppleSymbolicHotKeys:27:value:parameters:0 96" \
      -c "Set :AppleSymbolicHotKeys:27:value:parameters:1 50" \
      -c "Set :AppleSymbolicHotKeys:27:value:parameters:2 1048576" \
      "$HOTKEY_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy \
      -c "Add :AppleSymbolicHotKeys:27 dict" \
      -c "Add :AppleSymbolicHotKeys:27:enabled bool true" \
      -c "Add :AppleSymbolicHotKeys:27:value dict" \
      -c "Add :AppleSymbolicHotKeys:27:value:type string standard" \
      -c "Add :AppleSymbolicHotKeys:27:value:parameters array" \
      -c "Add :AppleSymbolicHotKeys:27:value:parameters:0 integer 96" \
      -c "Add :AppleSymbolicHotKeys:27:value:parameters:1 integer 50" \
      -c "Add :AppleSymbolicHotKeys:27:value:parameters:2 integer 1048576" \
      "$HOTKEY_PLIST" 2>/dev/null || true

    killall SystemUIServer 2>/dev/null || true
  '';

  # [Battery] AC電源時、ディスプレイオフ後もスリープさせない
  system.activationScripts.powerManagement.text = ''
    pmset -c sleep 0
  '';
}
