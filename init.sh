#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: init.sh <app>

Example:
  ./init.sh opencode

This creates a symlink from this repo's <app>/ to $XDG_CONFIG_HOME/<app>
(or ~/.config/<app> if XDG_CONFIG_HOME is not set).
Exceptions:
  - for 'copilot', the link target is ~/.copilot
  - for 'ssh', the link target is ~/.ssh
  - for 'git', symlink git/.gitconfig -> ~/.gitconfig and
    git/.gitignore_global -> ~/.gitignore_global
If the destination already exists and is not the desired symlink, it will be
moved aside to a timestamped .bak.<timestamp> path.

Special behavior for 'zsh':
  - ensures Oh My Zsh is installed (unattended)
  - installs configured custom plugins
  - appends the managed zsh config source snippet to ~/.zshrc (if missing)
EOF
}

install_oh_my_zsh_if_missing() {
	if [[ -d "$HOME/.oh-my-zsh" ]]; then
		echo "ok: Oh My Zsh already installed"
		return 0
	fi

	echo "installing: Oh My Zsh (unattended)"
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_plugins_if_available() {
	local script_dir="$1"
	local plugin_script="${script_dir}/install-zsh-plugins.sh"

	if [[ ! -f "$plugin_script" ]]; then
		echo "skip: plugin installer not found: $plugin_script"
		return 0
	fi

	echo "installing: Oh My Zsh custom plugins"
	bash "$plugin_script"
}

ensure_zshrc_sources_config_dir() {
	local zshrc="$HOME/.zshrc"
	local marker_begin="# >>> bootstrap-zsh-managed >>>"
	local marker_end="# <<< bootstrap-zsh-managed <<<"
	local source_line='for f in "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/"*.zsh; do source "$f"; done'

	touch "$zshrc"

	if grep -Fq "$marker_begin" "$zshrc"; then
		echo "ok: managed zshrc snippet already present"
		return 0
	fi

	if grep -Fq "$source_line" "$zshrc"; then
		echo "ok: zsh config source line already present"
		return 0
	fi

	cat >>"$zshrc" <<EOF

$marker_begin
$source_line
$marker_end
EOF

	echo "updated: appended zsh config source snippet to $zshrc"
}

bootstrap_zsh() {
	local script_dir="$1"
	install_oh_my_zsh_if_missing
	install_zsh_plugins_if_available "$script_dir"
	ensure_zshrc_sources_config_dir
}

link_path() {
	local src_path="$1"
	local dest_path="$2"
	local src_abs dest_abs ts backup

	src_abs="$(readlink -f "$src_path" 2>/dev/null || realpath "$src_path")"
	mkdir -p "$(dirname "$dest_path")"

	if [[ -L "$dest_path" ]]; then
		dest_abs="$(readlink -f "$dest_path" 2>/dev/null || realpath "$dest_path")"
		if [[ "$dest_abs" == "$src_abs" ]]; then
			echo "ok: already linked: $dest_path -> $src_abs"
			return 0
		fi
	fi

	if [[ -e "$dest_path" || -L "$dest_path" ]]; then
		ts="$(date +%Y%m%d%H%M%S)"
		backup="${dest_path}.bak.${ts}"
		mv -- "$dest_path" "$backup"
		echo "moved aside: $dest_path -> $backup"
	fi

	ln -s -- "$src_abs" "$dest_path"
	echo "linked: $dest_path -> $src_abs"
}

if [[ ${1-} == "-h" || ${1-} == "--help" ]]; then
	usage
	exit 0
elif [[ $# -eq 0 || ${1-} == "" ]]; then
	usage
	exit 1
fi

app="$1"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ "$app" == "git" ]]; then
	gitconfig_src="${script_dir}/git/.gitconfig"
	gitignore_src="${script_dir}/git/.gitignore_global"

	if [[ ! -f "$gitconfig_src" || ! -f "$gitignore_src" ]]; then
		echo "error: git config files not found under: ${script_dir}/git" >&2
		exit 2
	fi

	link_path "$gitconfig_src" "$HOME/.gitconfig"
	link_path "$gitignore_src" "$HOME/.gitignore_global"
	exit 0
fi

src="${script_dir}/${app}"

if [[ ! -d "$src" ]]; then
	echo "error: app '$app' not found at: $src" >&2
	exit 2
fi

if [[ "$app" == "copilot" ]]; then
	dest="$HOME/.copilot"
elif [[ "$app" == "ssh" ]]; then
	dest="$HOME/.ssh"
else
	config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
	dest="${config_home}/${app}"
	mkdir -p "$config_home"
fi

link_path "$src" "$dest"

if [[ "$app" == "zsh" ]]; then
	bootstrap_zsh "$script_dir"
fi
