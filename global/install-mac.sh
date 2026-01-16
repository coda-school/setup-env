#!/bin/bash
set -euo pipefail

# --- Fonctions utilitaires ---
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # reset couleur

ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
err()  { echo -e "${RED}[ERREUR]${NC} $*"; exit 1; }
info() { echo "[INFO] $*"; }

# Vérifie la présence d’une commande
has() { command -v "$1" >/dev/null 2>&1; }

# --- Installation Homebrew ---
if ! has brew; then
    info "Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || err "Échec installation Homebrew"
    ok "Homebrew installé."
else
    ok "Homebrew déjà présent."
fi

# --- Git et GitHub Desktop ---
if ! has git; then
    brew install git || err "Échec installation Git"
    ok "Git installé."
else
    ok "Git déjà présent."
fi

if ! has github; then
    brew install --cask github || err "Échec installation GitHub Desktop"
    ok "GitHub Desktop installé."
else
    ok "GitHub Desktop déjà présent."
fi

# --- VS Code ---
if ! has code; then
    brew install --cask visual-studio-code || err "Échec installation VS Code"
    ok "VS Code installé."
    code --install-extension ms-vscode.cpptools || err "Échec installation extension C/C++"
    ok "Extension C/C++ pour VS Code installée."
else
    ok "VS Code déjà présent."
fi

# --- Xcode command line tools ---
if ! xcode-select -p >/dev/null 2>&1; then
    info "Installation des outils Xcode..."
    xcode-select --install || true
    read -p "Appuyez sur Entrée une fois l'installation terminée..."
    sudo xcodebuild -license accept || err "Échec acceptation licence Xcode"
    ok "Outils Xcode installés."
else
    ok "Outils Xcode déjà présents."
fi

# --- GCC ---
if ! has gcc; then
    brew install gcc || err "Échec installation gcc"
    ok "gcc installé."
else
    ok "gcc déjà présent ($(gcc --version | head -n1))."
fi

# --- Docker Desktop ---
if ! has docker; then
    brew install --cask docker || err "Échec installation Docker Desktop"
    ok "Docker Desktop installé."
    open -a Docker
    info "Attente que Docker soit prêt..."
    until docker system info >/dev/null 2>&1; do sleep 1; done
    ok "Docker Desktop est prêt."
else
    ok "Docker déjà présent."
fi

# Test rapide avec une image FrankenPHP
if ! docker ps -a --format '{{.Names}}' | grep -q '^frankenphp-container$'; then
    info "Test lancement conteneur FrankenPHP..."
    docker run -d --name frankenphp-container -p 8080:80 -p 443:443 dunglas/frankenphp || err "Échec lancement conteneur FrankenPHP"
    ok "Conteneur FrankenPHP démarré (ports 8080 et 443)."
    sleep 3  # Temps pour que le conteneur démarre complètement
    docker stop frankenphp-container >/dev/null
    docker rm frankenphp-container >/dev/null
    ok "Conteneur FrankenPHP arrêté et supprimé."
else
    ok "Conteneur FrankenPHP déjà créé (test sauté)."
fi

# --- PhpStorm ---
if ! has phpstorm; then
    brew install --cask phpstorm || err "Échec installation PhpStorm"
    ok "PhpStorm installé."
else
    ok "PhpStorm déjà présent."
fi

# --- Node.js ---
if ! has node; then
    brew install node || err "Échec installation Node.js"
    ok "Node.js installé ($(node -v))."
else
    ok "Node.js déjà présent ($(node -v))."
fi

# --- SDKMan ---
if ! has sdk; then
    curl -s "https://get.sdkman.io" | bash
    ok "SDKMan installé"
else
    ok "SDKman déjà présent."
fi

# --- JDK ---
if ! java -version >/dev/null 2>&1; then
    sdk install java 25.0.1-tem
    ok "JDK 25 Temurin installé."
else
    ok "JDK déjà présent ($(java -version 2>&1 | head -n1))."
fi

# --- IntelliJ IDEA ---
if ! has intellij-idea-ultimate; then
    brew install --cask intellij-idea || err "Échec installation IntelliJ IDEA"
    ok "Intellij Ultimate installé."
else
    ok "Intellij Ultimate déjà présent."
fi

# --- SceneBuilder for JavaFX ---
if ! has scenebuilder; then
    brew install scenebuilder
    ok "Scenebuilder installé"
else
    ok "Scenebuilder déjà présent."
fi

ok "✅ Installation terminée avec succès."
exit 0