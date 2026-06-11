local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local SOLID_LEFT_ARROW = utf8.char(0xe0ba)
local SOLID_LEFT_MOST = utf8.char(0x2588)
local SOLID_RIGHT_ARROW = utf8.char(0xe0bc)

---------------------------------
-- window
---------------------------------
config.color_scheme = "Raycast_Dark"

wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

config.colors = {
	background = "#000000",
	split = "#5F6527",
	cursor_bg = "#769FF0",
	cursor_fg = "#000000",
	cursor_border = "#769FF0",
	tab_bar = {
		background = "#121212",
		new_tab = { bg_color = "#121212", fg_color = "#FCE8C3", intensity = "Bold" },
		new_tab_hover = { bg_color = "#121212", fg_color = "#FBB829", intensity = "Bold" },
		active_tab = { bg_color = "#121212", fg_color = "#FCE8C3" },
	},
}
config.inactive_pane_hsb = {
	saturation = 0.3,
	brightness = 0.3,
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
		background = "#769FF0"
		foreground = "#1C1B19"
	elseif hover then
		background = "#A3AED2"
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
	"HackGen Console NF",
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
-- mouse
---------------------------------
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "SUPER",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("ClipboardAndPrimarySelection"),
	},
}

---------------------------------
-- pane
---------------------------------
-- 同じleft座標のペインは同一カラム（縦に積まれたペイン）として扱う
local function get_columns(tab)
	local columns = {}
	local seen = {}
	for _, p in ipairs(tab:panes_with_info()) do
		if not seen[p.left] then
			seen[p.left] = true
			table.insert(columns, p)
		end
	end
	table.sort(columns, function(a, b)
		return a.left < b.left
	end)
	return columns
end

-- タブ内の全カラムの幅を均一にする。
-- AdjustPaneSizeは「アクティブペインから分割木を遡って最初に見つかる横分割の境界」を
-- Left/Rightの方向へ動かす仕様（mux/src/tab.rs adjust_pane_size）。どの境界が動くかは
-- 木の形に依存するため、境界ごとに左右どちらのカラムから動かすかを試しつつ、
-- 毎回実測して目標位置に収束させる。
-- 連打などで均等化ループが並走したとき、古いループを無効化するための世代カウンタ
local balance_generation = 0

local function balance_pane_widths(window)
	local tab = window:active_tab()
	if tab == nil then
		return
	end

	local columns = get_columns(tab)
	local n = #columns
	if n < 2 then
		return
	end

	local total_width = 0
	for _, c in ipairs(columns) do
		total_width = total_width + c.width
	end
	local left0 = columns[1].left
	local target = math.floor(total_width / n)

	balance_generation = balance_generation + 1
	local generation = balance_generation
	local original_pane = window:active_pane()
	local moved = false
	local tried = {}
	for i = 1, n - 1 do
		tried[i] = 0
	end

	local function finish()
		if moved then
			original_pane:activate()
		end
	end

	local steps = 0
	local function step()
		if generation ~= balance_generation then
			return
		end

		steps = steps + 1
		if steps > 30 then
			finish()
			return
		end

		columns = get_columns(tab)
		if #columns ~= n then
			finish()
			return
		end

		-- 目標位置からずれている最初の境界を1つ調整し、反映後に次のstepで再計測する
		for i = 1, n - 1 do
			local desired = left0 + i * target + (i - 1)
			local actual = columns[i].left + columns[i].width
			local delta = desired - actual
			if delta ~= 0 and tried[i] < 4 then
				-- 偶数回目は左カラム、奇数回目は右カラムのペインを基準に動かす
				local p = (tried[i] % 2 == 0) and columns[i].pane or columns[i + 1].pane
				tried[i] = tried[i] + 1
				moved = true
				p:activate()
				if delta > 0 then
					window:perform_action(act.AdjustPaneSize({ "Right", delta }), p)
				else
					window:perform_action(act.AdjustPaneSize({ "Left", -delta }), p)
				end
				wezterm.time.call_after(0.03, step)
				return
			end
		end

		finish()
	end

	step()
end

-- ペインが閉じられるのを待ってから幅を均等化する。
-- クローズは確認ダイアログを挟みmuxへの反映タイミングが読めないため、
-- 呼び出し時点のペイン数を記録し、減少を検知するまでポーリングする
-- （キャンセル時は最大約10秒で自然終了）。
local function balance_after_pane_close(window)
	local tab = window:active_tab()
	if tab == nil then
		return
	end
	local tab_id = tab:tab_id()
	local before = #tab:panes()
	local attempts = 0
	local function try_balance()
		local t = window:active_tab()
		if t == nil or t:tab_id() ~= tab_id then
			return
		end
		if #t:panes() < before then
			balance_pane_widths(window)
			return
		end
		attempts = attempts + 1
		if attempts < 100 then
			wezterm.time.call_after(0.1, try_balance)
		end
	end
	wezterm.time.call_after(0.05, try_balance)
end

---------------------------------
-- keybind
---------------------------------
config.keys = {
	{ key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Next") },
	{
		key = "d",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			-- pane:split()は同期APIで、新ペイン作成後すぐに均等化できる
			local new_pane = pane:split({ direction = "Right" })
			new_pane:activate()
			balance_pane_widths(window)
		end),
	},
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{
		key = "w",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			balance_after_pane_close(window)
			window:perform_action(act.CloseCurrentPane({ confirm = true }), pane)
		end),
	},
}

return config
