alias dotfiles="cd ~/dotfiles"

alias cls="clear"
alias c='clear'
alias cls='clear'
alias vim='nvim'
alias grep="grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}"
alias clip="xclip -sel clip"
alias open="explorer.exe"
alias apt-upgrade="sudo apt update && sudo apt upgrade -y"

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

# clients
alias s-miagui-prod="ssh -o ServerAliveInterval=60 prodapimiagui@45.178.182.83"
alias s-miagui-homolog="ssh -o ServerAliveInterval=60 hmlapimiagui@45.178.182.83"
alias s-miagui-root="ssh -o ServerAliveInterval=60 root@45.178.182.83"
alias s-neo-prod="ssh -o ServerAliveInterval=60 -p 51439 prodapi@45.178.180.228"
alias s-neo-homolog="ssh -o ServerAliveInterval=60 -p 51439 homologapi@45.178.180.228"
alias s-neo-root="ssh -p 51439 -o ServerAliveInterval=60 root@45.178.180.228"
alias s-neo-global-root="ssh -p 51439 -o ServerAliveInterval=60 root@45.178.182.21"
alias s-neo-global-prod="ssh -p 51439 -o ServerAliveInterval=60 gblprodapi@45.178.182.21"
alias s-dbc-homolog="ssh -o ServerAliveInterval=60 -p 52300 vitor.bitfans@144.22.132.245"
