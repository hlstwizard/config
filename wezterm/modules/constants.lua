local M = {}

M.DOMAIN_NAME = "unix"
M.MACMINI_SSH_DOMAIN = "SSH:mac-mini"

M.NAV_DIRECTIONS = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

M.NAV_KEYS = { "h", "j", "k", "l" }

M.EVENTS = {
	PRESET_DEV_1 = "preset-dev-1",
	PROMPT_TAB_TITLE = "trigger-tab-title",
	OPEN_WORKSPACE_PICKER = "open-workspace-picker",
	OPEN_OR_FOCUS_LOCAL_WORKSPACE = "open-or-focus-local-workspace",
	OPEN_OR_FOCUS_MACMINI_WORKSPACE = "open-or-focus-macmini-workspace",
}

return M
