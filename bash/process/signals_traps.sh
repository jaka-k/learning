#!/usr/bin/env bash
# ============================================================
# Signals, Traps & Cleanup
# ============================================================

# ----- trap — register handlers for signals & events -------------------
# Syntax: trap 'command' SIGNAL [SIGNAL...]
# Special pseudo-signals: EXIT, ERR, DEBUG, RETURN

demo_cleanup_trap() {
    local tmpfile
    tmpfile=$(mktemp)
    echo "Working with $tmpfile"

    # EXIT fires when the script exits for any reason — ideal for cleanup
    # Using a function is cleaner than an inline command
    cleanup() {
        echo "Cleaning up $tmpfile"
        rm -f "$tmpfile"
    }
    trap cleanup EXIT

    echo "data" > "$tmpfile"
    # Even if we return early or hit an error, cleanup runs
}

demo_interrupt_trap() {
    # INT is sent by Ctrl+C; TERM is sent by kill
    local caught=false

    trap 'caught=true; echo "Caught SIGINT"' INT
    trap 'echo "Caught SIGTERM"' TERM

    echo "Running (send Ctrl+C to test)..."
    # In real scripts you'd sleep or do work here
    # sleep 30

    trap - INT TERM   # reset traps to default behavior
}

# ----- ERR trap — run on any non-zero exit code --------------------------
# Useful with 'set -e' to log which command failed
demo_err_trap() {
    err_handler() {
        local exit_code=$?
        local line_no=$1
        echo "ERROR: command failed with exit $exit_code at line $line_no" >&2
    }

    trap 'err_handler $LINENO' ERR

    # set -e makes the script exit on first error
    # set -u treats unset variables as errors
    # set -o pipefail — pipe fails if any command in it fails
    set -euo pipefail

    # Demo: this would trigger the ERR trap
    # false

    trap - ERR
    set +euo pipefail
}

# ----- Propagating traps through subshells ------------------------------
demo_trap_scope() {
    trap 'echo "parent trap"' USR1

    # Subshells inherit traps as ignored signals
    # Functions run in the same shell and inherit parent traps

    inner() {
        # Override for this function's context
        trap 'echo "inner USR1"' USR1
        kill -USR1 $$                   # send to current PID
        trap - USR1                     # restore
    }
    inner

    # Subshell: inherits trap state at fork time, but can't modify parent
    ( trap 'echo "subshell USR1"' USR1; kill -USR1 $$ )
}

# ----- Common signals reference ------------------------------------------
# SIGHUP  (1)  — terminal closed or daemon reload
# SIGINT  (2)  — Ctrl+C
# SIGQUIT (3)  — Ctrl+\
# SIGKILL (9)  — force kill (cannot be caught or ignored)
# SIGTERM (15) — graceful termination (default kill signal)
# SIGUSR1 (10) — user-defined
# SIGUSR2 (12) — user-defined
# SIGCHLD (17) — child process state change

demo_send_signal() {
    # Send a signal to a PID: kill -SIGNAL PID
    # kill -0 PID — check if process exists (no signal sent)
    local target=$$   # ourselves
    if kill -0 "$target" 2>/dev/null; then
        echo "PID $target is alive"
    fi
}

main() {
    demo_cleanup_trap
    echo "---"
    demo_send_signal
    echo "---"
    demo_err_trap
    echo "---"
    # demo_trap_scope  # sends real signals — skip in automated runs
    echo "Skipping signal-sending demo in non-interactive mode"
}

main "$@"
