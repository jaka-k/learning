#!/usr/bin/env bash
# ============================================================
# I/O Redirection, Here-docs & Process Substitution
# ============================================================

# ----- Basic redirection -------------------------------------------------
demo_basic_redirection() {
    local tmpfile
    tmpfile=$(mktemp)

    # Stdout to file (truncate)
    echo "hello" > "$tmpfile"

    # Stdout to file (append)
    echo "world" >> "$tmpfile"

    # Stderr to file
    ls /nonexistent 2> "$tmpfile"

    # Both stdout and stderr to file
    ls /nonexistent > "$tmpfile" 2>&1       # 2>&1 must come after >
    ls /nonexistent &> "$tmpfile"           # bash shorthand (same effect)

    # Discard output
    ls /nonexistent 2>/dev/null

    # Stdin from file
    wc -l < "$tmpfile"

    rm "$tmpfile"
}

# ----- File descriptor manipulation -------------------------------------
demo_fd_tricks() {
    local tmpfile
    tmpfile=$(mktemp)

    # Open fd 3 for writing, write to it, close it
    exec 3> "$tmpfile"
    echo "line via fd3" >&3
    exec 3>&-                              # close fd 3

    # Open fd 4 for reading
    exec 4< "$tmpfile"
    while IFS= read -r line <&4; do
        echo "Read: $line"
    done
    exec 4<&-                              # close fd 4

    # Swap stdout and stderr
    # exec 3>&1 1>&2 2>&3 3>&-            # fd3=stdout, stdout=stderr, stderr=old-stdout

    rm "$tmpfile"
}

# ----- Here-documents ----------------------------------------------------
demo_heredoc() {
    # Standard here-doc — expansion happens (variables, command substitution)
    local name="jaka"
    cat <<EOF
Hello, $name!
Today is $(date +%F).
EOF

    # Quoted delimiter — no expansion (literal)
    cat <<'EOF'
No expansion: $name $(date)
EOF

    # Indented here-doc with <<- — strips leading tabs (not spaces!)
    cat <<-EOF
	This line has a leading tab that gets stripped.
	So does this one.
	EOF

    # Here-string — feed a single string as stdin
    wc -w <<< "one two three four"         # 4
}

# ----- Process substitution ----------------------------------------------
demo_process_substitution() {
    # <(cmd) — creates a named pipe; cmd's stdout is readable as a file
    # Useful when a command needs a filename, not a pipe

    # diff two commands' output without temp files
    diff <(ls /bin) <(ls /usr/bin) | head -5

    # Read from process substitution
    while IFS= read -r line; do
        echo "Host: $line"
    done < <(hostname)

    # >(cmd) — feed a file argument to a command that reads from it
    # tee to two commands simultaneously
    echo "data" | tee >(wc -c) >(tr 'a-z' 'A-Z') > /dev/null
}

main() {
    demo_basic_redirection
    echo "---"
    demo_fd_tricks
    echo "---"
    demo_heredoc
    echo "---"
    demo_process_substitution
}

main "$@"
