-- workモードだけ~/.config/wezterm/work.luaとして配置され、wezterm.luaから読み込まれる（nix/home/dotfiles.nix）
local wezterm = require("wezterm")
local act = wezterm.action

return function(config)
	-- TUIアプリがマウスキャプチャ中でも、ドラッグ/ダブルクリック/トリプルクリックによる
	-- WezTerm本来のテキスト選択を優先する（mouse_reporting = trueがないとこの間は無効になる）
	for streak, mode in ipairs({ "Cell", "Word", "Line" }) do
		table.insert(config.mouse_bindings, {
			event = { Down = { streak = streak, button = "Left" } },
			mods = "NONE",
			mouse_reporting = true,
			action = act.SelectTextAtMouseCursor(mode),
		})
		table.insert(config.mouse_bindings, {
			event = { Drag = { streak = streak, button = "Left" } },
			mods = "NONE",
			mouse_reporting = true,
			action = act.ExtendSelectionToMouseCursor(mode),
		})
		table.insert(config.mouse_bindings, {
			event = { Up = { streak = streak, button = "Left" } },
			mods = "NONE",
			mouse_reporting = true,
			action = act.CompleteSelection("ClipboardAndPrimarySelection"),
		})
	end
end
