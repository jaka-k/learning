#!/usr/bin/env bash
# ============================================================
# Regex — [[ =~ ]], BASH_REMATCH, grep & sed patterns
# ============================================================

# ----- Basic regex with [[ =~ ]] ----------------------------------------
demo_basic_regex() {
    local email="user@example.com"

    # ERE (Extended Regular Expressions) — same as grep -E
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Valid email"
    fi

    # BASH_REMATCH[0] = full match, [1] = first capture group, etc.
    local date="2024-12-25"
    if [[ "$date" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
        echo "Year:  ${BASH_REMATCH[1]}"
        echo "Month: ${BASH_REMATCH[2]}"
        echo "Day:   ${BASH_REMATCH[3]}"
    fi
}

# ----- Store regex in variable to avoid quoting issues ------------------
demo_regex_var() {
    # Do NOT quote the regex on the right side of =~
    # Quoting forces literal string comparison
    local ip="192.168.1.100"
    local ip_pattern='^([0-9]{1,3}\.){3}[0-9]{1,3}$'   # store in var, unquoted in test

    if [[ "$ip" =~ $ip_pattern ]]; then
        echo "Looks like an IP: $ip"
    fi

    # Wrong: [[ "$ip" =~ "$ip_pattern" ]]  — treats pattern as literal string
}

# ----- POSIX character classes -------------------------------------------
demo_posix_classes() {
    local test_str="Hello123!"

    # [[:alpha:]]  — letters
    # [[:digit:]]  — digits
    # [[:alnum:]]  — letters + digits
    # [[:space:]]  — whitespace
    # [[:upper:]]  — uppercase letters
    # [[:lower:]]  — lowercase letters
    # [[:punct:]]  — punctuation

    if [[ "$test_str" =~ [[:punct:]] ]]; then
        echo "Contains punctuation"
    fi

    if [[ "$test_str" =~ ^[[:alpha:]] ]]; then
        echo "Starts with a letter"
    fi
}

# ----- grep for filtering ------------------------------------------------
demo_grep() {
    local data
    data=$(printf "apple\nbanana\ncherry\napricot\nblueberry\n")

    # -E: extended regex, -o: only matching part, -i: case insensitive
    echo "$data" | grep -E '^a'                # lines starting with a
    echo "$data" | grep -E 'an'                # lines containing 'an'
    echo "$data" | grep -Eo '[aeiou]+'         # extract vowel sequences
    echo "$data" | grep -v 'an'                # lines NOT containing 'an'
    echo "$data" | grep -c '.'                 # count matching lines
}

# ----- sed for substitution ----------------------------------------------
demo_sed() {
    local text="The quick brown fox jumps over the lazy dog"

    # Basic substitution
    echo "$text" | sed 's/fox/cat/'            # first match
    echo "$text" | sed 's/the/a/gi'            # all matches, case insensitive

    # Capture groups with \1 \2 (BRE) or \1 \2 in ERE with -E
    echo "2024-12-25" | sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})/\3\/\2\/\1/'
    # Output: 25/12/2024

    # Delete lines matching pattern
    printf "keep\ndelete-me\nkeep-too\n" | sed '/delete/d'

    # In-place edit with backup (avoid in scripts — use temp file instead)
    # sed -i.bak 's/old/new/g' file.txt
}

main() {
    demo_basic_regex
    echo "---"
    demo_regex_var
    echo "---"
    demo_posix_classes
    echo "---"
    echo "grep demos:"
    demo_grep
    echo "---"
    echo "sed demos:"
    demo_sed
}

main "$@"
