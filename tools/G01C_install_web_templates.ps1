# G01C: restore ONLY official Godot 4.7-stable single-thread Web templates.
# Source: https://godotengine.org/download/archive/4.7-stable/
# The official download redirects to the Godot release object-storage mirror.
# HTTP byte-ranges avoid downloading the unrelated ~1.28GB template package.
# Never overwrites existing official template files.
param(
    [string]$SourceUrl = "https://godot-releases.nbg1.your-objectstorage.com/4.7-stable/Godot_v4.7-stable_export_templates.tpz"
)
$ErrorActionPreference = "Stop"
Add-Type -TypeDefinition @"
public static class G01CCrc32 {
    public static uint Compute(byte[] data) {
        uint crc = 0xFFFFFFFF;
        foreach (byte b in data) {
            crc ^= b;
            for (int i = 0; i < 8; i++) {
                crc = (crc >> 1) ^ ((crc & 1u) != 0u ? 0xEDB88320u : 0u);
            }
        }
        return ~crc;
    }
}
"@
function Get-ByteRange([long]$First, [long]$Last) {
    if ($First -lt 0 -or $Last -lt $First) { throw "Invalid requested byte range" }
    for ($attempt=1; $attempt -le 3; $attempt++) {
        try {
            $req = [System.Net.HttpWebRequest]::Create($SourceUrl)
            $req.AddRange($First, $Last)
            $req.Timeout = 90000
            $req.ReadWriteTimeout = 90000
            $response = $req.GetResponse()
            if ([int]$response.StatusCode -ne 206) {
                $response.Close()
                throw "Origin ignored HTTP Range"
            }
            $memory = New-Object System.IO.MemoryStream
            $response.GetResponseStream().CopyTo($memory)
            $response.Close()
            [byte[]]$data = $memory.ToArray()
            $memory.Dispose()
            if ($data.Length -ne ($Last - $First + 1)) {
                throw "Incomplete byte range $First-$Last"
            }
            return ,$data
        } catch {
            if ($attempt -eq 3) { throw }
            Start-Sleep -Seconds $attempt
        }
    }
}
$destination = Join-Path $env:APPDATA "Godot\export_templates\4.7.stable"
$required = @("web_nothreads_debug.zip", "web_nothreads_release.zip")
foreach ($name in $required) {
    if (Test-Path -LiteralPath (Join-Path $destination $name)) {
        throw "Existing file; refusing to overwrite: $name"
    }
}
$staging = Join-Path $env:TEMP "THESE_HANDZ_G01C_WEB_TEMPLATE_STAGING"
if (Test-Path -LiteralPath $staging) {
    throw "Staging path already exists; refusing to overwrite: $staging"
}
$head = [System.Net.HttpWebRequest]::Create($SourceUrl)
$head.Method = "HEAD"
$head.Timeout = 30000
$response = $head.GetResponse()
$total = [long]$response.ContentLength
$response.Close()
if ($total -le 0 -or $total -gt 2147483648) { throw "Unexpected archive length" }
$tailStart = [Math]::Max(0, $total - 262144)
[byte[]]$tail = Get-ByteRange $tailStart ($total - 1)
$footer = -1
for ($i=$tail.Length-22; $i -ge 0; $i--) {
    if ([BitConverter]::ToUInt32($tail, $i) -eq 0x06054b50) {
        $footer = $i
        break
    }
}
if ($footer -lt 0) { throw "ZIP central directory footer missing" }
$cdSize = [long][BitConverter]::ToUInt32($tail, $footer+12)
$cdOffset = [long][BitConverter]::ToUInt32($tail, $footer+16)
if ($cdSize -le 0 -or $cdOffset -eq 0xFFFFFFFF -or $cdOffset + $cdSize -gt $total) {
    throw "Unsupported archive directory layout"
}
[byte[]]$central = Get-ByteRange $cdOffset ($cdOffset + $cdSize - 1)
$entries = @()
$i = 0
while ($i -lt $central.Length) {
    if ([BitConverter]::ToUInt32($central,$i) -ne 0x02014b50) {
        throw "Invalid ZIP directory record"
    }
    $method = [BitConverter]::ToUInt16($central,$i+10)
    $crc = [BitConverter]::ToUInt32($central,$i+16)
    $comp = [long][BitConverter]::ToUInt32($central,$i+20)
    $size = [long][BitConverter]::ToUInt32($central,$i+24)
    $nameLen = [BitConverter]::ToUInt16($central,$i+28)
    $extraLen = [BitConverter]::ToUInt16($central,$i+30)
    $commentLen = [BitConverter]::ToUInt16($central,$i+32)
    $offset = [long][BitConverter]::ToUInt32($central,$i+42)
    $name = [System.Text.Encoding]::UTF8.GetString($central,$i+46,$nameLen)
    if ($name -match '^templates/(web_nothreads_(?:debug|release)[.]zip)$') {
        $entries += [PSCustomObject]@{ Name=$Matches[1]; Method=$method; Crc=$crc; Compressed=$comp; Size=$size; LocalOffset=$offset }
    }
    $i += 46+$nameLen+$extraLen+$commentLen
}
if ($entries.Count -ne 2) { throw "Expected exactly two official Web templates; found $($entries.Count)" }
New-Item -ItemType Directory -Path $staging -Force | Out-Null
try {
    foreach ($entry in $entries) {
        [byte[]]$local = Get-ByteRange $entry.LocalOffset ($entry.LocalOffset + 29)
        if ([BitConverter]::ToUInt32($local,0) -ne 0x04034b50) { throw "Bad ZIP local record" }
        $nameSize = [BitConverter]::ToUInt16($local,26)
        $extraSize = [BitConverter]::ToUInt16($local,28)
        $dataStart = $entry.LocalOffset + 30 + $nameSize + $extraSize
        if ($entry.Compressed -gt 200000000 -or $dataStart + $entry.Compressed -gt $total) {
            throw "Unexpected template entry size"
        }
        [byte[]]$compressed = Get-ByteRange $dataStart ($dataStart+$entry.Compressed-1)
        if ($entry.Method -eq 0) {
            [byte[]]$outputBytes = $compressed
        } elseif ($entry.Method -eq 8) {
            $source = New-Object System.IO.MemoryStream(,$compressed)
            $deflate = [System.IO.Compression.DeflateStream]::new($source,[System.IO.Compression.CompressionMode]::Decompress)
            $buffer = New-Object System.IO.MemoryStream
            $deflate.CopyTo($buffer)
            [byte[]]$outputBytes = $buffer.ToArray()
            $buffer.Dispose()
            $deflate.Dispose()
            $source.Dispose()
        } else { throw "Unexpected ZIP entry compression $($entry.Method)" }
        if ($outputBytes.Length -ne $entry.Size) { throw "Uncompressed size mismatch for $($entry.Name)" }
        $actualCrc = [G01CCrc32]::Compute($outputBytes)
        if ($actualCrc -ne $entry.Crc) { throw "CRC32 mismatch for $($entry.Name)" }
        $candidate = Join-Path $staging $entry.Name
        [System.IO.File]::WriteAllBytes($candidate,$outputBytes)
        Write-Output ("VERIFIED_TEMPLATE={0} SIZE={1} CRC32={2} SHA256={3}" -f $entry.Name,$entry.Size,$actualCrc,(Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash)
    }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    foreach ($name in $required) {
        $target = Join-Path $destination $name
        if (Test-Path $target) { throw "Destination became occupied; refusing overwrite" }
        Move-Item -LiteralPath (Join-Path $staging $name) -Destination $target
        Write-Output "INSTALLED_TEMPLATE=$target"
    }
} finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}
Write-Output "G01C_WEB_TEMPLATES=RECOVERED"
