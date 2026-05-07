# Bash Learning Project

## Instructions

- Create subdirectories by topic
- Create `.sh` files for learning individual concepts
- Do a little bit of the basics, but **mostly focus on advanced stuff**
- Add a lot of inline comments explaining specific behaviors and edge cases
- Files should be runnable examples with a `main` function called at the bottom where possible
- Add topic-specific `.md` files for complex tooling (awk, sed, dotfiles)

## Project Structure

```
bash/
├── scripting/         # variables, arguments, quoting, parameter expansion
├── functions/         # defining, scoping, recursion, return values
├── control_flow/      # conditionals, loops, case statements
├── arrays/            # indexed arrays, associative arrays, operations
├── strings/           # manipulation, regex, pattern matching
├── file_ops/          # find, permissions, redirection, process substitution
├── process/           # jobs, subshells, signals, traps
├── tools/             # awk, sed, xargs — with topic-specific .md files
└── dotfiles/          # example .bashrc / .bash_profile with explanations
```

## Focus Areas

- **Parameter expansion** — `${var:-default}`, `${var##prefix}`, `${var//old/new}`, etc.
- **Arrays & associative arrays** — declare, slicing, iterating
- **Process substitution** — `<(cmd)` vs pipes, subshells vs current shell
- **Traps & signals** — cleanup handlers, EXIT, ERR, INT
- **Here-docs & here-strings** — `<<EOF`, `<<<`, indentation with `<<-`
- **Regex** — `[[ =~ ]]`, POSIX classes, capture groups via `BASH_REMATCH`
- **Coprocesses** — `coproc`, two-way communication with background processes
- **Job control** — fg, bg, disown, wait, process groups
