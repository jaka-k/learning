#!/usr/bin/env bash
# ============================================================
# Quoting, Word Splitting & Globbing
# ============================================================

# ----- The three quoting styles -----------------------------------------
demo_quote_types() {
    local name="world"

    echo "Double: Hello $name"         # expands variables and \n \t etc.
    echo 'Single: Hello $name'         # completely literal — no expansion
    echo $'Escape: tab\there'          # $'...' interprets C-style escapes

    # ANSI-C quoting: $'\n' $'\t' $'\xHH' $'\uHHHH'
    printf '%s\n' $'line1\nline2'      # actually two lines
}

# ----- Word splitting ----------------------------------------------------
demo_word_splitting() {
    local files="file1.txt file2.txt file3.txt"

    # Unquoted: bash splits on IFS (default: space, tab, newline)
    for f in $files; do
        echo "File: $f"               # works here but fragile with spaces in names
    done

    # Quoted: treated as one word — usually wrong for lists
    for f in "$files"; do
        echo "Whole string: $f"       # prints the entire string once
    done

    # Correct pattern: use arrays instead of space-separated strings
    local -a file_array=("file 1.txt" "file2.txt" "file3.txt")
    for f in "${file_array[@]}"; do
        echo "Array element: $f"      # preserves spaces in names
    done
}

# ----- Glob expansion ----------------------------------------------------
demo_globbing() {
    # Globbing happens after word splitting, before command execution
    # *  — matches any string (not starting with .)
    # ?  — matches any single character
    # [] — character class

    # nullglob: unmatched globs expand to nothing instead of literal pattern
    shopt -s nullglob
    for f in /tmp/*.nonexistent; do
        echo "$f"                     # never prints — glob expands to nothing
    done
    shopt -u nullglob

    # globstar (bash 4+): ** matches directories recursively
    shopt -s globstar
    # for f in **/*.sh; do echo "$f"; done
    shopt -u globstar

    # Disable globbing entirely when you need literal * in a value
    set -f
    echo "no glob: *"                 # prints literal *
    set +f
}

# ----- Quoting pitfalls --------------------------------------------------
demo_pitfalls() {
    # Pitfall 1: unquoted variable with spaces in value
    local file="my file.txt"
    # touch $file     # creates TWO files: 'my' and 'file.txt'
    # touch "$file"   # creates ONE file: 'my file.txt'

    # Pitfall 2: command substitution strips trailing newlines
    local output
    output=$(printf "line1\nline2\n")
    echo "$output"                    # trailing newline stripped — usually fine
    printf '%s' "$output" | wc -c    # count bytes without extra newline

    # Pitfall 3: eval and injection — avoid unless absolutely necessary
    # eval "echo $user_input"  — NEVER do this with untrusted input

    # Pitfall 4: [ vs [[ — always prefer [[
    # [ uses external test binary, splits words, no regex
    # [[ is bash built-in, smarter quoting, supports =~ regex
    local val="hello world"
    if [[ $val == *"world"* ]]; then  # no quoting needed around $val in [[
        echo "contains world"
    fi
}

main() {
    demo_quote_types
    demo_word_splitting
    demo_globbing
    demo_pitfalls
}

main "$@"
