alias dotfiles="cd ~/dotfiles"

alias cls="clear"
alias c='clear'
alias cls='clear'
alias vim='nvim'
alias grep="grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}"
alias clip="xclip -sel clip"
alias open="explorer.exe"
alias apt-upgrade="sudo apt update && sudo apt upgrade -y"
alias pstorm="/mnt/c/Program\ Files\ \(x86\)/JetBrains/PhpStorm\ 2024.3/bin/phpstorm64.exe $(wslpath -w .)"
alias phpstorm="pstorm"

# bat
# https://github.com/sharkdp/bat/issues/954#issuecomment-1293173319
biff () {
  diff $@|bat -l diff
}

# https://github.com/sharkdp/bat?tab=readme-ov-file#git-diff
gitdiff() {
  git diff --name-only --relative --diff-filter=d | xargs bat --diff
}

# https://github.com/sharkdp/bat?tab=readme-ov-file#tail--f
battail() {
  tail -f "$1" | bat --paging=never -l log
}
alias batlog="bat -l log"

alias fiff="fancy-diff"

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
alias ohmyzsh="vim ~/.oh-my-zsh"
alias aliases="vim ~/dotfiles/.aliases.zsh"

# directories
alias sites="cd /home/vitorjustin/sites"
alias whome="cd /mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"

# docker
alias dcs="sudo /etc/init.d/docker start"
alias dcstatus="sudo service docker status"

# laravel
alias a="php artisan"
alias sail="alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'"

# WSL Bridge (https://github.com/Alex-D/dotfiles?tab=readme-ov-file#setup-docker)
alias wslb="PowerShell.exe 'Start-Process PowerShell -Verb RunAs \"PowerShell -File \$env:USERPROFILE\\wsl2-bridge.ps1\"'"
