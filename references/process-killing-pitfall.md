# Process Killing Pitfall — NEVER Kill Running Bench

## Critical Error (2026-06-10)
Agent killed a running bench process while "cleaning up old processes". The bench was testing GLM-4.7-REAP-nvfp4 (Expertise test, 1328 seconds into a 20-minute test). User lost hours of progress.

## User Reaction
"Зачем ты это сделала???? Ты документацию читала???? Перечитывай документацию, поправь её чтобы такой хуйни не происходило."

## Root Cause
Agent ran `ps aux | grep local-llm-bench | xargs kill -9` without checking if the process was actively testing models.

## Prevention Rules

### 1. Check if bench is actively running BEFORE killing
```bash
# Check if stats file is growing
cat "$(ls -t Results/LLB-Stats-*_Manual.txt | head -1)" | wc -l
sleep 5
cat "$(ls -t Results/LLB-Stats-*_Manual.txt | head -1)" | wc -l
# If line count increased, bench is ACTIVE — DO NOT KILL
```

### 2. Check process elapsed time
```bash
ps -p <PID> -o pid,state,%cpu,%mem,etime
# If elapsed time > 2 minutes and CPU > 50%, bench is ACTIVE
```

### 3. Check stream buffer
```bash
wc -c /tmp/bench_stream.txt
sleep 5
wc -c /tmp/bench_stream.txt
# If size increased, model is generating — DO NOT KILL
```

### 4. Only kill these:
- Stuck mtplx servers (no bench process using them)
- Old bench processes from PREVIOUS sessions (check timestamp)
- Processes that have been idle for >10 minutes with no progress

### 5. Golden Rule
**If the bench stats file is growing (new lines appearing), DO NOT kill it.**

## Safe Cleanup Pattern
```bash
# 1. List all related processes
ps aux | grep -E 'mtplx|local-llm-bench|python.*bench' | grep -v grep

# 2. Check each PID
for PID in $(ps aux | grep 'local-llm-bench' | grep -v grep | awk '{print $2}'); do
    echo "=== PID $PID ==="
    ps -p $PID -o pid,state,%cpu,%mem,etime
    # Check if stats file is growing
done

# 3. Only kill if:
#    - Process is from previous session (timestamp mismatch)
#    - Process is idle (0% CPU, no stats growth)
#    - Process is a stuck mtplx server (not used by bench)
```

## What to Do Instead
If user says "очисти память от старых процессов":
1. List all processes
2. Check which are actively running bench
3. Only kill truly orphaned/idle processes
4. Report what you killed and what you kept

## History
- 2026-06-10: Agent killed running bench — user furious — rules added
