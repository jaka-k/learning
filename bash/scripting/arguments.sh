#!/usr/bin/env bash
# ============================================================
# Arguments, Options & getopts
# ============================================================

# ----- Positional parameters --------------------------------------------
demo_positional() {
    # $1..$9 directly; ${10}+ require braces
    local first="${1:-<none>}"
    local second="${2:-<none>}"
    echo "First: $first, Second: $second"

    # shift moves positional params left — $2 becomes $1, etc.
    # shift N shifts by N positions
    set -- "a" "b" "c" "d"             # replace $@ in demo context
    shift 2
    echo "After shift 2: $@"           # c d
}

# ----- getopts — POSIX option parsing ------------------------------------
# getopts handles short options only (-x, -xval, -x val)
# For long options (--verbose), use getopt (external) or manual parsing
demo_getopts() {
    local verbose=false
    local output=""

    # Leading ':' in optstring enables silent error handling
    # A letter followed by ':' expects an argument (stored in $OPTARG)
    while getopts ":vo:" opt; do
        case $opt in
            v) verbose=true ;;
            o) output="$OPTARG" ;;
            :) echo "Option -$OPTARG requires an argument" >&2; return 1 ;;
            \?) echo "Unknown option: -$OPTARG" >&2; return 1 ;;
        esac
    done

    # Shift past the options to get to remaining positional args
    shift $((OPTIND - 1))
    OPTIND=1  # reset for next getopts call in the same shell

    echo "verbose=$verbose, output=${output:-stdout}, remaining=$*"
}

# ----- Manual long-option parsing ----------------------------------------
demo_long_opts() {
    local dry_run=false
    local name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)     dry_run=true ;;
            --name=*)      name="${1#*=}" ;;   # strip --name= prefix
            --name)        name="$2"; shift ;; # next arg is the value
            --)            shift; break ;;     # end of options
            -*|--*)        echo "Unknown: $1" >&2; return 1 ;;
            *)             break ;;            # first non-option arg
        esac
        shift
    done

    echo "dry_run=$dry_run, name=${name:-<unset>}, rest=$*"
}

# ----- $@ vs $* ----------------------------------------------------------
demo_array_args() {
    # Always use "$@" when forwarding args — preserves word splitting
    # "$*" would merge all args into one string

    local args=("hello world" "foo" "bar")

    for arg in "${args[@]}"; do
        echo "Arg: '$arg'"             # "hello world" stays together
    done

    # Wrong: for arg in "${args[*]}" — treats all as one word
    # Wrong: for arg in $args        — unquoted, splits on spaces
}

main() {
    demo_positional
    demo_getopts -v -o myfile.txt leftover1 leftover2
    demo_long_opts --dry-run --name=jaka extra
    demo_array_args
}

main "$@"
