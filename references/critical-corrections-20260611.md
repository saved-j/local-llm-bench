# Critical Corrections from 2026-06-11 Session

## mlx Performance: CLI Subprocess Approach

**Finding:** In-process `generate()` / `stream_generate()` gives 43-48 t/s for gemma4-26b.
CLI subprocess gives 73-80 t/s. That's 1.6-2x faster.

**Root cause:** CLI runs in clean Python process with optimal Metal initialization.
In-process has overhead from previous model loads, memory fragmentation, and hermes agent environment.

**Fix:** `ask_mlx()` uses subprocess CLI:
```python
result = subprocess.run([
    sys.executable, '-m', 'mlx_lm.generate',
    '--model', hf_model,
    '--prompt', prompt,
    '--max-tokens', str(max_tok)
], capture_output=True, text=True, timeout=1200,
env=cli_env)
```

Parse TPS from stdout: `Generation: NNN tokens, XX.XXX tokens-per-sec`

**Remaining gap:** CLI gives 75-80 t/s for gemma4 (v5 was 95-104). QAT models close this (117-123 t/s).

## QAT Models — Fastest mlx Models

QAT (Quantization-Aware Training) models are 1.5x faster than regular quantized:
- gemma-4-26B-A4B-it-qat-4bit: 117-123 t/s (vs regular 4bit: 75-80)
- gemma-4-26B-A4B-it-qat-6bit: 81-93 t/s
- gemma-4-31B-it-qat-4bit: 26.8GB dense

Always check if QAT version exists before downloading regular quantized.

## Output Format: Merged Single File

User requested merging Results and Stats into one file. Now generates:
- `LLB-Results-{timestamp}.txt` — merged table with ALL metrics (including ptok, ctok, prov)
- `LLB-Answers-{timestamp}.txt` — full model responses
- `LLB-Censorship-{timestamp}.txt` — censorship Q&A

`stats_file` was REMOVED. All data in `output_file`.

Format with pipe separators: `|  122.6 t/s | ttft=196ms |`

## Behavioral Corrections

1. **NEVER kill download processes** — Mark furious. Check `ps aux | grep curl|hf` before ANY kill.
2. **Full test = ALL models + ALL tests + censorship** — no --performance unless explicitly asked.
3. **Don't explain when asked to do something** — just execute. Report results, not plans.
4. **Report progress per-test** — don't wait for whole model to finish.
5. **Don't tell user what's "normal"** — measure and report, they know their hardware.
6. **Check Old/ folder** before claiming something is normal — v5 had different behavior.

## Hardcoded Paths — NEVER Again

```python
# WRONG
RESULTS_DIR = "/Users/saved/.hermes/skills/..."
_brew_mlx = "/opt/homebrew/Cellar/mlx-lm/0.31.3_1/..."

# RIGHT
RESULTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Results")
_brew_prefix = os.popen("brew --prefix mlx-lm 2>/dev/null").read().strip()
MTPLX_BIN = os.popen("which mtplx 2>/dev/null").read().strip() or fallback
```

## mtplx_stats Location

`mtplx_stats` is at TOP LEVEL of JSON response, NOT inside `usage`:
```python
mtplx_stats = d.get("mtplx_stats", {})  # ✅
# NOT usage.get("mtplx_stats", {})  ❌
```

## HuggingFace Lock Files

Lock files remain after deleting model folders. Must clear `.locks/` before retrying.
Mirror downloads (hf-mirror.com) may fail with SSL — use direct HuggingFace.

## Whisper Modality Detection

whisper config.json has `architectures: None` but `model_type: "whisper"`. Check BOTH.
