install_oh_my_zsh_if_missing() {
	if [[ -d "$HOME/.oh-my-zsh" ]]; then
		echo "ok: Oh My Zsh already installed"
		return 0
	fi

	echo "installing: Oh My Zsh (unattended)"
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

clone_plugin_if_missing() {
	local plugin_name="$1"
	local repo_url="$2"
	local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
	local plugin_dir="${plugins_dir}/${plugin_name}"

	mkdir -p "$plugins_dir"

	if [[ -d "$plugin_dir" ]]; then
		echo "ok: plugin already installed: $plugin_name"
		return 0
	fi

	echo "installing: plugin $plugin_name"
	git clone "$repo_url" "$plugin_dir"
}

install_zsh_plugins() {
	clone_plugin_if_missing "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
	clone_plugin_if_missing "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
	clone_plugin_if_missing "zsh-fzf-history-search" "https://github.com/joshskidmore/zsh-fzf-history-search.git"
}

link_zsh_custom_files() {
	local script_dir="$1"
	local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
	local src_file dest_file

	if [[ ! -d "${script_dir}/zsh/scripts" ]]; then
		echo "error: zsh scripts directory not found at: ${script_dir}/zsh/scripts" >&2
		exit 2
	fi

	mkdir -p "$zsh_custom"

	for src_file in "${script_dir}/zsh/scripts/"*.zsh; do
		if [[ ! -f "$src_file" ]]; then
			continue
		fi
		dest_file="${zsh_custom}/$(basename "$src_file")"
		link_path "$src_file" "$dest_file"
	done
}

link_zshrc_file() {
	local script_dir="$1"
	local zshrc_src="${script_dir}/zsh/.zshrc"

	if [[ ! -f "$zshrc_src" ]]; then
		echo "error: zshrc file not found at: $zshrc_src" >&2
		exit 2
	fi

	link_path "$zshrc_src" "$HOME/.zshrc"
}

bootstrap_zsh() {
	local script_dir="$1"
	install_oh_my_zsh_if_missing
	install_zsh_plugins
	link_zsh_custom_files "$script_dir"
	link_zshrc_file "$script_dir"
}
