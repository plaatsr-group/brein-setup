# ============================================================
#  Zet het tweede brein van Lotte op een Windows-laptop.
#
#  Gebruik: open Windows PowerShell (Start-knop, typ "PowerShell")
#  en plak deze ene regel:
#
#    irm https://raw.githubusercontent.com/plaatsr-group/brein-setup/main/zet-mijn-brein-op.ps1 | iex
#
#  Het script installeert Git, Obsidian en Claude, haalt het brein
#  op van GitHub en opent het in Obsidian. Je kunt het veilig
#  nog een keer draaien: wat er al is, wordt overgeslagen.
# ============================================================

$ErrorActionPreference = "Stop"
$BreinRepo = "https://github.com/plaatsr-group/lotte-brein.git"
$BreinMap = Join-Path $env:USERPROFILE "Brein"

function Stap($nr, $tekst) { Write-Host ""; Write-Host "== Stap ${nr}: $tekst" -ForegroundColor Cyan }
function Gelukt($tekst) { Write-Host "   OK: $tekst" -ForegroundColor Green }
function Probleem($tekst) {
    Write-Host ""
    Write-Host "   PROBLEEM: $tekst" -ForegroundColor Yellow
    Write-Host "   Geen paniek: maak een foto van dit scherm en app hem naar Martin." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Dit script zet je tweede brein op. Het duurt een paar minuten." -ForegroundColor Cyan
Write-Host "Er verschijnen tussendoor vensters die om toestemming vragen: kies steeds Ja/Toestaan."

# ---- Stap 1: winget aanwezig? --------------------------------
Stap 1 "controleren of de Windows-appwinkel-installer (winget) er is"
$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    Probleem "winget ontbreekt. Open de Microsoft Store, zoek 'App Installer', klik Installeren, en draai dit script daarna opnieuw."
    return
}
Gelukt "winget gevonden"

function Installeer($naam, $id) {
    $al = winget list --id $id -e --accept-source-agreements 2>$null | Select-String $id
    if ($al) { Gelukt "$naam staat er al"; return }
    Write-Host "   $naam installeren (dit kan even duren)..."
    winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "$naam installeren is niet gelukt (code $LASTEXITCODE)." }
    Gelukt "$naam geinstalleerd"
}

# ---- Stap 2: programma's installeren -------------------------
Stap 2 "Git, Obsidian en Claude installeren"
Installeer "Git" "Git.Git"
Installeer "Obsidian" "Obsidian.Obsidian"
try { Installeer "Claude" "Anthropic.Claude" }
catch { Probleem "Claude kon niet automatisch. Ga later naar claude.ai/download en installeer hem daar; de rest werkt gewoon door." }

# ---- Stap 3: git vinden en instellen -------------------------
Stap 3 "Git instellen op jouw naam"
$gitExe = "$env:ProgramFiles\Git\cmd\git.exe"
if (-not (Test-Path $gitExe)) { $gitExe = "${env:ProgramFiles(x86)}\Git\cmd\git.exe" }
if (-not (Test-Path $gitExe)) {
    $c = Get-Command git -ErrorAction SilentlyContinue
    if ($c) { $gitExe = $c.Source }
}
if (-not (Test-Path $gitExe)) { Probleem "Git is net geinstalleerd maar nog niet vindbaar. Sluit dit venster, open PowerShell opnieuw en draai het script nog een keer."; return }
& $gitExe config --global user.name "Lotte Geelen"
& $gitExe config --global user.email "lotte@plaatsr.nl"
& $gitExe config --global core.autocrlf false
& $gitExe config --global pull.rebase false
& $gitExe config --global init.defaultBranch main
Gelukt "Git staat op naam van Lotte Geelen (lotte@plaatsr.nl)"

# ---- Stap 4: het brein ophalen -------------------------------
Stap 4 "je brein ophalen van GitHub"
if (Test-Path (Join-Path $BreinMap ".git")) {
    Gelukt "de map Brein bestaat al, ophalen wordt overgeslagen"
} else {
    Write-Host "   LET OP: er opent zo een browservenster om in te loggen bij GitHub."
    Write-Host "   Log in met je eigen GitHub-account (lotte@plaatsr.nl) en klik op Authorize."
    & $gitExe clone $BreinRepo $BreinMap
    if ($LASTEXITCODE -ne 0) { Probleem "Het ophalen is niet gelukt. Meestal: nog geen toegang tot het brein. App je GitHub-gebruikersnaam naar Martin en probeer het daarna opnieuw."; return }
    Gelukt "je brein staat nu in $BreinMap"
}

# ---- Stap 5: Obsidian openen ---------------------------------
Stap 5 "Obsidian openen op je brein"
$obsidian = Join-Path $env:LOCALAPPDATA "Programs\Obsidian\Obsidian.exe"
if (Test-Path $obsidian) {
    Start-Process $obsidian
    Start-Sleep -Seconds 5
    Start-Process ("obsidian://open?path=" + [uri]::EscapeDataString($BreinMap))
    Gelukt "Obsidian gestart"
    Write-Host ""
    Write-Host "   In Obsidian: kies zo nodig 'Open folder as vault' en wijs de map $BreinMap aan." -ForegroundColor Cyan
    Write-Host "   Vraagt Obsidian of je de plugins van deze vault vertrouwt: kies 'Trust author and enable plugins'." -ForegroundColor Cyan
} else {
    Probleem "Obsidian is geinstalleerd maar niet gevonden op de verwachte plek. Start Obsidian via het Startmenu en kies 'Open folder as vault' met de map $BreinMap."
}

Write-Host ""
Write-Host "Klaar! Pak nu de handleiding (PDF) erbij voor de laatste twee dingen: Fireflies en Claude." -ForegroundColor Green
