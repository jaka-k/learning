# Bash Dotfiles Reference

## Load order

| File | When loaded |
|------|-------------|
| `/etc/profile` | Login shell — system-wide |
| `~/.bash_profile` | Login shell — user (sources `~/.bashrc` by convention) |
| `~/.bashrc` | Interactive non-login shell (new terminal tab, `bash` command) |
| `~/.bash_logout` | Login shell exit |
| `~/.inputrc` | Readline config (key bindings, completion behavior) |

**Rule of thumb**: put everything in `~/.bashrc`; have `~/.bash_profile` source it.

```bash
# ~/.bash_profile
[[ -f ~/.bashrc ]] && source ~/.bashrc
```

## Key `.bashrc` sections

### Prompt (PS1)

```bash
# Colors: \e[<style>;<fg>m ... \e[0m  (style: 0=reset, 1=bold; fg: 31=red, 32=green, 33=yellow, 34=blue)
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# Or use PROMPT_COMMAND for dynamic content
PROMPT_COMMAND='PS1="$(git_branch_prompt)\$ "'
```

### History

```bash
HISTSIZE=50000              # lines kept in memory
HISTFILESIZE=100000         # lines kept in ~/.bash_history
HISTCONTROL=ignoredups:erasedups  # skip and erase duplicate entries
HISTTIMEFORMAT="%F %T  "   # timestamp each entry
shopt -s histappend         # append to history file instead of overwriting
```

### Options (shopt)

```bash
shopt -s autocd             # 'dirname' without cd changes directory
shopt -s cdspell            # correct minor typos in cd path
shopt -s checkwinsize       # update LINES/COLUMNS after each command
shopt -s globstar           # ** matches files recursively
shopt -s extglob            # extended glob: ?(pat) +(pat) *(pat) @(pat) !(pat)
shopt -s nocaseglob         # case-insensitive globbing
```

### Aliases

```bash
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias mkdir='mkdir -pv'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
```

### Functions in `.bashrc`

```bash
# Quick directory bookmarking
bookmark() { export "BM_${1:?usage: bookmark NAME}=$PWD"; }
go() { local target="BM_${1:?usage: go NAME}"; cd "${!target}"; }

# Extract any archive format
extract() {
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.7z)      7z x "$1" ;;
        *)         echo "Unknown format: $1" ;;
    esac
}

# mkdir + cd
mkcd() { mkdir -p "$1" && cd "$1"; }
```

### Environment variables

```bash
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-RFX'          # -R: colors, -F: quit if fits screen, -X: no clear on exit
export LANG=en_US.UTF-8
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
```

## `.inputrc` (Readline)

```ini
# Case-insensitive tab completion
set completion-ignore-case on

# Show all matches immediately (no need to press Tab twice)
set show-all-if-ambiguous on

# Color files by type in completion list
set colored-stats on

# Up/down arrow searches history with current prefix
"\e[A": history-search-backward
"\e[B": history-search-forward

# Ctrl+arrows to move word by word
"\e[1;5C": forward-word
"\e[1;5D": backward-word
```

## Debugging dotfiles

```bash
bash -x ~/.bashrc           # trace execution of .bashrc
bash --norc                 # start without loading .bashrc
bash --noprofile            # start without loading .bash_profile
time bash -i -c exit        # measure startup time
```
