local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

---------------------------------
-- window
---------------------------------
config.color_scheme = "Ayu Dark (Gogh)"

wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- background
config.colors = {
	background = "#000000",
	split = "#5f6527",
}
config.window_background_opacity = 0.7

---------------------------------
-- font
---------------------------------
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"Apple Color Emoji",
})
config.font_size = 14

---------------------------------
-- behavior
---------------------------------
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

config.default_cwd = wezterm.home_dir

---------------------------------
-- keybind
---------------------------------
config.keys = {
	{ key = "m", mods = "CTRL", action = act.SendString("\r") },
	{ key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Next") },
	{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "SUPER", action = act.CloseCurrentPane({ confirm = true }) },
}

return config
