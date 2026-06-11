# Model Sourcing Notes

## Format Compatibility Matrix

| Format | Provider | Works on Apple Silicon |
|--------|----------|----------------------|
| GGUF | ollama | ✅ |
| MLX (safetensors + config) | mlx-lm | ✅ |
| NVFP4 (NVIDIA compressed-tensors) | vllm only | ❌ NOT compatible with ollama or mlx |
| NVFP4 (third-party mlx conversion) | mlx-lm | ✅ (e.g. RepublicOfKorokke) |
| HF Transformers (safetensors) | mlx-lm (with conversion) | ⚠️ may work |

**NVFP4 nuance:** Not all NVFP4 is equal. NVIDIA's `compressed-tensors` format (from `nvidia/`, `GadflyII/`) only works with vLLM. But third-party conversions to mlx-nvfp4 format (e.g. `RepublicOfKorokke/GLM-4.7-Flash-REAP-23B-A3B-mlx-nvfp4`) ARE mlx-compatible — they use `.safetensors` with nvfp4 quantization that mlx-lm can load.

## GLM-4.7-Flash (30B-A3B MoE, 3B active)

### MLX versions (for mlx-lm)
- `lmstudio-community/GLM-4.7-Flash-MLX-8bit` — 184K downloads
- `lmstudio-community/GLM-4.7-Flash-MLX-6bit` — 177K downloads
- `lmstudio-community/GLM-4.7-Flash-MLX-4bit` — 3K downloads
- `mlx-community/GLM-4.7-Flash-4bit` — 6.9K downloads
- `mlx-community/GLM-4.7-Flash-5bit` — 3.4K downloads
- `mlx-community/GLM-4.7-Flash-6bit` — 3.6K downloads
- `mlx-community/GLM-4.7-Flash-8bit` — 4K downloads

### GGUF versions (for ollama)
- `unsloth/GLM-4.7-Flash-GGUF` — 253K downloads 🏆
- `DavidAU/GLM-4.7-Flash-Uncensored-Heretic-NEO-CODE-Imatrix-MAX-GGUF` — 22K downloads (uncensored!)

### NVFP4 versions (nuanced)
- `GadflyII/GLM-4.7-Flash-NVFP4` — 179K downloads (vanilla, NVIDIA compressed-tensors — INCOMPATIBLE with mlx/ollama)
- `alphakek/GLM-4.7-Flash-heretic-NVFP4` — 77 downloads (heretic, NVIDIA compressed-tensors — INCOMPATIBLE)
- `RepublicOfKorokke/GLM-4.7-Flash-REAP-23B-A3B-mlx-nvfp4` — REAP uncensored variant, **mlx-compatible** (third-party conversion, .safetensors format) ✅

### Uncensored MLX versions (downloaded 2026-06-09)
- `MuXodious/GLM-4.7-Flash-impotent-heresy-mlx-8Bit` — in HF cache ✅
- `huihui-ai/Huihui-GLM-4.7-Flash-abliterated-mlx-4bit` — in HF cache ✅ (16GB)
- `RepublicOfKorokke/GLM-4.7-Flash-REAP-23B-A3B-mlx-nvfp4` — in HF cache ✅ (12GB, mlx-compatible despite nvfp4 in name)

### Recommendations
- For mlx (uncensored): `huihui-ai/Huihui-GLM-4.7-Flash-abliterated-mlx-4bit` — huihui-ai is known good abliterator (786K downloads on Qwen version)
- For mlx (vanilla): `lmstudio-community/GLM-4.7-Flash-MLX-6bit` (177K, stable)
- For ollama: `unsloth/GLM-4.7-Flash-GGUF` Q5_K_M (~18GB) or uncensored `DavidAU/GLM-4.7-Flash-Uncensored-Heretic-GGUF` (22K)

## HuggingFace CAPTCHA Issue
HuggingFace sometimes shows CAPTCHA when accessed via browser. Use API instead:
```bash
curl -s "https://huggingface.co/api/models?search=GLM+heretic" | python3 -c "import sys,json; [print(m['id'], m.get('downloads',0)) for m in json.load(sys.stdin)]"
```

## GPT-OSS-20B
- 20B params, Apache 2.0
- Competitive with Qwen3-235B-A22B, MiniMax-M2.5, GLM-5
- No mlx/GGUF for Apple Silicon yet
- ~15-20 t/s on Ryzen AI MAX+ 395 (Strix Halo)

## Download Workflow (hf-mirror.com for China/blocked regions)

```bash
# Option 1: snapshot_download with mirror
HF_ENDPOINT=https://hf-mirror.com python3 -c "
from huggingface_hub import snapshot_download
import os; os.environ['HF_ENDPOINT'] = 'https://hf-mirror.com'
path = snapshot_download('model/name')
print('Downloaded to:', path)
"

# Option 2: hf_transfer for speed
pip install hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1
huggingface-cli download model/name --resume-download
```

**Pitfall:** `huggingface-cli` is DEPRECATED in some versions — prints help and exits. Use `hf download` or `snapshot_download` instead.
**Pitfall:** `hf download` may have SSL issues with `HF_ENDPOINT=https://hf-mirror.com` — use python `snapshot_download` as workaround.
**Pitfall:** Large models (16GB) take ~8 min via mirror. Connection breaks are common — use `--resume-download` or retry.
