#!/usr/bin/env bash
# ============================================================
# Variables & Parameter Expansion
# ============================================================

# ----- Basic assignment --------------------------------------------------
# No spaces around '=' — bash interprets 'var = val' as a command named 'var'
demo_basics() {
    local name="bash"
    local version=5

    # Double quotes allow expansion; single quotes are literal
    echo "Hello from $name $version"
    echo 'Literal: $name $version'

    # Readonly prevents reassignment (silently ignored or error w/ set -e)
    readonly CONSTANT="immutable"
}

# ----- Default & fallback expansion -------------------------------------
demo_defaults() {
    local unset_var=""

    # ${var:-default}  — use default if unset OR empty
    echo "${unset_var:-fallback}"       # fallback

    # ${var-default}   — use default only if unset (not if empty)
    echo "${unset_var-not printed}"     # prints empty string

    # ${var:=default}  — assign default to var if unset/empty, then expand
    echo "${unset_var:=now_set}"        # now_set
    echo "$unset_var"                   # now_set (was assigned)

    # ${var:?error_msg} — abort with message if unset/empty (useful in scripts)
    # ${REQUIRED:?REQUIRED must be set}
}

# ----- String manipulation -----------------------------------------------
demo_string_ops() {
    local path="/home/user/docs/report.txt"

    # Length
    echo "${#path}"                     # 26

    # Remove shortest prefix matching pattern
    echo "${path#*/}"                   # home/user/docs/report.txt

    # Remove longest prefix matching pattern (greedy)
    echo "${path##*/}"                  # report.txt  (basename equivalent)

    # Remove shortest suffix
    echo "${path%.*}"                   # /home/user/docs/report

    # Remove longest suffix (greedy)
    echo "${path%%/*}"                  # empty — everything after first /

    # Substring: ${var:offset:length}
    echo "${path:6:4}"                  # user

    # Replace first match
    echo "${path/user/jaka}"            # /home/jaka/docs/report.txt

    # Replace all matches
    local csv="a,b,c,d"
    echo "${csv//,/ }"                  # a b c d

    # Case conversion (bash 4+)
    local word="Hello"
    echo "${word,,}"                    # hello (all lower)
    echo "${word^^}"                    # HELLO (all upper)
    echo "${word^}"                     # Hello (first char upper)
}

# ----- Indirect reference ------------------------------------------------
demo_indirect() {
    local color_red="255,0,0"
    local color_green="0,255,0"
    local selected="red"

    # ${!varname} — expand the variable whose name is in varname
    echo "${!color_$selected}"          # 255,0,0 — bash resolves color_red
}

# ----- Special variables -------------------------------------------------
demo_special() {
    echo "Script name : $0"
    echo "PID         : $$"
    echo "Last PID    : $!"             # PID of last backgrounded process
    echo "Exit status : $?"             # exit code of last command
    echo "Arg count   : $#"
    echo "All args    : $@"             # each arg as separate word (use in loops)
    echo "All args    : $*"             # all args as single word (use in strings)

    # IFS-aware difference: "$*" joins with first char of IFS, "$@" preserves words
    IFS=","
    args=("one" "two" "three")
    echo "${args[*]}"                   # one,two,three
    echo "${args[@]}"                   # one two three
    IFS=$' \t\n'                        # restore default IFS
}

main() {
    demo_basics
    demo_defaults
    demo_string_ops
    demo_indirect
    demo_special
}

main "$@"
