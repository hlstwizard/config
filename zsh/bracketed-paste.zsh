if [[ -o interactive ]] && (( $+widgets[zle-line-init] || $+functions[zle] || $+builtins[zle] )); then
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic
fi
