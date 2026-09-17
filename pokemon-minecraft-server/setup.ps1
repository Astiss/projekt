# Cobblemon (Pokemon) Minecraft server - automatyczna instalacja (Windows, PowerShell)
#
# Co robi ten skrypt:
#   1. Sprawdza obecnosc Javy 17+ (wymagana dla Minecraft 1.20.1 / Fabric).
#   2. Pobiera oficjalny instalator Fabric (fabricmc.net) i stawia serwer Fabric
#      wraz z ORYGINALNYM, legalnym serwerowym jarem Minecrafta pobieranym
#      bezposrednio z serwerow Mojanga (opcja -downloadMinecraft instalatora).
#   3. Pobiera moda Cobblemon (Pokemony) oraz Fabric API z Modrinth (oficjalne API,
#      https://modrinth.com/mod/cobblemon) - to darmowy, open-source'owy mod,
#      wiec pobieranie i hostowanie go jest w pelni legalne.
#   4. Tworzy server.properties z online-mode=false, dzieki czemu polaczysz sie
#      kontem non-premium / TLauncher (BEZ potrzeby kupowania Minecrafta).
#   5. Tworzy skrypt startowy start.bat z sensownymi flagami pamieci/JVM.
#
# Skrypt NIE instaluje zadnego "pirackiego Minecrafta" ani launchera -
# zakladamy, ze TLauncher juz masz zainstalowany samodzielnie.
#
# Uzycie: otworz PowerShell W TYM FOLDERZE i uruchom:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\setup.ps1

$ErrorActionPreference = "Stop"

$McVersion       = "1.20.1"      # wersja Minecrafta obslugiwana stabilnie przez Cobblemon
$FabricInstaller = "1.0.1"
$ServerDir       = $PSScriptRoot
$ModsDir         = Join-Path $ServerDir "mods"

Write-Host "=== Cobblemon Server Setup ===" -ForegroundColor Cyan
Write-Host "Docelowy folder: $ServerDir"

# --- 1. Sprawdzenie Javy ---
try {
    $javaVersionOutput = & java -version 2>&1 | Out-String
} catch {
    Write-Host "Nie znaleziono Javy. Pobierz i zainstaluj Java 17 (Temurin):" -ForegroundColor Yellow
    Write-Host "https://adoptium.net/temurin/releases/?version=17"
    exit 1
}
Write-Host "Znaleziono Jave:`n$javaVersionOutput"

New-Item -ItemType Directory -Force -Path $ServerDir | Out-Null
New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
Set-Location $ServerDir

# --- 2. Fabric installer + serwer + oryginalny jar Minecrafta z Mojanga ---
$installerJar = "fabric-installer-$FabricInstaller.jar"
if (-not (Test-Path $installerJar)) {
    Write-Host "Pobieram Fabric installer..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$FabricInstaller/fabric-installer-$FabricInstaller.jar" -OutFile $installerJar
}

Write-Host "Instaluje serwer Fabric $McVersion (pobiera oryginalny server.jar od Mojanga)..." -ForegroundColor Cyan
& java -jar $installerJar server -mcversion $McVersion -downloadMinecraft -dir $ServerDir

# --- 3. Cobblemon + Fabric API z Modrinth (oficjalne API) ---
function Get-LatestModrinthFile {
    param(
        [string]$Slug,
        [string]$GameVersion,
        [string]$Loader = "fabric"
    )
    $uri = "https://api.modrinth.com/v2/project/$Slug/version?game_versions=[`"$GameVersion`"]&loaders=[`"$Loader`"]"
    $versions = Invoke-RestMethod -Uri $uri
    if (-not $versions -or $versions.Count -eq 0) {
        throw "Brak wersji dla $Slug / $GameVersion / $Loader"
    }
    $latest = $versions[0]
    $file = $latest.files | Where-Object { $_.primary } | Select-Object -First 1
    if (-not $file) { $file = $latest.files[0] }
    return $file
}

Write-Host "Pobieram Fabric API (wymagane przez Cobblemon)..." -ForegroundColor Cyan
$fapiFile = Get-LatestModrinthFile -Slug "fabric-api" -GameVersion $McVersion
Invoke-WebRequest -Uri $fapiFile.url -OutFile (Join-Path $ModsDir $fapiFile.filename)

Write-Host "Pobieram Cobblemon..." -ForegroundColor Cyan
$cobbleFile = Get-LatestModrinthFile -Slug "cobblemon" -GameVersion $McVersion
Invoke-WebRequest -Uri $cobbleFile.url -OutFile (Join-Path $ModsDir $cobbleFile.filename)

Write-Host "Zainstalowane mody:" -ForegroundColor Green
Get-ChildItem $ModsDir | Format-Table Name

# --- 4. EULA (wymagane przez Mojanga, akceptujesz je swiadomie sam) ---
Write-Host ""
Write-Host "Uruchamiajac serwer akceptujesz EULA Minecrafta: https://aka.ms/MinecraftEULA" -ForegroundColor Yellow
$agree = Read-Host "Akceptujesz EULA? (tak/nie)"
if ($agree -notmatch "^(t|tak|y|yes)$") {
    Write-Host "Nie zaakceptowano EULA - przerywam." -ForegroundColor Red
    exit 1
}
"eula=true" | Out-File -Encoding ascii (Join-Path $ServerDir "eula.txt")

# --- 5. server.properties: kluczowe - online-mode=false ---
$propsPath = Join-Path $ServerDir "server.properties"
if (-not (Test-Path $propsPath)) { New-Item -ItemType File -Path $propsPath | Out-Null }
$props = @{
    "online-mode"        = "false"   # <- pozwala grac bez konta premium (TLauncher itp.)
    "enforce-secure-profile" = "false"  # <- wylacza wymog podpisanych profili Mojang (potrzebne dla non-premium na nowszych wersjach)
    "white-list"         = "false"   # <- wylacza whiteliste, kazdy moze wejsc
    "motd"               = "Pokemon Server (Cobblemon) - non-premium OK"
    "difficulty"         = "normal"
    "gamemode"            = "survival"
    "max-players"        = "20"
    "view-distance"      = "10"
    "server-port"        = "25565"
    "enable-command-block" = "true"
}
$existing = @{}
if (Test-Path $propsPath) {
    Get-Content $propsPath | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") { $existing[$matches[1].Trim()] = $matches[2] }
    }
}
foreach ($k in $props.Keys) { $existing[$k] = $props[$k] }
$existing.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Set-Content -Encoding ascii $propsPath

# --- 6. Skrypt startowy ---
$startBat = @"
@echo off
cd /d "%~dp0"
java -Xms2G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -jar fabric-server-launch.jar nogui
pause
"@
$startBat | Set-Content -Encoding ascii (Join-Path $ServerDir "start.bat")

Write-Host ""
Write-Host "=== GOTOWE ===" -ForegroundColor Green
Write-Host "Uruchom serwer klikajac dwukrotnie: start.bat"
Write-Host "Zobacz README.md po instrukcje polaczenia z TLaunchera oraz udostepnienia znajomym."
