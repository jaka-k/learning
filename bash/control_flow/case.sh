#!/usr/bin/env bash
# ============================================================
# case Statement & Pattern Matching
# ============================================================

# ----- Basic case -------------------------------------------------------
demo_basic_case() {
    local day="Monday"

    case "$day" in
        Monday|Tuesday|Wednesday|Thursday|Friday)
            echo "Weekday"
            ;;
        Saturday|Sunday)
            echo "Weekend"
            ;;
        *)
            echo "Unknown day"
            ;;
    esac
}

# ----- case with glob patterns ------------------------------------------
demo_glob_patterns() {
    local filename="report_2024.csv"

    case "$filename" in
        *.csv)   echo "CSV file" ;;
        *.json)  echo "JSON file" ;;
        *.sh)    echo "Shell script" ;;
        report*) echo "Matches report prefix (never reached — *.csv matched first)" ;;
        *)       echo "Unknown file type" ;;
    esac

    # Note: patterns are matched in order — first match wins
}

# ----- Fall-through with ;& and ;;&  (bash 4+) --------------------------
demo_fallthrough() {
    local val=2

    case $val in
        1)
            echo "one"
            ;;&   # ;;&  — test remaining patterns (continue matching)
        2)
            echo "two"
            ;&    # ;&   — fall through to next block unconditionally (no test)
        3)
            echo "three (fell through from 2)"
            ;;    # ;; — stop
    esac
    # Output: two, three (fell through from 2)
}

# ----- case for option dispatch ------------------------------------------
demo_dispatch() {
    local cmd="${1:-help}"

    case "$cmd" in
        start)
            echo "Starting service..."
            ;;
        stop|halt)
            echo "Stopping service..."
            ;;
        restart)
            echo "Restarting service..."
            ;;
        status|info)
            echo "Service is running"
            ;;
        -h|--help|help)
            echo "Usage: script.sh {start|stop|restart|status}"
            ;;
        *)
            echo "Unknown command: $cmd" >&2
            return 1
            ;;
    esac
}

main() {
    demo_basic_case
    echo "---"
    demo_glob_patterns
    echo "---"
    demo_fallthrough
    echo "---"
    demo_dispatch start
    demo_dispatch --help
    demo_dispatch unknown
}

main "$@"
