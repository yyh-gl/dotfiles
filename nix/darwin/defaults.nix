{ lib, username, homeDirectory, ... }: {
  system.defaults = {
    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.trackpad.scaling" = 3.0;
      AppleInterfaceStyle = "Dark";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      AppleShowScrollBars = "Always";
    };

    trackpad.Clicking = true;

    dock = {
      show-recents = false;
      mru-spaces = false;
      showhidden = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "clmv";
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      NewWindowTarget = "Home";
    };

    screencapture = {
      type = "png";
      disable-shadow = true;
    };

    controlcenter = {
      Bluetooth = true;
      Sound = true;
      # [Menu bar] バッテリー残量をパーセントで表示
      BatteryShowPercentage = true;
    };

    # 入力ソース。旧.defaults/com.apple.HIToolbox.plistのうち意図した設定だけを移したもの
    # （AppleInputSourceHistory・AppleInputSourceUpdateTimeは使うたびに変わる状態なので含めない）
    CustomUserPreferences."com.apple.HIToolbox" = {
      AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.ABC";
      AppleDictationAutoEnable = 0;
      AppleEnabledInputSources = [
        { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 252; "KeyboardLayout Name" = "ABC"; }
        { "Bundle ID" = "com.apple.CharacterPaletteIM"; InputSourceKind = "Non Keyboard Input Method"; }
        { "Bundle ID" = "com.apple.PressAndHold"; InputSourceKind = "Non Keyboard Input Method"; }
        { "Bundle ID" = "com.apple.inputmethod.EmojiFunctionRowItem"; InputSourceKind = "Non Keyboard Input Method"; }
      ];
      AppleSelectedInputSources = [
        { "Bundle ID" = "com.apple.PressAndHold"; InputSourceKind = "Non Keyboard Input Method"; }
        { "Bundle ID" = "com.apple.inputmethod.EmojiFunctionRowItem"; InputSourceKind = "Non Keyboard Input Method"; }
        { "Bundle ID" = "com.google.inputmethod.Japanese"; "Input Mode" = "com.apple.inputmethod.Roman"; InputSourceKind = "Input Mode"; }
      ];
    };
  };

  # nix-darwinのactivationは決まった名前（preActivation・extraActivation・postActivationなど）しか実行しない。
  # system.activationScripts.<任意の名前>は呼ばれないため、postActivationに追記する。
  # activationはrootで動くので、ユーザーのplistを触る処理は`sudo -u`で実行する（rootで書くとroot所有のplistになる）。
  # symbolichotkeysはAppleSymbolicHotKeys全体を置き換えてしまうためCustomUserPreferencesに移さず、PlistBuddyで必要な項目だけ書き換える。
  system.activationScripts.postActivation.text = lib.mkAfter ''
    sudo -u ${username} env HOTKEY_PLIST="${homeDirectory}/Library/Preferences/com.apple.symbolichotkeys.plist" /bin/bash -s <<'USER_EOF'
    # [Key shortcut] 「入力メニューの次のソースを選択」を無効化（ID 60, 61）
    for id in 60 61; do
      /usr/libexec/PlistBuddy \
        -c "Set :AppleSymbolicHotKeys:$id:enabled false" \
        "$HOTKEY_PLIST" 2>/dev/null \
      || /usr/libexec/PlistBuddy \
        -c "Add :AppleSymbolicHotKeys:$id:enabled bool false" \
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
    USER_EOF

    # [Battery] AC電源時、ディスプレイオフ後もスリープさせない（-cでAC電源のみ。power.sleep.computerはバッテリー時も変わるため使わない）
    pmset -c sleep 0
  '';
}
