# Bootstrap

## Install Applications

- Install brew from https://brew.sh/
- Install the applications from brew using the brewfile:

```bash
brew bundle --file=Brewfile
```

## Set Up Zsh

1. Install [Oh My Zsh](https://ohmyz.sh/):

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

2. Install plugins:

```bash
./install-zsh-plugins.sh
```

3. Enable the plugins in `~/.zshrc` by updating the `plugins` line:

```zsh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
```

4. Load zsh configs by symlinking the `zsh/` config directory and sourcing all `*.zsh` files in `~/.zshrc`:

```bash
./init.sh zsh
```

```zsh
for f in "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/"*.zsh; do source "$f"; done
```

## Input Method (Rime / Squirrel)

1. Install [Squirrel](https://rime.im/) via Homebrew (included in Brewfile) or manually.

2. Install [rime-ice](https://github.com/iDvel/rime-ice) (雾凇拼音) using [Plum](https://github.com/rime/plum) (东风破):

```bash
# Install Plum
cd ~
git clone https://github.com/rime/plum.git plum

# Install all rime-ice files
cd ~/plum
bash rime-install iDvel/rime-ice:others/recipes/full
```

> To update rime-ice later, re-run `bash rime-install iDvel/rime-ice:others/recipes/full` from `~/plum`.

3. Overlay your saved config from OneDrive on top of the rime-ice base:

```bash
cp -r ~/Library/CloudStorage/OneDrive-Personal/RimeSync/. ~/Library/Rime/
```

4. Reload Rime: click the Squirrel menu bar icon → **Deploy** (重新部署).

> The Rime config folder defaults to `~/Library/Rime` on macOS.

## Configure Applications 

This repository mirrors ~/.config/ and can be reused across different machines.

Link an app directory from this repo into your host's config directory:

```bash
./init.sh opencode
```

This creates a symlink from `<repo>/opencode/` to `${XDG_CONFIG_HOME:-~/.config}/opencode`. If the destination already exists and isn't the desired symlink, it is moved aside to `*.bak.<timestamp>`.

Example: OpenCode

OpenCode configuration lives in `opencode/`.

- `opencode/AGENTS.md`: default agent instructions (copied from `~/AGENTS.md`).
