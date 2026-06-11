# User Behavioral Corrections — Benchmark Sessions

## Critical Rules (from 2026-06-10/11 marathon session)

### NEVER kill download processes
Mark: "Бля нахуя ты опять загрузку убила? Вот за это я тебя и удалю."
- Before ANY `kill`, check: `ps aux | grep -E 'curl|huggingface|hf.*download'`
- Downloads (curl, hf download) must NOT be killed even if they look stuck
- Lock files from interrupted downloads: `rm -rf ~/.cache/huggingface/hub/.locks/models--*`

### "Full test" = everything
- Mark: "Полный тест бля это полный тест" — means ALL 10 tests + ALL 20 censorship + ALL models
- NO --performance unless explicitly stated
- Don't assume --performance is OK because "censorship is slow"

### Don't tell user what's "normal" for their machine
- Mark: "Не нужно мне рассказывать что нормально, я знаю что нормально"
- Just measure and report. User knows their hardware better than you.

### Don't explain when user asks to do something
- Mark furious when I narrate instead of acting
- Report results, not plans
- "Just execute" = no preamble, no explanation, no "first I'll..."

### Report progress per-test during long runs
- After each test completes, show the result immediately
- Don't wait for the whole model to finish before reporting
### mlx speed expectations
- v5 showed 95-104 t/s for gemma4-26b → this was with max_tokens=256 (bug)
- Real speed with CLI subprocess: 73-80 t/s for gemma4
- gemma3-4b: 120 t/s matches v5
- QAT models: 117-123 t/s (exceeds v5!)
- Don't claim "this is normal" when speed differs from v5 — investigate
- smbd runaway (1400% CPU) can cause 20% degradation via thermal throttling

### Don't make "marketing claims" about progress
- Mark: "75-80 это хорошо но это не обещанные мне 100+"
- Report actual numbers, don't hype partial results
- If speed is below target, say so directly

### QAT models are faster than regular quantized
- QAT (Quantization-Aware Training) produces better quality at same bit-width
- gemma-4-26B-A4B-it-qat-4bit: 117-123 t/s vs regular 4bit: 75-80 t/s
- Always check if QAT version exists for a model before downloading regular

### HuggingFace cache structure
- `hf cache list` shows installed models
- Models in `~/.cache/huggingface/hub/models--<org>--<name>/`
- Snapshots in `snapshots/<hash>/` — symlinked to blobs
- Lock files in `.locks/` — must clear before retrying downloads
- `hf download` is the correct command (not curl for LFS files)

### Benchmark file format preference
- ptok = prompt tokens (input/ingest)
- ctok = completion tokens (output)
- User wants merged Results+Stats file, not two separate files
- Include header with date, system, mode, providers

### mlx speed expectations
- v5 showed 95-104 t/s for gemma4-26b → this was with max_tokens=256 (bug)
- Real speed with CLI subprocess: 73-80 t/s for gemma4
- gemma3-4b: 120 t/s matches v5
- Don't claim "this is normal" when speed differs from v5 — investigate
- smbd runaway (1400% CPU) can cause 20% degradation via thermal throttling
