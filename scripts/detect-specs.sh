#!/usr/bin/env bash
# detect-specs.sh — READ-ONLY hardware detection for macOS and Linux.
# Prints a human-readable summary. Touches no files, makes no network calls,
# never uses sudo. Safe to run anywhere.
set -u

echo "=== Local AI Model Matcher — system specs (read-only) ==="

os="$(uname -s 2>/dev/null || echo unknown)"
echo "OS: $os"

if [ "$os" = "Darwin" ]; then
  # macOS (Apple Silicon shares unified memory between CPU and GPU)
  cpu="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'unknown')"
  mem_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  mem_gb=$(( mem_bytes / 1024 / 1024 / 1024 ))
  echo "CPU/Chip: $cpu"
  echo "Total RAM: ${mem_gb} GB (Apple Silicon: ~75% usable as VRAM)"
  echo "--- GPU / display ---"
  system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset Model|VRAM|Metal|Total Number of Cores" || echo "  (could not read display info)"

elif [ "$os" = "Linux" ]; then
  echo "--- CPU ---"
  lscpu 2>/dev/null | grep -E "Model name|^CPU\(s\)" || echo "  (lscpu not available)"
  echo "--- System RAM ---"
  free -h 2>/dev/null | grep -E "Mem" || echo "  (free not available)"
  echo "--- NVIDIA GPU(s) ---"
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null
  else
    echo "  no nvidia-smi (no NVIDIA GPU detected)"
    echo "--- Other GPUs ---"
    lspci 2>/dev/null | grep -Ei "vga|3d|display" || echo "  (lspci not available)"
  fi

else
  echo "Unsupported OS for this script. On Windows use scripts/detect-specs.ps1"
fi

echo "=== done — no files were changed ==="
