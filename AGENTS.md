# Repo Agents

This repository is a mirror of `~/.config/` (XDG Base Directory layout) so it can be reused across machines.

## Init

To link an app directory from this repo into the host config directory:

```bash
./init.sh opencode
```

This creates a symlink from `<repo>/opencode/` to `${XDG_CONFIG_HOME:-~/.config}/opencode`.
If the destination already exists and isn't the desired symlink, it is moved aside to `*.bak.<timestamp>`.

## OpenCode

OpenCode configuration lives in `opencode/`.
