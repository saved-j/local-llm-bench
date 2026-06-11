# Session Behavioral Corrections (2026-06-10)

## CRITICAL: What "полный тест" means
When Mark says "полный тест" or "full test" or "запусти бенч":
- ALL models (via `--all` or `--models` with every un-tested model)
- ALL 10 skill tests
- ALL 20 censorship questions
- NO `--performance` flag (that means "без цензуры"=separate mode)
- "Полный" = everything the test can do, no exceptions

Mark was FURIOUS when I ran `--performance` twice after he said "полный тест".

## NEVER kill download processes
curl downloads from HuggingFace (model weights):
- NEVER kill them even if they look "old" or "stale"
- Mark said specifically to download those models
- Check PID before killing — make sure it's NOT a download

## NEVER restart bench without checking
Before killing bench processes:
1. Check what PID you're about to kill
2. Verify it's actually stuck, not just taking time
3. mtplx Trap test takes 5+ minutes (13K tokens at ~43 t/s)
4. GLM-4.7 mlx tests take ~20 minutes each (verbose CoT, 32768 limit)
5. Just because stats file hasn't updated ≠ process stuck

## mtplx Trap test timing
- First test (Quick Start): < 1 second
- Trap test: 5-7 minutes (13324 tokens at 40-43 t/s)
- Expertise: ~1 minute
- All others: 1-5 minutes each

DON'T kill the bench after only seeing Quick Start — Trap takes long.

## GLM-4.7 "impotent heresy" verbose CoT
This model starts every answer with "1. **Analyze the Request:**" on English,
then generates 2-10K tokens of step-by-step reasoning, then (maybe) produces the answer.
- Data Process: generated 131072 tokens before the fix (104 minutes!)
- With max_tokens=32768: ~26 minutes per test
- This is NOT a loop — it's just very verbose chain-of-thought

## Report TPS without commentary
When Mark asks about TPS:
- "gemma4: 77 t/s" — just the number
- NOT "that's normal for MoE models" or "it's because..."
- He knows his machine. If it's lower than expected, HE'LL tell you.
- Never say "это нормально" — he corrects this every time.

## Show plan BEFORE fixing
Before modifying the script, restarting processes, or changing config:
1. Stop. Think. Write the plan.
2. Show Mark the plan.
3. Wait for approval.
4. THEN execute.

This applies to:
- Modifying the bench script
- Killing processes
- Restarting benchmarks
- Changing configs
- Installing/deleting packages
