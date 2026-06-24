---
name: local-ai-model-matcher
description: Safely auto-detect the current machine's hardware (GPU, VRAM, system RAM, OS) with read-only commands, then recommend the top 3 local AI models to run — most powerful that fits, best for coding, and best small-and-fast — each with download links. Use when someone asks "what AI models can my computer run" or "what's the best local model for my rig".
---

# Local AI Model Matcher

You read the user's **actual machine specs** and recommend exactly **3 local AI
models** with download links. You do NOT ask the user to type their specs — you
detect them yourself using safe, read-only commands.

Run this from the user's project root (or anywhere — it doesn't touch their files).

## SAFETY RULES — read first, do not skip

- **Read-only only.** Only run the exact detection commands listed below.
- **Never** write, move, or delete files. **Never** use `sudo`. **Never** install
  anything. **Never** make network calls during detection.
- Before running detection, tell the user in one line what you're about to read
  ("I'll read your GPU, VRAM, RAM, and OS — read-only, nothing is changed").
- If a command isn't found, skip it gracefully and move on. Never guess specs you
  couldn't read — say what you couldn't detect.

## Step 1 — Detect the OS

Run one of:
- `uname -s` (macOS/Linux) — `Darwin` = macOS, `Linux` = Linux
- On Windows the agent is typically in PowerShell; check `$PSVersionTable` or `ver`.

A helper script is bundled — prefer it if present:
- macOS/Linux: `bash scripts/detect-specs.sh`
- Windows: `powershell -ExecutionPolicy Bypass -File scripts/detect-specs.ps1`

If the script isn't available, run the per-OS commands below directly.

## Step 2 — Detect hardware (read-only)

### macOS (Apple Silicon or Intel)
```bash
sysctl -n hw.memsize                    # total system RAM (bytes)
sysctl -n machdep.cpu.brand_string      # CPU
system_profiler SPDisplaysDataType      # GPU / chip (unified memory on Apple Silicon)
```
On Apple Silicon, **unified memory ≈ usable VRAM** (the GPU shares system RAM).
Treat ~75% of total RAM as usable for model weights.

### Linux
```bash
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader   # NVIDIA GPUs + VRAM
free -h                                                          # system RAM
lscpu | grep -E "Model name|^CPU\(s\)"                           # CPU
lspci | grep -Ei "vga|3d|display"                               # fallback: any GPU
```
If `nvidia-smi` is missing there is likely no NVIDIA GPU — fall back to CPU/iGPU
models and small quantized models in system RAM.

### Windows (PowerShell)
```powershell
Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM
Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory
Get-CimInstance Win32_Processor | Select-Object Name
```
`AdapterRAM` can misreport on some drivers — if it looks wrong, ask the user to
confirm their GPU's VRAM rather than guessing.

## Step 3 — Compute usable VRAM

- **Dedicated NVIDIA/AMD GPU:** usable VRAM = sum of GPU memory (minus ~1–2GB
  overhead per card).
- **Apple Silicon:** usable ≈ 75% of unified memory.
- **No dedicated GPU:** you can still run small models in system RAM on CPU, just
  slowly — recommend ≤8B 4-bit models.

VRAM estimate for a model:
```
VRAM_GB ≈ params_billion × bytes_per_param × 1.2   (+ a few GB for context)
  4-bit ≈ 0.5 bytes/param   →  params_B × 0.6
  8-bit ≈ 1.0 bytes/param   →  params_B × 1.2
```
For MoE models, use **total** params for the memory check (all weights must load),
but expect speed closer to the **active** param count.

## Step 4 — Recommend exactly 3 models

From the model table below, pick:

1. **🔥 Most powerful you can run** — the highest-quality model that fits usable
   VRAM at a sane quant (prefer 4-bit if 8-bit doesn't fit). State the quant.
2. **💻 Best for coding** — the strongest coding/agentic model that fits (Qwen 3.6,
   GLM, Step — these excel at backend/DevOps/agent work).
3. **⚡ Best small + fast** — a model that leaves plenty of headroom and runs at high
   tok/s for everyday/tool-calling use.

If the same model is the best answer for two slots, pick the next-best for the
second so the user gets variety.

## Model table

| Model | Total / active params | Type | Strengths | ~VRAM @ 4-bit | ~VRAM @ 8-bit | Links |
|---|---|---|---|---|---|---|
| Gemma 3 4B | 4B | dense | small, fast, world knowledge | ~3 GB | ~5 GB | HF · Ollama |
| Qwen 3.6 8B | 8B | dense | fast, strong tool-calling | ~5 GB | ~9 GB | HF · LM Studio · Ollama |
| Gemma 3 12B | 12B | dense | general, knowledge | ~8 GB | ~14 GB | HF · Ollama |
| Qwen 3.6 27B | 27B | dense-ish | **coding/agentic**, reasons like much bigger models | ~16 GB | ~30 GB | HF · LM Studio · Ollama |
| Gemma 3 27B | 27B | dense | world knowledge (weaker at agentic) | ~16 GB | ~30 GB | HF · Ollama |
| Qwen 3.6 35B | 35B | dense-ish | **coding/agentic**, more headroom | ~22 GB | ~40 GB | HF · LM Studio · Ollama |
| Hermes 70B | 70B | dense | uncensored, general | ~40 GB | ~75 GB | HF · LM Studio |
| Step 3.7 Flash | MoE | MoE | big step up, coding | ~fits 256GB tier | — | HF |
| DeepSeek V4 Flash | MoE | MoE | fast agentic, concurrency | ~$20k tier | — | HF |
| Minimax M2 | 229B / 10B active | MoE | strong, efficient decode | ~140 GB | — | HF |
| GLM 5.2 | 744B / 40B active | MoE | **frontier coding/DevOps/agents** | ~450 GB | — | HF |
| Kimi K2.5 | 1T / 30B active | MoE | frontier breadth | ~600 GB | — | HF |

**Canonical link bases** (construct the model's page; confirm the exact slug):
- Hugging Face: `https://huggingface.co/models?search=<model>`
- LM Studio: `https://lmstudio.ai/models`
- Ollama: `https://ollama.com/search?q=<model>`

Always give the user clickable links for each recommended model. If unsure of an
exact repo slug, link the search URL rather than inventing a slug.

## Output format

```
I read your machine (read-only):
- OS: <os>   CPU: <cpu>
- GPU: <gpu(s)>   Usable VRAM: <N> GB   System RAM: <N> GB

## Top 3 models for your rig

🔥 **Most powerful you can run:** <model> @ <quant>
   ~<VRAM> GB · ~<tok/s> · <one-line why>
   <HF link> · <LM Studio link> · <Ollama link>

💻 **Best for coding:** <model> @ <quant>
   ~<VRAM> GB · <why it's great for agentic coding>
   <links>

⚡ **Best small + fast:** <model> @ <quant>
   ~<VRAM> GB · leaves headroom, ~<tok/s>
   <links>

**Want more than this?** To run the next tier up (<model>) you'd need <hardware>.
Plan it with the Rig Planner skill: https://github.com/Maciejdziuba/local-ai-rig-planner
```

Numbers are planning estimates from the 0xSero podcast + community quantization
norms — real VRAM/speed varies by quant, context length, and runtime. Always tell
the user to verify before buying or relying on a model.
