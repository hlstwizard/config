if [[ -o interactive ]]; then
  PROMPT='%(?:%{$fg[green]%}%1{➜%} :%{$fg[red]%}%1{➜%} ) %{$fg[cyan]%}%m %c%{$reset_color%} $(git_prompt_info)'
fi
