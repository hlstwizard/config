# WezTerm Notes

Use `show-keys` to verify the effective keybindings loaded from this config.

## Platform-specific commands

- macOS / Linux (from this repo root):

```bash
wezterm --config-file "./wezterm/wezterm.lua" show-keys
```

- macOS / Linux (after `./init.sh wezterm` symlink setup):

```bash
wezterm --config-file "${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/wezterm.lua" show-keys
```

- Windows PowerShell (after `./init.ps1 wezterm` symlink setup):

```powershell
wezterm --config-file "$env:USERPROFILE/.config/wezterm/wezterm.lua" show-keys
```

## Quick checks

- Print only custom key lines:

```bash
wezterm --config-file "./wezterm/wezterm.lua" show-keys | rg "LEADER|user-defined|preset-dev-1|trigger-tab-title"
```

- If `wezterm` is not found, verify installation:

```bash
wezterm --version
```

## Launcher entries: local and remote

- Ensure `ssh/config` contains `Host macmini-tmux` with:
  - `RequestTTY force`
  - `RemoteCommand tmux new-session -A -s main`
- In WezTerm launch menu:
  - `local (unix mux)` opens a local login shell.
  - `mac mini (tmux)` opens a persistent remote `tmux` session.
- Local startup behavior (`connect unix`) remains unchanged.
- On macOS, `Cmd+N` opens a workspace picker with `local` and `mac mini`.
- If the selected workspace already has a window, WezTerm focuses it.
- If not, WezTerm creates a new window in that workspace.
