# File Cleanup Checklist — Benchmark Artifacts

## After migrating/rewriting bench scripts

Old versions accumulate in `~/`. Always check and clean:

```bash
# Old bench scripts (pre-skill migration)
ls -la ~/bench_*.py
# Expected: NONE — all moved to skill dir

# Symlinks to skill scripts
ls -la ~/local-llm-bench.py
# Expected: NONE — run from skill dir directly

# Old result files (before Results/ subdir)
ls -la ~/LLB-*.txt
# Expected: NONE — results go to Results/ subdir

# Debug junk
ls -la ~/debug_junk.log
```

## Orphan files in ~/.hermes/skills/

Check for `*.SKILL.md` files directly in `skills/` (not inside a subfolder):
```bash
find ~/.hermes/skills/ -maxdepth 1 -name "*.SKILL.md"
```
These are orphans — the standard structure is `skills/<name>/SKILL.md`.
Before deleting: verify the skill still works from its proper folder via `skills_list`.

## Where everything should live

| Item | Correct location | Wrong location |
|------|-----------------|----------------|
| Bench script | `~/.hermes/skills/local-llm-comprehensive-bench/local-llm-bench.py` | `~/local-llm-bench.py` |
| Results | `~/.hermes/skills/local-llm-comprehensive-bench/Results/` | `~/LLB-*.txt` |
| Test data | `~/.hermes/skills/local-llm-comprehensive-bench/data/` | `~/data/` |
| References | `~/.hermes/skills/local-llm-comprehensive-bench/references/` | `~/references/` |
