#!/usr/bin/env bash
# ============================================================
# Jobs, Subshells & Process Management
# ============================================================

# ----- Subshells vs current shell ---------------------------------------
demo_subshell_isolation() {
    local x="original"

    (
        x="changed in subshell"
        echo "Inside subshell: $x"     # changed in subshell
    )

    echo "In parent: $x"               # original — subshell can't affect parent

    # cd in a subshell doesn't affect parent
    ( cd /tmp; echo "In subshell: $PWD" )
    echo "In parent: $PWD"
}

# ----- Background jobs --------------------------------------------------
demo_background_jobs() {
    # & sends a command to the background; $! captures its PID
    sleep 0.1 &
    local pid1=$!
    sleep 0.1 &
    local pid2=$!

    echo "Started PIDs: $pid1 $pid2"

    # wait for specific PID; $? gets its exit code
    wait "$pid1"
    echo "pid1 exited with $?"

    # wait with no args: waits for all background jobs
    wait
    echo "All background jobs done"
}

# ----- Job control -------------------------------------------------------
demo_job_control() {
    # Job control is for interactive shells; in scripts, use PIDs directly
    # fg %1  — bring job 1 to foreground
    # bg %1  — continue stopped job in background
    # jobs   — list background jobs
    # disown %1 — remove job from job table (keeps running after shell exits)

    sleep 0.1 &
    local bg_pid=$!
    echo "Background job PID: $bg_pid"
    jobs    # shows [1]+ Running   sleep 0.1
    wait "$bg_pid"
}

# ----- Parallel execution patterns --------------------------------------
demo_parallel() {
    local -a pids=()
    local -a results=()
    local tmpdir
    tmpdir=$(mktemp -d)

    # Launch multiple tasks in parallel
    for i in {1..4}; do
        (
            # Each subshell writes its result to a temp file
            sleep 0.05
            echo "result_$i" > "$tmpdir/out_$i"
        ) &
        pids+=($!)
    done

    # Wait for all and collect results
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    for i in {1..4}; do
        results+=("$(<"$tmpdir/out_$i")")
    done

    echo "Results: ${results[*]}"
    rm -rf "$tmpdir"
}

# ----- Process substitution vs pipes ------------------------------------
demo_proc_vs_pipe() {
    # Pipe: runs in subshell — variable changes don't propagate to parent
    local count=0
    echo -e "a\nb\nc" | while IFS= read -r line; do
        (( count++ ))   # modifies subshell's count, not parent's
    done
    echo "After pipe while: count=$count"   # 0 — not modified!

    # Fix: use process substitution — while loop runs in current shell
    count=0
    while IFS= read -r line; do
        (( count++ ))
    done < <(printf "a\nb\nc\n")
    echo "After process sub while: count=$count"   # 3 — correct!
}

# ----- wait with timeout (bash 5.1+) ------------------------------------
demo_wait_timeout() {
    sleep 10 &
    local long_pid=$!

    # wait -t 1 — timeout after 1 second; returns 142 if timed out
    if ! wait -t 0.5 "$long_pid" 2>/dev/null; then
        echo "Timed out; killing $long_pid"
        kill "$long_pid" 2>/dev/null
        wait "$long_pid" 2>/dev/null    # reap the zombie
    fi
}

main() {
    demo_subshell_isolation
    echo "---"
    demo_background_jobs
    echo "---"
    demo_job_control
    echo "---"
    demo_parallel
    echo "---"
    demo_proc_vs_pipe
    echo "---"
    demo_wait_timeout
}

main "$@"
