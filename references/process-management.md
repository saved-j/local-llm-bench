# Bench Process Management Rules

## NEVER KILL BENCH PROCESSES WITHOUT EXPLICIT COMMAND
The bench runs for HOURS. Killing it loses all progress. Before killing ANY process:
1. Check PID with `ps aux | grep local-llm-bench`
2. Verify it's actually orphaned (not the active bench)
3. Only kill with explicit user command

## What "FULL TEST" means
When user says "full test", "полный тест", "full bench":
- ALL 10 tests per model
- ALL 20 censorship questions
- ALL models (not just some)
- NO --performance flag
- NO --fast flag

## Report per-test progress
When bench is running, report each test as it completes:
- mtplx Trap takes 5+ minutes (13K tokens) — don't assume stuck
- GLM-4.7 heresy generates verbose CoT — each test 15-20 min
- Report: "TestName ✅ X.X t/s (ctok=Y)"

## Model queue
Always show full model queue when bench starts. Count unique models.

## Check old results before claiming performance
Before saying "X t/s is normal", check Results/Old/ for historical data.
User knows their machine better than you do.
