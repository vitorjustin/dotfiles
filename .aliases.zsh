alias cls="clear"
alias c='clear'
alias cls='clear'
alias vim='nvim'
alias grep="grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}"
alias clip="xclip -sel clip"
alias open="explorer.exe"
alias apt-upgrade="sudo apt update && sudo apt upgrade -y"
alias gdm="git diff --name-only main...HEAD"
alias code2="/mnt/c/Users/vitor/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code"
alias dotfiles="cd ~/dotfiles"

# bat
# https://github.com/sharkdp/bat?tab=readme-ov-file#git-diff
batdiff() {
  git diff --name-only --relative --diff-filter=d | xargs bat --diff
}

# https://github.com/sharkdp/bat?tab=readme-ov-file#tail--f
battail() {
  tail -f "$1" | bat --paging=never -l log
}

# https://medium.com/@GroundControl/better-git-diffs-with-fzf-89083739a9cb
fd() {
  preview="git diff $@ --color=always -- {-1}"
  git diff $@ --name-only | fzf -m --ansi --preview "$preview" --height=100% --preview-window=right:wrap
}

alias fdb="fd main...HEAD"

## EZA (better ls) or custom ls aliases
if type eza >/dev/null 2>&1; then
    alias ls="eza --icons --git"
    alias l='eza -alg --color=always --group-directories-first --git'
    alias ll='eza -aliSgh --color=always --group-directories-first --icons --header --long --git'
    alias lt='eza -@alT --color=always --git'
    alias llt="eza --oneline --tree --icons --git-ignore"
    alias lr='eza -alg --sort=modified --color=always --group-directories-first --git'
else
    alias l='ls -alh --group-directories-first'
    alias ll='ls -al --group-directories-first'
    alias lr='ls -ltrh --group-directories-first'
fi

# config files
alias zshconfig="vim ~/.zshrc"
alias reload='source ~/.zshrc && rehash'
alias ohmyzsh="vim ~/.oh-my-zsh"
alias aliases="vim ~/dotfiles/.aliases.zsh"
alias weztermconfig="vim /mnt/c/Users/vitor/.wezterm.lua"

# directories
alias sites="cd /home/vitorjustin/sites"
alias whome="cd /mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"

# docker
alias dcs="sudo /etc/init.d/docker start"
alias dcstatus="sudo service docker status"
alias docker-start="sudo systemctl start docker"

# git
alias gpush="git push origin HEAD"
alias gfpush="git push origin HEAD --force-with-lease"
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'

# laravel
alias a="php artisan"
alias sail="alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'"

# WSL Bridge (https://github.com/Alex-D/dotfiles?tab=readme-ov-file#setup-docker)
alias wslb="PowerShell.exe 'Start-Process PowerShell -Verb RunAs \"PowerShell -File \$env:USERPROFILE\\wsl2-bridge.ps1\"'"

# opencode - toggle concise instruction
alias concise-off="> ~/.config/opencode/instructions/concise.md"
alias concise-on="echo 'Be extremely concise. Sacrifice grammar for the sake of concision.' > ~/.config/opencode/instructions/concise.md"

# opencode - auto commit
commit() {
  local interactive=""
  local words=()
  local arg

  for arg in "$@"; do
    if [[ "$arg" == "--mini" ]]; then
      interactive="-i"
    else
      words+=("$arg")
    fi
  done

  local message="${words[*]}"
  local prompt

  if [[ -n "$message" ]]; then
    prompt="commit all. do atomic commits if possible. use this as the commit message/intent: \"$message\", adapting it to follow the latest 8 commits messages styling and language (pt-br or en)."
  else
    prompt="commit all. do atomic commits if possible. follow latest 8 commits messages styling and language (pt-br or en)."
  fi

  if [[ -n "$interactive" ]]; then
    opencode2 mini --prompt "$prompt" --model opencode-go/deepseek-v4-flash
  else
    opencode2 run "$prompt" --model opencode-go/deepseek-v4-flash --auto
  fi
}

# today dir: creates <YYYYMMDD>_<counter> and cds into it
td() {
  local today n=1 dir
  today=$(date +%Y%m%d)
  while [[ -e "$(printf '%s_%03d' "$today" "$n")" ]]; do
    ((n++))
  done
  dir="$(printf '%s_%03d' "$today" "$n")"
  mkdir "$dir" && cd "$dir"
}

# private aliases (gitignored) — clients, work servers, etc.
[ -f ~/.aliases.private.zsh ] && source ~/.aliases.private.zsh
