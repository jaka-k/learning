#!/usr/bin/env bash
# ============================================================
# awk — Field Processing & Text Transformation
# ============================================================
# awk processes input line by line (records), splitting each into fields ($1, $2, ...)
# Default field separator: whitespace. Default record separator: newline.

DATA=$(cat <<'EOF'
alice   engineering  95000
bob     marketing    72000
carol   engineering  110000
dave    design       85000
eve     marketing    68000
EOF
)

# ----- Basic field extraction -------------------------------------------
demo_fields() {
    # $1=name, $2=dept, $3=salary; $0=entire line; NF=number of fields; NR=record number
    echo "$DATA" | awk '{ print NR, $1, $3 }'

    # Print last field regardless of how many there are
    echo "$DATA" | awk '{ print $NF }'

    # Custom OFS (output field separator)
    echo "$DATA" | awk 'BEGIN { OFS="," } { print $1, $2, $3 }'
}

# ----- Pattern matching --------------------------------------------------
demo_patterns() {
    # Regex pattern — only process matching lines
    echo "$DATA" | awk '/engineering/ { print $1, $3 }'

    # Negation
    echo "$DATA" | awk '!/marketing/ { print $0 }'

    # Numeric comparison
    echo "$DATA" | awk '$3 > 80000 { print $1, "earns", $3 }'

    # Range pattern: from first match to second match (inclusive)
    echo "$DATA" | awk '/bob/,/carol/ { print }'
}

# ----- BEGIN and END blocks ----------------------------------------------
demo_begin_end() {
    # BEGIN runs before any input; END runs after all input
    echo "$DATA" | awk '
        BEGIN {
            total = 0
            count = 0
            print "--- Salary Report ---"
        }
        {
            total += $3
            count++
        }
        END {
            printf "Total: %d\nCount: %d\nAverage: %.0f\n", total, count, total/count
        }
    '
}

# ----- Built-in variables & functions ------------------------------------
demo_builtins() {
    echo "$DATA" | awk '
        {
            name = toupper($1)          # string functions: tolower, toupper, length, substr, index, split, gsub, sub
            dept = $2
            sal  = $3

            # sprintf for formatting
            formatted = sprintf("%-10s %-15s $%d", name, dept, sal)
            print formatted
        }
    '

    # split: split field into array
    echo "one:two:three" | awk '{ n = split($0, arr, ":"); for(i=1;i<=n;i++) print arr[i] }'
}

# ----- Associative arrays ------------------------------------------------
demo_awk_arrays() {
    # Sum salaries by department
    echo "$DATA" | awk '
        {
            dept_total[$2] += $3
            dept_count[$2]++
        }
        END {
            for (dept in dept_total) {
                printf "%s: avg=%.0f\n", dept, dept_total[dept] / dept_count[dept]
            }
        }
    '
}

# ----- Custom field separator (FS) ---------------------------------------
demo_custom_fs() {
    # CSV parsing (naive — doesn't handle quoted fields)
    local csv="name,age,city
alice,30,NYC
bob,25,LA"

    echo "$csv" | awk -F',' 'NR > 1 { print $1, "is", $2, "from", $3 }'

    # Multiple separators with regex
    echo "one::two:::three" | awk -F':+' '{ print $1, $2, $3 }'
}

main() {
    echo "=== Fields ==="
    demo_fields
    echo "=== Patterns ==="
    demo_patterns
    echo "=== BEGIN/END ==="
    demo_begin_end
    echo "=== Builtins ==="
    demo_builtins
    echo "=== Arrays ==="
    demo_awk_arrays
    echo "=== Custom FS ==="
    demo_custom_fs
}

main "$@"
