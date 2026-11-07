# OVS THESE HANDZ / G01C - export + quarantine-safety validation
# Output is local only: build/web/*. No public hosting or canon promotion.
param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [switch]$ValidateOnly
)
$ErrorActionPreference = "Stop"
$preset = Join-Path $ProjectPath "export_presets.cfg"
if (-not (Test-Path -LiteralPath $preset)) { throw "Web preset missing" }
$config = [System.IO.File]::ReadAllText($preset)
foreach ($pattern in @("res://assets/source_sheets/*", "res://build/*", "res://tests/*")) {
    if (-not $config.Contains($pattern)) { throw "Safety exclusion missing: $pattern" }
}
if (-not $ValidateOnly) {
    & (Join-Path $PSScriptRoot "G01B_export_web.ps1") -GodotExe $GodotExe -ProjectPath $ProjectPath
    if ($LASTEXITCODE -ne 0) { throw "Web export command failed" }
}
$dir = Join-Path $ProjectPath "build\web"
$files = @("index.html", "index.js", "index.wasm", "index.pck")
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $dir $file))) {
        throw "Missing Web artifact: $file"
    }
}
$packPath = Join-Path $dir "index.pck"
[byte[]]$packBytes = [System.IO.File]::ReadAllBytes($packPath)
$plain = [System.Text.Encoding]::ASCII.GetString($packBytes)
foreach ($marker in @("_HOLD_", "TRADEMARKS", "source_sheets", "res://build/")) {
    if ($plain.Contains($marker)) { throw "QUARANTINE_VIOLATION: $marker embedded in game pack" }
}
if (-not $plain.Contains("res://assets/sprites")) {
    throw "Missing expected playable fighter-sprite assets"
}
$sha = (Get-FileHash -LiteralPath $packPath -Algorithm SHA256).Hash
$gitHead = (& git -C $ProjectPath rev-parse HEAD | Select-Object -First 1)
$receipt = @(
    "THESE_HANDZ_G01C_SAFE_WEB=PASS"
    "GitCommit=$gitHead"
    "GamePackBytes=$($packBytes.Length)"
    "GamePackSHA256=$sha"
    "ExportOutput=$dir"
    "UnfilteredOrHeldAssetsIncluded=FALSE"
    "NOTE=Engine/browser export proof only; actual iPhone Safari is not yet certified."
)
$receiptPath = Join-Path $ProjectPath "build\G01C_WEB_EXPORT_RECEIPT.txt"
$receipt | Set-Content -LiteralPath $receiptPath -Encoding UTF8
$receipt | ForEach-Object { Write-Output $_ }
exit 0
