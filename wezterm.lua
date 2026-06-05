local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local SOLID_LEFT_ARROW = utf8.char(0xe0ba)
local SOLID_LEFT_MOST = utf8.char(0x2588)
local SOLID_RIGHT_ARROW = utf8.char(0xe0bc)

---------------------------------
-- window
---------------------------------
config.color_scheme = "Ayu Dark (Gogh)"

wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

config.colors = {
	background = "#000000",
	split = "#5f6527",
	tab_bar = {
		background = "#121212",
		new_tab = { bg_color = "#121212", fg_color = "#FCE8C3", intensity = "Bold" },
		new_tab_hover = { bg_color = "#121212", fg_color = "#FBB829", intensity = "Bold" },
		active_tab = { bg_color = "#121212", fg_color = "#FCE8C3" },
	},
}
config.window_background_opacity = 0.7
config.macos_window_background_blur = 10
config.window_decorations = "RESIZE"
config.window_frame = {
	active_titlebar_bg = "#000000",
	inactive_titlebar_bg = "#111111",
}
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 60

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local edge_background = "#121212"
	local background = "#4E4E4E"
	local foreground = "#1C1B19"

	if tab.is_active then
		background = "#769ff0"
		foreground = "#1C1B19"
	elseif hover then
		background = "#FF8700"
		foreground = "#1C1B19"
	end

	local edge_foreground = background

	local left_arrow = SOLID_LEFT_ARROW
	if tab.tab_index == 0 then
		left_arrow = SOLID_LEFT_MOST
	end

	local title = " " .. wezterm.nerdfonts.md_robot .. " " .. wezterm.truncate_right(tab.active_pane.title, max_width - 6) .. " "

	return {
		{ Attribute = { Intensity = "Bold" } },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = left_arrow },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_RIGHT_ARROW },
		{ Attribute = { Intensity = "Normal" } },
	}
end)

---------------------------------
-- font
---------------------------------
config.font = wezterm.font_with_fallback({
	"Ricty Diminished",
	"Apple Color Emoji",
})
config.font_size = 14.5

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
