# nvmB
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

export ZSH="/home/vitorjustin/.oh-my-zsh"

ZSH_THEME="robbyrussell"
#ZSH_THEME="dracula"

source $ZSH/oh-my-zsh.sh
source ~/.zplug/init.zsh

zplug "plugins/git",   from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/docker-compose", from:oh-my-zsh
zplug "zsh-users/zsh-syntax-highlighting", defer:2
#zplug "~/.zsh", from:local
#zplug 'dracula/zsh', as:theme

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load --verbose

# zmv - https://filipe.kiss.ink/zmv-zsh-rename/
autoload zmv
alias zcp='zmv -C'
alias zln='zmv -L'
alias renamecompressed="zmv -v \'(*)_compressed.(jpg|png)\' \'${1}.${2}\'"

# User configuration
export EDITOR=vim

# Aliases
alias zshconfig="vi ~/.zshrc"
alias ohmyzsh="vi ~/.oh-my-zsh"
alias ls="ls -lha --color=auto"
alias folder="explorer.exe"
alias time="\time -f \"%e %C\""

# Programs
alias chrome="/mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe"

# Web server
function enablephp74() {
    sudo a2dismod mpm_event
    sudo a2dismod php8.0
    sudo a2dismod php8.1
    sudo a2disconf php8.0-fpm
    sudo a2disconf php8.1-fpm
    sudo service apache2 reload
    sudo a2enmod mpm_prefork
    sudo a2enmod php7.4
    sudo a2enconf php7.4-fpm
    sudo service apache2 restart
    sudo service php7.4-fpm start
}

function enablephp80() {
    sudo a2dismod mpm_event
    sudo a2dismod php7.4
    sudo a2dismod php8.1
    sudo a2disconf php7.4-fpm
    sudo a2disconf php8.1-fpm
    sudo a2enmod mpm_prefork
    sudo service apache2 reload
    sudo a2enconf php8.0-fpm
    sudo service php8.0-fpm start
    sudo service apache2 restart
}

function enablephp81() {
    sudo a2dismod php7.4
    sudo a2disconf php7.4-fpm
    sudo a2dismod mpm_prefork
    sudo a2enmod mpm_event
    sudo service apache2 reload
    sudo a2enconf php8.1-fpm
    sudo service php8.1-fpm start
    sudo service apache2 restart
}

alias php74="enablephp74"
alias php80="enablephp80"
alias php81="enablephp81"
alias change-php-version="sudo update-alternatives --config php"
alias server="echo 150323 | sudo -S service apache2 start; sudo service mysql start; sudo service php8.1-fpm start"
alias server-stop="echo 150323 | sudo -S service apache2 stop; sudo service mysql stop; sudo service php8.1-fpm stop"
alias sites="cd /home/vitorjustin/sites"
alias apachesites="cd /etc/apache2/sites-available"

# Laravel
alias art="php artisan"
alias a="php artisan"
alias sail="./vendor/bin/sail"
alias routes="a route:list --columns=uri,name,method"


[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
