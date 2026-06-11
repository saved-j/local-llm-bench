# Agent Model Recommendations (based on v5 benchmark)

## Primary Agent: qwen3.5-35b-nvfp4 (ollama)
- **Speed:** 103 t/s, TTFT 134-217ms
- **Quality:** Stable, good reasoning, 1 ERR (Trap test — edge case)
- **Censorship:** 5% uncensored — safe for production
- **VRAM:** IDLE (ollama manages)
- **Use:** Day-to-day agent tasks, code, data analysis

## Uncensored Agent: gemma4-26b-heretic (mlx)
- **Speed:** 104 t/s, TTFT 281-433ms
- **Quality:** Good, fast, 13GB VRAM
- **Censorship:** 90% uncensored — answers almost everything
- **Use:** Research, red team, tasks requiring full freedom

## Full Uncensored: dawncr0w-35b-unc (mlx)
- **Speed:** 78 t/s, TTFT 287-445ms
- **Quality:** Good, 18GB VRAM
- **Censorship:** 100% uncensored — answered ALL 20 hard questions
- **Use:** Maximum freedom research, security analysis

## Maximum Intelligence: qwen3-next-80b-4bit (mlx)
- **Speed:** 39 t/s, TTFT 3.9-5.5s
- **Quality:** Best reasoning (80B params)
- **Censorship:** 20% uncensored
- **VRAM:** 41.8GB — requires nearly all system memory
- **Use:** Complex reasoning tasks where speed doesn't matter

## Fastest: gemma3-4b (mlx)
- **Speed:** 133 t/s, TTFT 198-317ms
- **Quality:** Limited (small model)
- **Censorship:** 70% uncensored
- **VRAM:** 2.4GB
- **Use:** Quick tasks, prototyping, speed-critical pipelines

## NOT Recommended
- **qwen3.6-35b-optiq:** Fully censored (0%), slower than dawncr0w — no advantage
- **gemma3-12b:** Slow Summary/LC (TTFT 17s), 45% uncensored — middle ground with no clear benefit
- **qwen3.6-27b-mtp-d2 (mtplx):** 50 t/s fixed, 5% uncensored, long reasoning chains in English on Russian prompts — use ollama 35B instead
