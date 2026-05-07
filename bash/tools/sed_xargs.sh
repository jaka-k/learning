#!/usr/bin/env bash
# ============================================================
# sed & xargs — Stream Editing & Batch Execution
# ============================================================

# ============================================================
# sed
# ============================================================
# sed reads input line by line, applies commands, and prints to stdout.
# It does NOT edit files in place unless -i is used.

demo_sed_substitution() {
    local text="the quick brown fox jumps over the lazy dog"

    # s/pattern/replacement/flags
    # g = global (all occurrences), i = case-insensitive, p = print matched line
    echo "$text" | sed 's/the/a/g'
    echo "$text" | sed 's/FOX/cat/i'
    echo "$text" | sed 's/\bthe\b/a/g'      # word-boundary (GNU sed)

    # Capture groups with & (whole match) and \1 (group 1)
    echo "john smith" | sed 's/\([a-z]*\) \([a-z]*\)/\2, \1/'   # smith, john
    echo "john smith" | sed -E 's/([a-z]+) ([a-z]+)/\2, \1/'    # ERE with -E
}

demo_sed_addresses() {
    local data
    data=$(printf "header\nline1\nline2\nline3\nfooter\n")

    # Address: line number, regex, or range
    echo "$data" | sed '1d'             # delete line 1
    echo "$data" | sed '$d'             # delete last line
    echo "$data" | sed '2,4d'           # delete lines 2-4
    echo "$data" | sed '/header/d'      # delete lines matching pattern
    echo "$data" | sed '/line/,/foot/d' # delete from first /line/ to first /foot/
    echo "$data" | sed -n '2,3p'        # print only lines 2-3 (-n suppresses default print)
}

demo_sed_multiline() {
    # N — append next line to pattern space (join two lines)
    printf "hello\nworld\n" | sed 'N; s/\n/ /'   # hello world

    # d after pattern with P;D — sliding window
    # P — print up to first newline; D — delete up to first newline, restart
}

demo_sed_inplace() {
    local tmpfile
    tmpfile=$(mktemp --suffix=.txt)
    echo "old text here" > "$tmpfile"

    # -i: in-place edit; -i.bak: create backup first (portable across GNU/BSD)
    sed -i.bak 's/old/new/' "$tmpfile"
    cat "$tmpfile"

    rm -f "$tmpfile" "${tmpfile}.bak"
}

# ============================================================
# xargs
# ============================================================
# xargs reads items from stdin and builds command lines from them.
# Avoids "argument list too long" errors and enables parallel execution.

demo_xargs_basics() {
    # Basic: pipe a list and pass each as an argument
    echo "one two three" | xargs echo "Items:"

    # -n 1: one argument per command invocation
    printf "a\nb\nc\n" | xargs -n 1 echo "Item:"

    # -n 2: two arguments per invocation
    printf "1\n2\n3\n4\n" | xargs -n 2 echo "Pair:"

    # -I {}: replace {} with each item (like a for loop)
    printf "alpha\nbeta\n" | xargs -I {} echo "Got: {}"
}

demo_xargs_parallel() {
    # -P N: run up to N processes in parallel
    # Combined with -n 1, one item per process
    printf "1\n2\n3\n4\n" | xargs -n 1 -P 4 bash -c 'echo "Processing: $1"' _
}

demo_xargs_null() {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/file with spaces.txt" "$tmpdir/normal.txt"

    # find -print0 / xargs -0: null-terminated — safe for filenames with spaces
    find "$tmpdir" -name "*.txt" -print0 | xargs -0 ls -la

    rm -rf "$tmpdir"
}

demo_xargs_from_find() {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/a.sh" "$tmpdir/b.sh"

    # Prefer find -exec + over xargs for simple cases (no shell invocation)
    # Use xargs when you need shell features or explicit parallelism

    # Count lines in all .sh files
    find "$tmpdir" -name "*.sh" -print0 | xargs -0 wc -l

    rm -rf "$tmpdir"
}

main() {
    echo "=== sed substitution ==="
    demo_sed_substitution
    echo "=== sed addresses ==="
    demo_sed_addresses
    echo "=== sed multiline ==="
    demo_sed_multiline
    echo "=== sed in-place ==="
    demo_sed_inplace
    echo "=== xargs basics ==="
    demo_xargs_basics
    echo "=== xargs parallel ==="
    demo_xargs_parallel
    echo "=== xargs null ==="
    demo_xargs_null
    echo "=== xargs + find ==="
    demo_xargs_from_find
}

main "$@"
