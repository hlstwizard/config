-- Pull in the wezterm API
local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.leader = { key = "Space", mods = "ALT", timeout_milliseconds = 1000 }

-- Basic: split window like iTerm (Cmd+d)
config.keys = {
	{ mods = "LEADER", key = "p", action = wezterm.action.PaneSelect },
	{
		key = "d",
		mods = "CMD",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "CMD|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "CMD",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
	},
}

wezterm.on("gui-startup", function(cmd)
	local screen = wezterm.gui.screens().active
	local width = math.floor(screen.width / 2)
	local height = screen.height
	local x = screen.x + width
	local y = screen.y

	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():set_position(x, y)
	window:gui_window():set_inner_size(width, height)
end)

return config
