local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

---------------------------------
-- window
---------------------------------
-- Ghostty: theme = Ayu
config.color_scheme = "Ayu Dark (Gogh)"

-- Ghostty: window-width/height = 99999 (起動時にウィンドウを最大化)
wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- background
-- Ghostty: background = black / background-opacity = 0.7 / split-divider-color = #5f6527
config.colors = {
	background = "#000000",
	split = "#5f6527",
}
config.window_background_opacity = 0.7

---------------------------------
-- font
---------------------------------
-- Ghostty: font-size = 13
config.font_size = 13

---------------------------------
-- behavior
---------------------------------
-- Ghostty: copy-on-select = clipboard
-- WezTermはマウス選択時に自動でクリップボードへコピーするのがデフォルト挙動。
-- 選択完了時にクリップボード（+ primary selection）へコピーする。
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("ClipboardAndPrimarySelection"),
	},
}

-- Ghostty: macos-option-as-alt = true (OptionキーをAltとして扱う)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Ghostty: working-directory = home / window-inherit-working-directory = false
-- 新規ウィンドウは作業ディレクトリを引き継がず常にホームから開始する。
config.default_cwd = wezterm.home_dir

---------------------------------
-- keybind
---------------------------------
config.keys = {
	-- Ghostty: keybind = ctrl+m=text:\r
	{ key = "m", mods = "CTRL", action = act.SendString("\r") },
	-- Ghostty: keybind = super+[=goto_split:previous
	{ key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Prev") },
	-- Ghostty: keybind = super+]=goto_split:next
	{ key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Next") },
}

return config
