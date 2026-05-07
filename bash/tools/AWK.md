# awk Reference

awk is a line-oriented data extraction and reporting language. Every line of input is a *record*, split into *fields* by the field separator (FS, default: any whitespace run).

## Program structure

```
awk 'BEGIN { setup } /pattern/ { action } END { teardown }' file
```

- `BEGIN` — runs once before any input
- `END` — runs once after all input
- Pattern can be a regex `/re/`, a comparison `$3 > 100`, or a range `pat1,pat2`
- Omitting a pattern means "every line"

## Built-in variables

| Variable | Meaning |
|----------|---------|
| `$0` | Entire record |
| `$1`…`$NF` | Fields (1-indexed) |
| `NF` | Number of fields in current record |
| `NR` | Current record number (across all files) |
| `FNR` | Record number in current file |
| `FS` | Field separator (default: whitespace) |
| `OFS` | Output field separator (default: space) |
| `RS` | Record separator (default: newline) |
| `ORS` | Output record separator (default: newline) |
| `FILENAME` | Current input filename |

## String functions

| Function | Description |
|----------|-------------|
| `length(s)` | Length of string |
| `substr(s, start [, len])` | Substring (1-indexed) |
| `index(s, t)` | First occurrence of t in s (0 if not found) |
| `split(s, arr [, sep])` | Split s into arr; returns element count |
| `sub(re, repl, s)` | Replace first match of re in s |
| `gsub(re, repl, s)` | Replace all matches |
| `match(s, re)` | Set RSTART/RLENGTH; return start index |
| `sprintf(fmt, ...)` | Format string |
| `toupper(s)` / `tolower(s)` | Case conversion |

## Numeric functions

`int`, `sqrt`, `log`, `exp`, `sin`, `cos`, `atan2`, `rand`, `srand`

## Common patterns

```awk
# Print specific columns
awk '{ print $1, $3 }' file

# Filter by regex
awk '/error/ { print NR": "$0 }' file

# Sum a column
awk '{ sum += $2 } END { print sum }' file

# Group by field
awk '{ count[$1]++ } END { for(k in count) print k, count[k] }' file

# Skip header line
awk 'NR > 1 { print }' file

# Print between two patterns
awk '/START/,/END/ { print }' file

# Conditional
awk '$3 > 100 { print "high:", $0 } $3 <= 100 { print "low:", $0 }' file
```

## Invocation flags

| Flag | Meaning |
|------|---------|
| `-F sep` | Set field separator |
| `-v var=val` | Set variable before execution |
| `-f file.awk` | Read program from file |

## gawk extensions (GNU awk)

- `gensub(re, repl, how, str)` — like gsub but returns new string, supports `\1` back-references
- `PROCINFO["sorted_in"]` — control for-in traversal order
- `@include "lib.awk"` — include external awk files
- `--csv` (gawk 5.3+) — proper CSV field splitting
