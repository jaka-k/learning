#!/usr/bin/env bash
# ============================================================
# Arrays — Indexed & Associative
# ============================================================

# ----- Indexed arrays ---------------------------------------------------
demo_indexed() {
    # Declaration
    local -a colors=("red" "green" "blue")

    # Access by index
    echo "${colors[0]}"               # red
    echo "${colors[-1]}"              # blue (negative index from bash 4.3+)

    # All elements — use [@] not [*]
    echo "${colors[@]}"               # red green blue

    # Length
    echo "${#colors[@]}"              # 3

    # Indices (sparse arrays can have gaps!)
    echo "${!colors[@]}"              # 0 1 2

    # Append
    colors+=("yellow")
    echo "${colors[-1]}"              # yellow

    # Assign to specific index (creates sparse array)
    colors[10]="purple"
    echo "${!colors[@]}"              # 0 1 2 3 10
    echo "${#colors[@]}"              # 5 — count of elements, not max index

    # Slicing: ${arr[@]:offset:length}
    echo "${colors[@]:1:2}"           # green blue
}

# ----- Modifying arrays -------------------------------------------------
demo_modify() {
    local -a arr=("a" "b" "c" "d" "e")

    # Delete element (leaves a hole — index is unset, not shifted)
    unset 'arr[2]'
    echo "${arr[@]}"                  # a b d e
    echo "${!arr[@]}"                 # 0 1 3 4  — gap at 2

    # Re-index to fill gaps
    arr=("${arr[@]}")
    echo "${!arr[@]}"                 # 0 1 2 3

    # Remove all elements
    unset arr
    echo "${arr[@]+set}"              # empty — arr is unset
}

# ----- Associative arrays (bash 4+) -------------------------------------
demo_associative() {
    # Must use declare -A — no shorthand literal syntax
    declare -A config=(
        [host]="localhost"
        [port]="5432"
        [db]="myapp"
    )

    echo "${config[host]}"            # localhost
    echo "${config[port]}"            # 5432

    # All keys
    echo "${!config[@]}"              # order is not guaranteed

    # All values
    echo "${config[@]}"

    # Check if key exists: use ${var+x} idiom
    if [[ -n "${config[host]+x}" ]]; then
        echo "host key exists"
    fi

    # Iterate key-value pairs
    for key in "${!config[@]}"; do
        echo "$key = ${config[$key]}"
    done

    # Delete a key
    unset 'config[db]'
    echo "${!config[@]}"
}

# ----- Arrays from command output ----------------------------------------
demo_from_command() {
    # mapfile (readarray) — read lines into array (bash 4+)
    # -t strips trailing newlines from each element
    mapfile -t lines < <(printf "line1\nline2\nline3\n")
    echo "${#lines[@]}"               # 3
    echo "${lines[1]}"                # line2

    # Word splitting into array (avoid for filenames with spaces)
    local words
    read -ra words <<< "one two three"
    echo "${words[1]}"                # two
}

main() {
    demo_indexed
    echo "---"
    demo_modify
    echo "---"
    demo_associative
    echo "---"
    demo_from_command
}

main "$@"
