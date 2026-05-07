# ~/.bashrc — interactive shell configuration
# Sourced for every new interactive non-login bash shell

# ----- Guard: only run for interactive shells --------------------------
[[ $- != *i* ]] && return

# ----- History ----------------------------------------------------------
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:erasedups   # skip duplicates and remove older copies
HISTTIMEFORMAT="%F %T  "
shopt -s histappend                 # append rather than overwrite ~/.bash_history
PROMPT_COMMAND="history -a"         # flush history after every command

# ----- Shell options (shopt) -------------------------------------------
shopt -s autocd                     # type a dir name to cd into it
shopt -s cdspell                    # correct minor typos in cd arguments
shopt -s checkwinsize               # update LINES/COLUMNS on resize
shopt -s globstar                   # ** for recursive globbing
shopt -s extglob                    # ?(pat) *(pat) +(pat) @(pat) !(pat)
shopt -s nocaseglob                 # case-insensitive glob
shopt -s cmdhist                    # save multiline commands as one history entry

# ----- Environment ------------------------------------------------------
export EDITOR=nvim
export VISUAL=nvim
export PAGER="less -RFX"
export LANG=en_US.UTF-8
export LESS='-RFX --mouse'
export GREP_COLOR='1;32'

# Local bin directories first
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ----- Prompt -----------------------------------------------------------
# Minimal prompt with git branch
_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
    printf " (%s)" "$branch"
}

# Colors: \[ \] wraps non-printing sequences so readline counts width correctly
GREEN='\[\e[1;32m\]'
BLUE='\[\e[1;34m\]'
YELLOW='\[\e[1;33m\]'
RESET='\[\e[0m\]'

PS1="${GREEN}\u@\h${RESET}:${BLUE}\w${YELLOW}\$(_git_branch)${RESET}\$ "

# ----- Aliases ----------------------------------------------------------
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'

# Navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gp='git push'
alias gc='git commit'

# ----- Functions --------------------------------------------------------

# mkdir + cd in one step
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Jump to a git repo root
root() {
    local r
    r=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repo"; return 1; }
    cd "$r"
}

# Extract any common archive format
extract() {
    [[ -f "$1" ]] || { echo "File not found: $1"; return 1; }
    case "$1" in
        *.tar.bz2)  tar xjf "$1"   ;;
        *.tar.gz)   tar xzf "$1"   ;;
        *.tar.xz)   tar xJf "$1"   ;;
        *.bz2)      bunzip2 "$1"   ;;
        *.gz)       gunzip "$1"    ;;
        *.zip)      unzip "$1"     ;;
        *.7z)       7z x "$1"      ;;
        *.rar)      unrar x "$1"   ;;
        *)          echo "Unknown format: $1" ;;
    esac
}

# Simple HTTP server in current dir
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# Quick notes
note() {
    local notes_dir="$HOME/.notes"
    mkdir -p "$notes_dir"
    if [[ $# -eq 0 ]]; then
        ls "$notes_dir"
    else
        "${EDITOR:-nano}" "$notes_dir/$1.md"
    fi
}

# Portable 'which' with fallback details
what() {
    type -a "$1"
    command -v "$1" | xargs file 2>/dev/null
}

# ----- Completion -------------------------------------------------------
# Source system bash completion if available
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
    source /etc/bash_completion
fi

# ----- Local overrides --------------------------------------------------
# Source machine-specific settings without cluttering this file
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
