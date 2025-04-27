# Schnellere Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Schnelle Git-Befehle
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'

# Schnellere Updates
alias rebuild='sudo nixos-rebuild switch --flake /etc/nixos#default --show-trace'

# Colorize ls
alias ls='ls --color=auto -lah'

PS1='\[\e[0;32m\]\u@\h:\[\e[0;34m\]\w\[\e[0;31m\]$(__git_ps1 " (%s)")\[\e[0m\]\$ '

# Neue Ordner erstellen und direkt reingehen
mkcd () {
    mkdir -p "$1"
    cd "$1"
}

# Bash History verbessern
HISTSIZE=10000
HISTFILESIZE=50000
shopt -s histappend  # History wird nicht überschrieben, sondern angehängt

# Auto-Korrektur bei kleinen Tippfehlern im Pfad
shopt -s cdspell

# Glob Patterns erweitern
shopt -s globstar
