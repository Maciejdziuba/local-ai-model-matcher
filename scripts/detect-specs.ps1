# detect-specs.ps1 — READ-ONLY hardware detection for Windows (PowerShell).
# Prints a human-readable summary. Touches no files, makes no network calls,
# requires no admin rights. Safe to run anywhere.

Write-Output "=== Local AI Model Matcher - system specs (read-only) ==="
Write-Output "OS: Windows"

try {
  $cpu = (Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1).Name
  Write-Output "CPU: $cpu"
} catch { Write-Output "CPU: (could not read)" }

try {
  $ramBytes = (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory
  $ramGb = [math]::Round($ramBytes / 1GB, 0)
  Write-Output "Total RAM: $ramGb GB"
} catch { Write-Output "Total RAM: (could not read)" }

Write-Output "--- GPU(s) ---"
try {
  Get-CimInstance Win32_VideoController -ErrorAction Stop | ForEach-Object {
    $vramGb = if ($_.AdapterRAM) { [math]::Round($_.AdapterRAM / 1GB, 0) } else { "unknown" }
    Write-Output ("  {0} - {1} GB VRAM (AdapterRAM can misreport; confirm if it looks wrong)" -f $_.Name, $vramGb)
  }
} catch { Write-Output "  (could not read GPU info)" }

# nvidia-smi gives the most reliable VRAM if an NVIDIA GPU is present
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
  Write-Output "--- nvidia-smi (authoritative VRAM) ---"
  nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
}

Write-Output "=== done - no files were changed ==="
