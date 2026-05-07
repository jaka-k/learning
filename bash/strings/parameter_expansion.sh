#!/usr/bin/env bash
# ============================================================
# Parameter Expansion — Advanced Patterns
# ============================================================

# ----- Substitution & transformation ------------------------------------
demo_substitution() {
    local str="Hello, World! Hello, Bash!"

    # Replace first match
    echo "${str/Hello/Hi}"             # Hi, World! Hello, Bash!

    # Replace all matches
    echo "${str//Hello/Hi}"            # Hi, World! Hi, Bash!

    # Replace only at start (# anchors to beginning)
    echo "${str/#Hello/Greetings}"     # Greetings, World! Hello, Bash!

    # Replace only at end (% anchors to end)
    echo "${str/%Bash!/Shell}"         # Hello, World! Hello, Shell

    # Delete matches (replace with nothing)
    echo "${str//Hello, /}"            # World! Bash!
}

# ----- Prefix & suffix stripping ----------------------------------------
demo_stripping() {
    local path="/home/jaka/projects/app/main.sh"

    # ${var#pattern}  — remove shortest matching prefix
    echo "${path#/home/}"              # jaka/projects/app/main.sh

    # ${var##pattern} — remove longest matching prefix (greedy)
    echo "${path##*/}"                 # main.sh  (basename)

    # ${var%pattern}  — remove shortest matching suffix
    echo "${path%.sh}"                 # /home/jaka/projects/app/main

    # ${var%%pattern} — remove longest matching suffix (greedy)
    echo "${path%%/*}"                 # empty — everything after first /

    # Practical: get directory from path without dirname
    echo "${path%/*}"                  # /home/jaka/projects/app  (dirname)

    # Change file extension
    local file="report.csv"
    echo "${file%.csv}.json"           # report.json
}

# ----- Case conversion (bash 4+) -----------------------------------------
demo_case_conversion() {
    local str="Hello World"

    echo "${str,,}"                    # hello world  (all lowercase)
    echo "${str^^}"                    # HELLO WORLD  (all uppercase)
    echo "${str^}"                     # Hello World  (first char upper)
    echo "${str,}"                     # hello World  (first char lower)

    # Apply to specific character class
    local snake="hello_world_foo"
    echo "${snake//_/ }"              # hello world foo (replace underscores)
}

# ----- Substring extraction ----------------------------------------------
demo_substring() {
    local str="abcdefghij"

    echo "${str:3}"                    # defghij (from index 3)
    echo "${str:3:4}"                  # defg (4 chars from index 3)
    echo "${str: -3}"                  # hij (last 3; space before - is required!)
    echo "${str: -5:3}"                # fgh (3 chars, starting 5 from end)
}

# ----- Indirect expansion & namerefs ------------------------------------
demo_indirect() {
    local greeting_en="Hello"
    local greeting_es="Hola"
    local lang="en"

    # ${!varname} — expand variable whose name is the value of varname
    local key="greeting_${lang}"
    echo "${!key}"                     # Hello

    # nameref — alias to another variable (bash 4.3+)
    local target="greeting_es"
    local -n ref="$target"
    echo "$ref"                        # Hola
    ref="Buenos días"                  # modifies greeting_es through the ref
    echo "$greeting_es"               # Buenos días
}

main() {
    demo_substitution
    echo "---"
    demo_stripping
    echo "---"
    demo_case_conversion
    echo "---"
    demo_substring
    echo "---"
    demo_indirect
}

main "$@"
