#!/usr/bin/env bash
# ============================================================
# find & grep — File Search & Content Matching
# ============================================================

# ----- find — file system search ----------------------------------------
demo_find_basics() {
    # Find files by name pattern
    find /tmp -name "*.sh" 2>/dev/null | head -5

    # Case-insensitive name match
    find /tmp -iname "*.SH" 2>/dev/null | head -5

    # By type: f=file, d=directory, l=symlink
    find /etc -type f -name "*.conf" 2>/dev/null | head -5

    # By size: +1M = over 1MB, -1k = under 1KB, 512c = exactly 512 bytes
    find /var/log -type f -size +1M 2>/dev/null | head -5

    # By modification time: -mtime -1 = modified in last 24h
    find /tmp -mtime -1 2>/dev/null | head -5

    # By permissions
    find /tmp -perm 777 2>/dev/null | head -5
    find /etc -perm /u+w 2>/dev/null | head -5  # user-writable
}

# ----- find with actions ------------------------------------------------
demo_find_actions() {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/a.txt" "$tmpdir/b.log" "$tmpdir/c.txt"

    # -print (default), -delete, -exec
    find "$tmpdir" -name "*.txt" -print

    # -exec: {} is the found file; \; runs once per file
    find "$tmpdir" -name "*.txt" -exec echo "Found: {}" \;

    # -exec with + : runs once with all files (like xargs — faster)
    find "$tmpdir" -name "*.txt" -exec ls -la {} +

    # -execdir: runs in the file's directory (safer for untrusted paths)
    find "$tmpdir" -name "*.log" -execdir pwd \;

    # Combine conditions: -and (default), -or, -not
    find "$tmpdir" \( -name "*.txt" -or -name "*.log" \) -not -name "b*"

    rm -rf "$tmpdir"
}

# ----- grep — content search --------------------------------------------
demo_grep() {
    local tmpfile
    tmpfile=$(mktemp)
    printf "apple pie\nbanana split\ncherry tart\nAPPLE juice\n" > "$tmpfile"

    grep "apple" "$tmpfile"             # case-sensitive match
    grep -i "apple" "$tmpfile"          # case-insensitive
    grep -v "apple" "$tmpfile"          # invert: lines NOT matching
    grep -n "apple" "$tmpfile"          # show line numbers
    grep -c "apple" "$tmpfile"          # count matching lines
    grep -l "apple" "$tmpfile"          # list filenames (useful with globs)

    # Extended regex: -E (same as egrep)
    grep -E "^(apple|banana)" "$tmpfile"

    # Only print the matching part
    grep -Eo "[a-z]+" "$tmpfile" | sort -u

    # Recursive search
    # grep -r "pattern" /path/to/dir
    # grep -rl "pattern" /path       # only filenames

    rm "$tmpfile"
}

# ----- ripgrep / ag — modern alternatives --------------------------------
demo_modern_grep() {
    # rg (ripgrep) — respects .gitignore, much faster, sane defaults
    # ag (the silver searcher) — similar to rg but older

    if command -v rg &>/dev/null; then
        rg --type sh "function" . 2>/dev/null | head -5
    else
        echo "rg not installed; falling back to grep -r"
        grep -r --include="*.sh" "function" . 2>/dev/null | head -5
    fi
}

main() {
    echo "=== find basics ==="
    demo_find_basics
    echo "=== find actions ==="
    demo_find_actions
    echo "=== grep ==="
    demo_grep
    echo "=== modern grep ==="
    demo_modern_grep
}

main "$@"
