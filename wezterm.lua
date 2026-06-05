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
config.macos_window_background_blur = 10
config.window_decorations = "RESIZE"
config.window_frame = {
	active_titlebar_bg = "#000000",
	inactive_titlebar_bg = "#111111",
}
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local background = "#000000"
    local foreground = "#FFFFFF"

    if tab.is_active then
        background = "#769ff0"
        foreground = "#FFFFFF"
    end

    local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

    return {
        { Background = { Color = background } },
        { Foreground = { Color = foreground } },
        { Text = title },
    }
end)
---------------------------------
-- font
---------------------------------
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"Apple Color Emoji",
})
config.font_size = 13.5

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
	{ key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Next") },
	{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "SUPER", action = act.CloseCurrentPane({ confirm = true }) },
}

return config
