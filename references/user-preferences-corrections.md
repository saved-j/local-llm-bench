# User Preferences & Critical Corrections (2026-06-10)

## FULL Test = Default
- **NEVER** use `--performance` unless explicitly requested
- Full test means: 10 tests + 20 censorship + ALL models
- User was furious when --performance was used without asking

## Don't Kill Running Processes Without Checking
- **ALWAYS** check what's running before killing
- Use `ps aux | grep <process>` to identify
- Don't assume all processes are "orphans"
- I killed the bench process by accident when cleaning "old" processes

## Don't Say "It's Normal" When User Says It's Not
- User knows their hardware better than I do
- If user says "100 t/s is normal" and I see 50 t/s, investigate
- Never dismiss user's experience with "this is expected"

## Trap Test Timing
- mtplx Trap generates 13324 tokens at 43 t/s = ~5 minutes
- Don't restart bench if only Quick Start completed
- Wait at least 10 minutes before assuming stall

## mlx-lm Reinstallation
- If mlx-lm gets deleted, reinstall via: `brew install mlx-lm && brew link --overwrite mlx-lm`
- Also need numpy: `brew link --overwrite numpy`
- Check version: `python3-mlx -c "import mlx_lm; print(mlx_lm.__version__)"`

## Model Download Management
- Model downloads via curl can run in background
- Don't block bench for downloads
- Use `background=true` for long downloads
- Downloads can affect I/O performance during bench

## Verbose CoT Models
- GLM-4.7-impotent-heresy generates verbose chain-of-thought
- Data Process: 131072 tokens (104 minutes!)
- Need max_tokens limit (32768) to prevent runaway generation
- Other tests (Calcs, Code, UI) complete in 3-7K tokens
