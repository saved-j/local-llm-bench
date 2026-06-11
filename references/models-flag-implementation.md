# --models Flag Implementation (2026-06-10)

## Purpose
Run multiple specific models by comma-separated names/IDs without re-testing already completed models.

## Usage
```bash
# Single model
python3-mlx local-llm-bench.py --model "gemma-4-26B"

# Multiple models
python3-mlx local-llm-bench.py --models "gemma-4-26B,Qwen3.6-35B,Huihui-GLM"

# With other flags
python3-mlx local-llm-bench.py --models "gemma-4-26B,Qwen3.6-35B" --no-chat --suffix=_Full
```

## Implementation
- Added `--models` argument to argparse
- Added `MULTI_MODELS` global variable
- Added filtering logic after `SINGLE_MODEL` filtering
- Each model in comma-separated list is matched against `selected` list
- Partial matching supported (e.g., "gemma-4" matches "gemma-4-26B-A4B-it-ultra-uncensored-heretic-mlx-4Bit")

## Error Handling
- If model not found: prints WARNING and skips
- If no models found: prints ERROR and exits

## Example
```bash
# Test only remaining mlx models (skip already tested mtplx/ollama)
python3-mlx local-llm-bench.py --models "gemma-4-26B,Qwen3.6-35B,Huihui-GLM,Qwen3-Next-80B,Qwen3.6-35B-OptiQ,gemma-3-12b,gemma-3-4b" --no-chat --suffix=_Full
```
