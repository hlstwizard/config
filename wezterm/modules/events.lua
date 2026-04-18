local M = {}

local LOCAL_WORKSPACE = "local"
local MACMINI_WORKSPACE = "macmini"

local function open_or_focus_workspace(window, pane, wezterm, workspace_name, args)
	window:perform_action(
		wezterm.action.SwitchToWorkspace({
			name = workspace_name,
			spawn = {
				args = args,
			},
		}),
		pane
	)
end

function M.register(wezterm, mux, fit_window_to_active_screen, events)
	wezterm.on("gui-startup", function(cmd)
		local _, _, window = mux.spawn_window(cmd or {})
		fit_window_to_active_screen(window)
	end)

	wezterm.on("gui-attached", function()
		local workspace = mux.get_active_workspace()
		for _, window in ipairs(mux.all_windows()) do
			if window:get_workspace() == workspace then
				fit_window_to_active_screen(window)
			end
		end
	end)

	wezterm.on(events.OPEN_OR_FOCUS_LOCAL_WORKSPACE, function(window, pane)
		open_or_focus_workspace(window, pane, wezterm, LOCAL_WORKSPACE, { "zsh", "-l" })
	end)

	wezterm.on(events.OPEN_OR_FOCUS_MACMINI_WORKSPACE, function(window, pane)
		open_or_focus_workspace(window, pane, wezterm, MACMINI_WORKSPACE, { "ssh", "macmini-tmux" })
	end)

	wezterm.on(events.OPEN_WORKSPACE_PICKER, function(window, pane)
		window:perform_action(
			wezterm.action.InputSelector({
				title = "Open workspace",
				choices = {
					{ id = events.OPEN_OR_FOCUS_LOCAL_WORKSPACE, label = "local" },
					{ id = events.OPEN_OR_FOCUS_MACMINI_WORKSPACE, label = "mac mini" },
				},
				action = wezterm.action_callback(function(win, callback_pane, id, label)
					local selected = id or label
					local target_pane = callback_pane or pane

					if selected == events.OPEN_OR_FOCUS_LOCAL_WORKSPACE or selected == "local" then
						open_or_focus_workspace(win, target_pane, wezterm, LOCAL_WORKSPACE, { "zsh", "-l" })
					elseif selected == events.OPEN_OR_FOCUS_MACMINI_WORKSPACE or selected == "mac mini" then
						open_or_focus_workspace(win, target_pane, wezterm, MACMINI_WORKSPACE, { "ssh", "macmini-tmux" })
					end
				end),
			}),
			pane
		)
	end)
end

return M
