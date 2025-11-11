# ==============================
# Image converter to PNG with FFmpeg (parallel)
# ==============================
param(
    [Parameter(Mandatory = $true)]
    [string]$root
)

$extensions = @("*.heic", "*.jpg", "*.jpeg", "*.webp")
$ffmpegPath = "ffmpeg"

Write-Host "=== Image Converter to PNG ===" -ForegroundColor Cyan
Write-Host "Root folder: $root"
Write-Host ""

# --- Folder validation ---
if (-not (Test-Path $root)) {
    Write-Host "❌ The specified folder does not exist: $root" -ForegroundColor Red
    exit 1
}

# --- Function to count files by type ---
function Get-FileCounts($path, $exts) {
    $counts = @{}
    foreach ($ext in $exts + "*.png") {
        $name = $ext.Replace("*.", "").ToUpper()
        $counts[$name] = (Get-ChildItem -Path $path -Recurse -Include $ext -File -ErrorAction SilentlyContinue).Count
    }
    $counts["TOTAL"] = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue).Count
    return $counts
}

# --- Count before ---
Write-Host "📊 File count BEFORE conversion:"
$before = Get-FileCounts $root $extensions
$order = @("HEIC","JPG","JPEG","WEBP","PNG","TOTAL")
foreach ($key in $order) {
    if ($before.ContainsKey($key)) {
        Write-Host (" - {0}: {1}" -f $key, $before[$key])
    }
}
Write-Host ""

# --- Ask for dry run ---
$choice = Read-Host "Do you want to perform a dry-run before conversion? (Y/N)"
$dryRun = $false
if ($choice -match '^[Yy]') {
    $dryRun = $true
    Write-Host "`n🧪 Dry-run mode enabled: no files will be modified." -ForegroundColor Yellow
} else {
    Write-Host "`nReal mode: original files will be deleted after conversion." -ForegroundColor Red
}

# --- User confirmation ---
$confirm = Read-Host "`nDo you want to continue? (Y/N)"
if ($confirm -notmatch '^[Yy]') {
    Write-Host "❌ Operation canceled by user."
    exit
}

# --- Get all the files to convert ---
$files = Get-ChildItem -Path $root -Recurse -Include $extensions -File
$total = $files.Count

if ($total -eq 0) {
    Write-Host "No files to convert." -ForegroundColor Yellow
    exit
}

Write-Host "`nStarting conversion of $total files..." -ForegroundColor Cyan

# --- Parallel conversion ---
$files | ForEach-Object -Parallel {
    $inputPath = $_.FullName
    $outputPath = [System.IO.Path]::ChangeExtension($inputPath, ".png")

    # Access outer variables with $using:
    $ffmpegPathLocal = $using:ffmpegPath
    $dryRunLocal = $using:dryRun

    if (Test-Path $outputPath) {
        Write-Host ("[{0}] (SKIPPED) {1}" -f (Get-Date -Format "HH:mm:ss"), $_.Name) -ForegroundColor DarkYellow
        return
    }

    if ($dryRunLocal) {
        Write-Host ("[{0}] Dry-run: {1} -> {2}" -f (Get-Date -Format "HH:mm:ss"), $_.Name, $outputPath)
        return
    }

    & $ffmpegPathLocal -hide_banner -loglevel error -y -i "$inputPath" "$outputPath"

    if (Test-Path $outputPath) {
        Write-Host ("[{0}] ✅ Converted: {1}" -f (Get-Date -Format "HH:mm:ss"), $_.Name) -ForegroundColor Green
        Remove-Item $inputPath -Force
    } else {
        Write-Host ("[{0}] ⚠️ Failed: {1}" -f (Get-Date -Format "HH:mm:ss"), $_.Name) -ForegroundColor Red
    }

} -ThrottleLimit 15

# --- Count after ---
Write-Host "`n📊 File count AFTER conversion:"
$after = Get-FileCounts $root $extensions
foreach ($key in $order) {
    if ($after.ContainsKey($key)) {
        Write-Host (" - {0}: {1}" -f $key, $after[$key])
    }
}
Write-Host ""

if ($dryRun) {
    Write-Host "✅ Dry-run completed — no files were modified." -ForegroundColor Green
} else {
    Write-Host "✅ Conversion completed!" -ForegroundColor Green
}
