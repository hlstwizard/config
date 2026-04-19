local M = {}

local LOCAL_WORKSPACE = "local"
local MACMINI_WORKSPACE = "macmini"
local DEFAULT_WORKSPACE = "default"
local LOGIN_SHELL_ARGS = { "zsh", "-l" }

local function open_or_focus_workspace(window, pane, wezterm, workspace_name, spawn)
	window:perform_action(
		wezterm.action.SwitchToWorkspace({
			name = workspace_name,
			spawn = spawn,
		}),
		pane
	)
end

local function open_or_focus_shell_workspace(window, pane, wezterm, workspace_name)
	open_or_focus_workspace(window, pane, wezterm, workspace_name, {
		args = LOGIN_SHELL_ARGS,
	})
end

local function open_or_focus_macmini_workspace(window, pane, wezterm, constants)
	open_or_focus_workspace(window, pane, wezterm, MACMINI_WORKSPACE, {
		domain = { DomainName = constants.MACMINI_SSH_DOMAIN },
	})
end

function M.register(wezterm, mux, fit_window_to_active_screen, events, constants)
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
		open_or_focus_shell_workspace(window, pane, wezterm, LOCAL_WORKSPACE)
	end)

	wezterm.on(events.OPEN_OR_FOCUS_MACMINI_WORKSPACE, function(window, pane)
		open_or_focus_macmini_workspace(window, pane, wezterm, constants)
	end)

	wezterm.on(events.OPEN_WORKSPACE_PICKER, function(window, pane)
		window:perform_action(
			wezterm.action.InputSelector({
				title = "Open workspace",
				choices = {
					{ id = DEFAULT_WORKSPACE, label = "default" },
					{ id = events.OPEN_OR_FOCUS_LOCAL_WORKSPACE, label = "local" },
					{ id = events.OPEN_OR_FOCUS_MACMINI_WORKSPACE, label = "mac mini" },
				},
				action = wezterm.action_callback(function(win, callback_pane, id, label)
					local selected = id or label
					local target_pane = callback_pane or pane

					if selected == DEFAULT_WORKSPACE or selected == "default" then
						open_or_focus_shell_workspace(win, target_pane, wezterm, DEFAULT_WORKSPACE)
					elseif selected == events.OPEN_OR_FOCUS_LOCAL_WORKSPACE or selected == "local" then
						open_or_focus_shell_workspace(win, target_pane, wezterm, LOCAL_WORKSPACE)
					elseif selected == events.OPEN_OR_FOCUS_MACMINI_WORKSPACE or selected == "mac mini" then
						open_or_focus_macmini_workspace(win, target_pane, wezterm, constants)
					end
				end),
			}),
			pane
		)
	end)
end

return M
