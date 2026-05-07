#!/usr/bin/env bash
# ============================================================
# Conditionals — if, [[ ]], (( )), test
# ============================================================

# ----- [[ ]] — preferred conditional ---------------------------------
demo_string_tests() {
    local a="hello"
    local b=""

    [[ -n "$a" ]] && echo "a is non-empty"
    [[ -z "$b" ]] && echo "b is empty"
    [[ "$a" == "hello" ]] && echo "string equality"
    [[ "$a" != "world" ]] && echo "string inequality"
    [[ "$a" < "zz" ]] && echo "lexicographic less-than"

    # Pattern matching (not regex) — no quotes around pattern
    [[ "$a" == h* ]] && echo "starts with h"

    # Regex matching — capture groups in BASH_REMATCH
    local version="v1.2.3"
    if [[ "$version" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        echo "major=${BASH_REMATCH[1]}, minor=${BASH_REMATCH[2]}, patch=${BASH_REMATCH[3]}"
    fi
}

# ----- (( )) — arithmetic conditionals ----------------------------------
demo_arithmetic_tests() {
    local x=10

    (( x > 5 ))  && echo "x > 5"
    (( x == 10 )) && echo "x == 10"
    (( x % 2 == 0 )) && echo "x is even"

    # Inside (( )), variables don't need $ (but it's allowed)
    (( x * 2 > 15 )) && echo "x*2 > 15"
}

# ----- File tests --------------------------------------------------------
demo_file_tests() {
    local f="/etc/hostname"

    [[ -e "$f" ]] && echo "exists"
    [[ -f "$f" ]] && echo "is regular file"
    [[ -d "/tmp" ]] && echo "/tmp is a directory"
    [[ -r "$f" ]] && echo "readable"
    [[ -w "$f" ]] || echo "not writable by current user"
    [[ -x "/bin/bash" ]] && echo "/bin/bash is executable"
    [[ -s "$f" ]] && echo "non-empty file"
    [[ "$f" -nt "/etc/passwd" ]] && echo "hostname newer than passwd" || echo "passwd is newer or same age"
}

# ----- Compound conditions -----------------------------------------------
demo_compound() {
    local age=25
    local name="jaka"

    # && and || inside [[ ]] — short-circuit
    if [[ $age -ge 18 && "$name" == "jaka" ]]; then
        echo "adult named jaka"
    fi

    # Equivalent with separate [[ ]] — slightly different semantics for errors
    if [[ $age -ge 18 ]] && [[ "$name" == "jaka" ]]; then
        echo "same result"
    fi
}

# ----- Ternary-style idioms ----------------------------------------------
demo_ternary() {
    local n=7

    # Short-circuit as ternary
    (( n % 2 == 0 )) && echo "even" || echo "odd"

    # Warning: the above breaks if the 'true' branch fails
    # Safer: use if/else or a function

    local label
    label=$(( n % 2 == 0 ? 0 : 1 ))  # arithmetic expansion — 0 for even, 1 for odd
    echo "label=$label"
}

main() {
    demo_string_tests
    echo "---"
    demo_arithmetic_tests
    echo "---"
    demo_file_tests
    echo "---"
    demo_compound
    echo "---"
    demo_ternary
}

main "$@"
