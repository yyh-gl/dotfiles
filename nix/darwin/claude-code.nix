{ lib, ... }: {
  # Claude Code自身は書き換えないmanaged-settings.jsonに置くことで、/model等の操作による自動再生成（claude-code#22659）から設定を保護する
  # system.activationScripts.<任意の名前>.text はnix-darwinの実行リストに含まれず呼ばれないため、
  # 正式な差込口であるpostActivationに追記する
  system.activationScripts.postActivation.text = lib.mkAfter ''
    mkdir -p "/Library/Application Support/ClaudeCode"
    cp -f "${toString ./../../claude/managed-settings.json}" "/Library/Application Support/ClaudeCode/managed-settings.json"
    chmod 644 "/Library/Application Support/ClaudeCode/managed-settings.json"
    chown root:wheel "/Library/Application Support/ClaudeCode/managed-settings.json"
  '';
}
