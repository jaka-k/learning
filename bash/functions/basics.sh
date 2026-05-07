#!/usr/bin/env bash
# ============================================================
# Functions — Definition, Scope & Return Values
# ============================================================

# ----- Two definition syntaxes ------------------------------------------
# Both are equivalent; prefer the 'name()' form (POSIX compatible)
demo_syntax() {
    greet() { echo "Hello, $1"; }
    function greet2 { echo "Hi, $1"; }   # 'function' keyword is bash-only

    greet "world"
    greet2 "bash"
}

# ----- Local vs global scope --------------------------------------------
demo_scope() {
    global_var="I am global"

    modify() {
        local local_var="only inside modify"
        global_var="modified by function"  # modifies the global
        echo "local_var: $local_var"
    }

    modify
    echo "global_var: $global_var"
    # echo "$local_var"  # empty — local_var is gone after modify returns
}

# ----- Return values: exit codes vs stdout ------------------------------
# Functions can't return arbitrary values — only a 0-255 exit code
# Convention: return 0 for success, non-zero for failure
# To "return" a value, echo it and capture with $()

add() {
    echo $(( $1 + $2 ))
}

is_even() {
    (( $1 % 2 == 0 ))   # arithmetic command exits 0 (true) or 1 (false)
}

demo_return_values() {
    local sum
    sum=$(add 3 7)
    echo "Sum: $sum"                  # 10

    if is_even 4; then
        echo "4 is even"
    fi

    if ! is_even 5; then
        echo "5 is not even"
    fi

    # Capturing exit code explicitly
    is_even 6
    echo "Exit code: $?"              # 0 (success / true)
}

# ----- Passing arrays to functions --------------------------------------
# Bash doesn't pass arrays by value — pass by name and use nameref (bash 4.3+)
print_array() {
    local -n arr_ref=$1               # nameref: arr_ref is an alias for the named var
    for item in "${arr_ref[@]}"; do
        echo "  - $item"
    done
}

demo_array_passing() {
    local fruits=("apple" "banana" "cherry")
    print_array fruits                # pass the name, not the value
}

# ----- Functions as first-class values ----------------------------------
# Bash doesn't have function references, but you can use names as strings
apply() {
    local fn="$1"
    local arg="$2"
    "$fn" "$arg"                      # call function by name stored in variable
}

shout() { echo "${1^^}!"; }

demo_higher_order() {
    apply shout "hello"               # HELLO!
}

main() {
    demo_syntax
    demo_scope
    demo_return_values
    demo_array_passing
    demo_higher_order
}

main "$@"
