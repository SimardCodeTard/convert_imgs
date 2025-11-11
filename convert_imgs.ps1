# ==============================
# Image converter to png with ffmpeg
# ==============================
param(
    [Parameter(Mandatory = $true)]
    [string]$root
)

$extensions = @("*.heic", "*.jpg", "*.jpeg", "*.webp")
$ffmpegPath = "ffmpeg"

Write-Host "=== Convertisseur d'images vers PNG ===" -ForegroundColor Cyan
Write-Host "Dossier racine : $root"
Write-Host ""

# --- Folder validation ---
if (-not (Test-Path $root)) {
    Write-Host "❌ Le dossier spécifié n'existe pas : $root" -ForegroundColor Red
    exit 1
}

# --- Counts all files by type ---
function Get-FileCounts($path, $exts) {
    $counts = @{}
    # count by type
    foreach ($ext in $exts + "*.png") {
        $name = $ext.Replace("*.", "").ToUpper()
        $counts[$name] = (Get-ChildItem -Path $path -Recurse -Include $ext -File -ErrorAction SilentlyContinue).Count
    }
    # total count of files
    $counts["TOTAL"] = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue).Count
    return $counts
}

# --- Count before ---
Write-Host "📊 Décompte AVANT conversion :"
$before = Get-FileCounts $root $extensions
$order = @("HEIC","JPG","JPEG","WEBP","PNG","TOTAL")
foreach ($key in $order) {
    if ($before.ContainsKey($key)) {
        Write-Host (" - {0}: {1}" -f $key, $before[$key])
    }
}
Write-Host ""

# --- Ask for dry run ---
$choice = Read-Host "Souhaitez-vous lancer une simulation avant la conversion ? (O/N)"
$dryRun = $false
if ($choice -match '^[OoYy]') {
    $dryRun = $true
    Write-Host "`n🧪 Mode simulation activé : aucune modification ne sera faite." -ForegroundColor Yellow
} else {
    Write-Host "`nMode réel : les fichiers originaux seront supprimés après conversion." -ForegroundColor Red
}

# --- User confirmation ---
$confirm = Read-Host "`nVoulez-vous continuer ? (O/N)"
if ($confirm -notmatch '^[OoYy]') {
    Write-Host "❌ Opération annulée par l'utilisateur."
    exit
}

# --- Get all the files to convert ---
$files = Get-ChildItem -Path $root -Recurse -Include $extensions -File
$total = $files.Count
$count = 0

if ($total -eq 0) {
    Write-Host "Aucun fichier à convertir." -ForegroundColor Yellow
    exit
}

# --- Convertoon ---
foreach ($file in $files) {
    $count++
    $output = [System.IO.Path]::ChangeExtension($file.FullName, ".png")

    # Ignore if png already exists
    if (Test-Path $output) {
        Write-Host ("[{0,5:P1}] (IGNORÉ) {1}" -f ($count / $total), $file.Name) -ForegroundColor DarkYellow
        continue
    }

    if ($dryRun) {
        Write-Host ("[{0,5:P1}] Simulation : {1} -> {2}" -f ($count / $total), $file.Name, $output)
        continue
    }

    # Silent convertion with ffmpeg
	$inputPath = $file.FullName
	$outputPath = $output
	& $ffmpegPath -hide_banner -loglevel error -y -i "$inputPath" "$outputPath"

    # Success verification
	if (Test-Path $outputPath) {
		Write-Host ("    ✅ Conversion réussie : {0}" -f $file.Name) -ForegroundColor Green
		if (-not $dryRun) { Remove-Item $inputPath -Force }
	} else {
		Write-Host ("    ⚠️ Échec de la conversion : {0}" -f $file.Name) -ForegroundColor Red
	}
}

# --- Count after ---
Write-Host ""
Write-Host "📊 Décompte APRÈS conversion :"
$after = Get-FileCounts $root $extensions
foreach ($key in $order) {
    if ($after.ContainsKey($key)) {
        Write-Host (" - {0}: {1}" -f $key, $after[$key])
    }
}
Write-Host ""

if ($dryRun) {
    Write-Host "✅ Simulation terminée — aucun fichier n'a été modifié." -ForegroundColor Green
} else {
    Write-Host "✅ Conversion terminée !" -ForegroundColor Green
}
