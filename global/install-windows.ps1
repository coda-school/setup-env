# install.ps1 — Script d’installation (Windows 11) idempotent
# Mise à jour de Powershell :
#   winget install --id Microsoft.PowerShell --source winget
# Exécuter en PowerShell (Admin) :
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1

# -------------------- Sécurité & couleurs --------------------
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force | Out-Null
$script:FAILED = $false

function Ok   ($msg){
    Write-Host "[OK] $msg" -ForegroundColor Green
}
function Err  ($msg){
    Write-Host "[ERREUR] $msg" -ForegroundColor Red
    $script:FAILED = $true
}
function Info ($msg){
    Write-Host "[INFO] $msg" -ForegroundColor Yellow
}
function Has  ($cmd){
    [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# refresh env for current session (Chocolatey)
function Refresh-Env {
  try {
    if (Get-Command refreshenv -ErrorAction SilentlyContinue) { refreshenv; return }
    $chocoProfile = Join-Path $env:ChocolateyInstall "helpers\chocolateyProfile.psm1"
    if (Test-Path $chocoProfile) { Import-Module $chocoProfile -ErrorAction SilentlyContinue; refreshenv; return }
  } catch {}
  if (Get-Command Update-SessionEnvironment -ErrorAction SilentlyContinue) {
    Update-SessionEnvironment; return
  }

  $paths = @(
    "$env:ProgramFiles\Git\cmd",
    "C:\Program Files\Microsoft VS Code\bin",
    "C:\Program Files\Docker\Docker\resources\bin",
    "C:\tools\mingw64\bin"
  )
  foreach ($p in $paths) {
    if (Test-Path $p -and -not ($env:Path -split ';' | Where-Object { $_ -ieq $p })) {
      $env:Path = "$p;$env:Path"
    }
  }
}

# -------------------- Chocolatey --------------------
if (-not (Has "choco")) {
  Info "Installation de Chocolatey…"
  try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Ok "Chocolatey installé."
  } catch {
    Err "Échec installation Chocolatey: $($_.Exception.Message)"
  }
} else { Ok "Chocolatey déjà présent." }

Refresh-Env

# Utilitaires Chocolatey
function Is-ChocoInstalled($pkgId) {
  choco list --local-only --exact $pkgId | Select-String -Quiet " $pkgId " 2>$null
}

function Ensure-Choco ($pkgId, $label=$null) {
  if (-not $label) { $label = $pkgId }
  if (Is-ChocoInstalled $pkgId) { Ok "$label déjà installé."; return }
  Info "Installation de $label…"
  choco install $pkgId -y --no-progress
  if ($LASTEXITCODE -ne 0) { Err "Échec installation $label"; return }
  Refresh-Env
  Ok "$label installé."
}

# -------------------- VS Code + extension C/C++ --------------------
Ensure-Choco "vscode" "Visual Studio Code"
Refresh-Env

if (Has "code") {
  $exts = code --list-extensions 2>$null
  if ($exts -match '^ms-vscode\.cpptools$') {
    Ok "Extension VS Code 'ms-vscode.cpptools' déjà installée."
  } else {
    Info "Installation de l’extension C/C++…"
    code --install-extension ms-vscode.cpptools --force | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok "Extension C/C++ installée." } else { Err "Échec installation extension C/C++." }
  }
} else {
  Err "La commande 'code' est introuvable (VS Code installé mais CLI non dispo)."
}

# -------------------- MinGW / GCC --------------------
Ensure-Choco "mingw" "MinGW (GCC)"
$mingwPath = "C:\tools\mingw64\bin"
try {
  $machinePath = [Environment]::GetEnvironmentVariable("Path","Machine")
  if ($machinePath -notlike "*$mingwPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$mingwPath", "Machine")
    Info "Ajout de MinGW au PATH machine."
  }
} catch {
  Err "Impossible d’ajouter MinGW au PATH machine (droits nécessaires)."
}

Refresh-Env
if (Has "gcc") {
  $v = & gcc --version 2>$null | Select-Object -First 1
  Ok "GCC disponible : $v"
} else { Err "GCC non détecté dans le PATH." }

# -------------------- Git & GitHub Desktop --------------------
Ensure-Choco "git" "Git"
Ensure-Choco "github-desktop" "GitHub Desktop"

# -------------------- Configure VSCode as Git Code Editor --------------------
Refresh-Env
git config --global core.editor "code --wait"

# -------------------- Docker Desktop --------------------
Ensure-Choco "docker-desktop" "Docker Desktop"

# -------------------- IDE & runtimes --------------------
Ensure-Choco "phpstorm" "PhpStorm"
Ensure-Choco "openjdk"  "OpenJDK"
Ensure-Choco "nodejs-lts" "Node.js LTS"
if (Has "node") { Ok "Node : $(node -v)"; } else { Err "Node non détecté." }

# -------------------- Notepad++ --------------------
Ensure-Choco "notepadplusplus" "Notepad++"

# -------------------- Fin --------------------
if ($script:FAILED) {
  Err "Installation terminée avec erreurs."
  exit 1
} else {
  Ok "✅ Installation terminée avec succès (idempotente)."
  exit 0
}
