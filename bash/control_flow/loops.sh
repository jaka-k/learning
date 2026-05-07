#!/usr/bin/env bash
# ============================================================
# Loops — for, while, until, select
# ============================================================

# ----- for — iterate over a list ----------------------------------------
demo_for_list() {
    for color in red green blue; do
        echo "Color: $color"
    done

    # Iterate over array — always quote "${arr[@]}"
    local -a fruits=("apple" "banana" "kiwi")
    for fruit in "${fruits[@]}"; do
        echo "Fruit: $fruit"
    done

    # Iterate with index
    for i in "${!fruits[@]}"; do
        echo "[$i] ${fruits[$i]}"
    done
}

# ----- C-style for loop --------------------------------------------------
demo_for_c_style() {
    for (( i = 0; i < 5; i++ )); do
        printf "%d " $i
    done
    echo

    # Nested with break/continue
    for (( i = 0; i < 3; i++ )); do
        for (( j = 0; j < 3; j++ )); do
            (( i == j )) && continue        # skip diagonal
            printf "(%d,%d) " $i $j
        done
    done
    echo
}

# ----- Brace expansion in loops -----------------------------------------
demo_brace_expansion() {
    for n in {1..5}; do printf "%d " $n; done; echo

    # Step value (bash 4+)
    for n in {0..10..2}; do printf "%d " $n; done; echo

    # Character ranges
    for c in {a..e}; do printf "%s " $c; done; echo
}

# ----- while — condition-based loop -------------------------------------
demo_while() {
    local count=0
    while (( count < 3 )); do
        echo "count=$count"
        (( count++ ))
    done

    # Read lines from a file (or stdin) — IFS= prevents stripping leading whitespace
    # while IFS= read -r line; do
    #     echo "Line: $line"
    # done < /etc/hostname

    # Read from a command
    while IFS= read -r line; do
        echo "host: $line"
    done < <(hostname)                 # process substitution — <() runs cmd in subshell
}

# ----- until — loop until condition is true -----------------------------
demo_until() {
    local n=5
    until (( n == 0 )); do
        echo "n=$n"
        (( n-- ))
    done
}

# ----- select — interactive menu ----------------------------------------
demo_select() {
    # select prints a numbered menu and reads user choice into the variable
    # PS3 is the prompt shown; REPLY holds the raw input
    # In non-interactive scripts, select loops forever on empty input — use a timeout or skip
    echo "(skipping select in non-interactive mode)"

    # Example of what it looks like:
    # PS3="Choose a fruit: "
    # select fruit in apple banana cherry quit; do
    #     case $fruit in
    #         quit) break ;;
    #         "")   echo "Invalid choice: $REPLY" ;;
    #         *)    echo "You picked $fruit" ;;
    #     esac
    # done
}

# ----- Loop control: break with level ------------------------------------
demo_break_levels() {
    for (( i = 0; i < 3; i++ )); do
        for (( j = 0; j < 3; j++ )); do
            (( i == 1 && j == 1 )) && break 2   # break 2 exits both loops
            printf "(%d,%d) " $i $j
        done
    done
    echo "(broke out at i=1,j=1)"
}

main() {
    demo_for_list
    echo "---"
    demo_for_c_style
    echo "---"
    demo_brace_expansion
    echo "---"
    demo_while
    echo "---"
    demo_until
    echo "---"
    demo_select
    echo "---"
    demo_break_levels
}

main "$@"
