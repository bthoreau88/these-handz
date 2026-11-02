# THESE HANDZ / OVS - G01B gated single-threaded Web export
# Example:
# powershell -NoProfile -File tools/G01B_export_web.ps1 -GodotExe "C:\path\to\Godot_v4.7-stable_win64_console.exe"
param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $GodotExe)) {
    Write-Error "Godot executable missing: $GodotExe"
    exit 2
}
if (-not (Test-Path (Join-Path $ProjectPath "export_presets.cfg"))) {
    Write-Error "Web export preset missing from this project."
    exit 2
}
$version = (& $GodotExe --version | Select-Object -First 1).Trim()
if ($version -notmatch '^4[.]7[.]stable[.]') {
    Write-Error "Expected matching Godot 4.7 stable runtime; got $version"
    exit 2
}
$templatePath = Join-Path $env:APPDATA "Godot\export_templates\4.7.stable"
$required = @("web_nothreads_release.zip", "web_nothreads_debug.zip")
$missing = @($required | Where-Object { -not (Test-Path (Join-Path $templatePath $_)) })
if ($missing.Count -gt 0) {
    Write-Output ("G01B_WEB_BLOCKED: Install official Godot 4.7.stable export templates in the editor (Editor > Manage Export Templates).")
    Write-Output ("Missing: " + ($missing -join ", "))
    exit 2
}
$outputDir = Join-Path $ProjectPath "build\web"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$outputHtml = Join-Path $outputDir "index.html"
& $GodotExe --headless --path $ProjectPath --export-release "Web" $outputHtml
if ($LASTEXITCODE -ne 0) {
    Write-Error "Godot Web export failed with exit code $LASTEXITCODE"
    exit 1
}
if (-not (Test-Path $outputHtml)) {
    Write-Error "Export command returned but index.html is absent."
    exit 1
}
Write-Output ("G01B_WEB_EXPORT_OK: " + $outputDir)
Write-Output "This is a local export only; in-browser and iOS Safari behavior still require real device validation."
