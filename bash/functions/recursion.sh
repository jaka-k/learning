#!/usr/bin/env bash
# ============================================================
# Recursion & Advanced Function Patterns
# ============================================================

# ----- Factorial (classic recursion) ------------------------------------
factorial() {
    local n=$1
    if (( n <= 1 )); then
        echo 1
        return
    fi
    local sub
    sub=$(factorial $(( n - 1 )))
    echo $(( n * sub ))
}

# ----- Directory tree traversal -----------------------------------------
# Bash recursion depth is limited (~1000 by default via FUNCNEST)
walk_dir() {
    local dir="$1"
    local indent="${2:-}"

    for entry in "$dir"/*; do
        [[ -e "$entry" ]] || continue          # handle empty dirs (nullglob off)
        echo "${indent}$(basename "$entry")"
        if [[ -d "$entry" ]]; then
            walk_dir "$entry" "${indent}  "    # recurse with increased indent
        fi
    done
}

# ----- Memoization via associative array --------------------------------
declare -A _fib_cache

fib() {
    local n=$1
    if [[ -n "${_fib_cache[$n]+x}" ]]; then   # '+x' checks key existence, not value
        echo "${_fib_cache[$n]}"
        return
    fi
    if (( n <= 1 )); then
        _fib_cache[$n]=$n
        echo $n
        return
    fi
    local a b
    a=$(fib $(( n - 1 )))
    b=$(fib $(( n - 2 )))
    local result=$(( a + b ))
    _fib_cache[$n]=$result
    echo $result
}

# ----- FUNCNEST — limit recursion depth ---------------------------------
demo_funcnest() {
    # FUNCNEST caps the call stack depth; defaults to unlimited in most distros
    # Set it to prevent runaway recursion from killing the shell
    local saved=$FUNCNEST
    FUNCNEST=10

    infinite() { infinite; }
    infinite 2>/dev/null && echo "didn't hit limit" || echo "recursion capped at FUNCNEST=$FUNCNEST"

    FUNCNEST=$saved
    unset -f infinite
}

main() {
    echo "5! = $(factorial 5)"
    echo "10! = $(factorial 10)"

    echo ""
    echo "Directory tree of /tmp (depth ~2):"
    walk_dir /tmp "  " 2>/dev/null | head -20

    echo ""
    echo "Fibonacci(10) = $(fib 10)"
    echo "Fibonacci(15) = $(fib 15)"

    echo ""
    demo_funcnest
}

main "$@"
