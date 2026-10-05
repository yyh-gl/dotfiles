{ lib, ... }: {
  # Claude Code自身は書き換えないmanaged settingsに置くことで、/model等の操作による自動再生成（claude-code#22659）から設定を保護する
  # managed-settings.json（先）とmanaged-settings.d/*.json（アルファベット順）は同じ層としてマージされて読まれる。
  # ほかのツールがmanaged-settings.jsonを使っても上書きし合わないよう、drop-inの50-dotfiles.jsonに置く
  # system.activationScripts.<任意の名前>.text はnix-darwinの実行リストに含まれず呼ばれないため、
  # 正式な差込口であるpostActivationに追記する
  system.activationScripts.postActivation.text = lib.mkAfter ''
    claude_dir="/Library/Application Support/ClaudeCode"
    mkdir -p "$claude_dir/managed-settings.d"
    chmod 755 "$claude_dir/managed-settings.d"
    chown root:wheel "$claude_dir/managed-settings.d"
    cp -f "${toString ./../../claude/managed-settings.json}" "$claude_dir/managed-settings.d/50-dotfiles.json"
    chmod 644 "$claude_dir/managed-settings.d/50-dotfiles.json"
    chown root:wheel "$claude_dir/managed-settings.d/50-dotfiles.json"
    # 旧配置のmanaged-settings.jsonは自動では消さない（移行後の初回のみ必要な作業のため。CLAUDE.mdの手順で手動削除する）
  '';
}
