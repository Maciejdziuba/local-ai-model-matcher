# Local AI Model Matcher (skill)

A portable agent **skill** that **reads your computer's actual specs** (safely,
read-only) and recommends the **top 3 local AI models** to run:

- 🔥 **Most powerful** you can run
- 💻 **Best for coding**
- ⚡ **Best small + fast**

…each with download links (Hugging Face / LM Studio / Ollama). You don't type your
specs — the skill detects them. Built from David Ondrej's interview with **0xSero**.

## How it works

1. You run it from your project root with a shell-capable agent (e.g. Claude Code).
2. It runs **read-only** commands to detect your GPU, VRAM, system RAM, and OS.
3. It computes your usable VRAM and recommends 3 models with links + a stretch goal.

It never writes files, never uses `sudo`, never installs anything, and makes no
network calls during detection. See the SAFETY RULES section of `SKILL.md`.

## Use it

**Claude Code / agents with skills**

```bash
git clone https://github.com/Maciejdziuba/local-ai-model-matcher
```

Drop `SKILL.md` where your agent loads skills (e.g. `~/.claude/skills/`), open your
agent in any folder, and ask:

> What local AI models can my computer run?

The agent will run the detection (or `scripts/detect-specs.sh` /
`scripts/detect-specs.ps1`) and return your top 3.

**Check the detection yourself first (optional)**

```bash
# macOS / Linux
bash scripts/detect-specs.sh

# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File scripts/detect-specs.ps1
```

## Companion skill

Shopping for hardware instead? Use
**[local-ai-rig-planner](https://github.com/Maciejdziuba/local-ai-rig-planner)** —
give it a budget and it builds your rig plan.

## Disclaimer

Model VRAM/speed figures are planning estimates from the 0xSero podcast + community
quantization norms. Real numbers vary by quant, context, and runtime. Verify before
relying on a model. Not financial advice.

## License

MIT
