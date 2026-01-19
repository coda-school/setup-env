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

# --- Mise à jour des paquets ---
info "Mise à jour des paquets système..."
sudo apt update && sudo apt upgrade -y || err "Échec mise à jour des paquets"

# --- Git et GitHub Desktop ---
if ! has git; then
    info "Installation de Git..."
    sudo apt install -y git || err "Échec installation Git"
    ok "Git installé."
else
    ok "Git déjà présent."
fi

# GitHub Desktop n'est pas officiellement disponible pour Linux, mais on peut utiliser l'alternative "GitKraken" ou "GitHub CLI"
if ! has gh; then
    info "Installation de GitHub CLI..."
    sudo apt install -y gh || err "Échec installation GitHub CLI"
    ok "GitHub CLI installé."
else
    ok "GitHub CLI déjà présent."
fi

# --- VS Code ---
if ! has code; then
    info "Installation de VS Code..."
    sudo apt install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code || err "Échec installation VS Code"
    ok "VS Code installé."
    code --install-extension ms-vscode.cpptools || err "Échec installation extension C/C++"
    ok "Extension C/C++ pour VS Code installée."
else
    ok "VS Code déjà présent."
fi

# --- GCC ---
if ! has gcc; then
    info "Installation de gcc..."
    sudo apt install -y build-essential || err "Échec installation gcc"
    ok "gcc installé."
else
    ok "gcc déjà présent ($(gcc --version | head -n1))."
fi

# --- Docker ---
if ! has docker; then
    info "Installation de Docker..."
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io || err "Échec installation Docker"
    sudo usermod -aG docker $USER
    ok "Docker installé. Redémarrez votre session pour appliquer les permissions."
else
    ok "Docker déjà présent."
fi

# --- Docker Desktop ---
if [ ! -d "/usr/bin/docker-desktop" ]; then
    info "Installation de Docker Desktop..."
    # Téléchargement du package .deb
    TEMP_DIR="/tmp/docker_desktop_install"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR" || err "Impossible d'accéder au répertoire temporaire."
    wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.27.2-amd64.deb -O docker-desktop.deb || err "Échec du téléchargement de Docker Desktop."

    # Installation
    sudo apt install -y ./docker-desktop.deb || err "Échec de l'installation de Docker Desktop."
    rm -rf "$TEMP_DIR"

    # Ajout de l'utilisateur au groupe docker (si pas déjà fait)
    sudo usermod -aG docker $USER

    ok "Docker Desktop installé. Redémarrez votre session pour finaliser l'installation."
else
    ok "Docker Desktop déjà présent."
fi

# Test rapide avec une image FrankenPHP
if ! docker ps -a --format '{{.Names}}' | grep -q '^frankenphp-container$'; then
    info "Test lancement conteneur FrankenPHP..."
    docker run -d --name frankenphp-container -p 8080:80 -p 443:443 dunglas/frankenphp || err "Échec lancement conteneur FrankenPHP"
    ok "Conteneur FrankenPHP démarré."
    docker stop frankenphp-container >/dev/null
    docker rm frankenphp-container >/dev/null
    ok "Conteneur FrankenPHP arrêté et supprimé."
else
    ok "Conteneur FrankenPHP déjà créé (test sauté)."
fi

# --- PhpStorm ---
if ! has phpstorm; then
    info "Installation de PhpStorm via Snap..."
    sudo snap install phpstorm --classic || err "Échec installation PhpStorm"
    ok "PhpStorm installé."
else
    ok "PhpStorm déjà présent."
fi

# --- JDK ---
if ! java -version >/dev/null 2>&1; then
    info "Installation du JDK 21 (Temurin)..."
    apt install openjdk-25-jdk  || err "Échec installation JDK"
    ok "Open JDK 25."
else
    ok "JDK déjà présent ($(java -version 2>&1 | head -n1))."
fi

# --- IntelliJ IDEA ---
if ! has idea; then
    info "Installation de IntelliJ IDEA Ultimate via Snap..."
    sudo snap install intellij-idea-ultimate --classic || err "Échec installation IntelliJ IDEA"
    ok "IntelliJ IDEA Ultimate installé."
else
    ok "IntelliJ IDEA déjà présent."
fi

# --- SceneBuilder for JavaFX ---
if ! has scenebuilder; then
    info "Installation de Scene Builder..."
    TEMP_DIR="/tmp/scene_builder_install"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR" || err "Impossible d'accéder au répertoire temporaire."

    # Téléchargement du fichier .deb
    info "Téléchargement de Scene Builder..."
    wget https://download2.gluonhq.com/scenebuilder/25.0.0/install/linux/SceneBuilder-25.0.0.deb -O SceneBuilder.deb || err "Échec du téléchargement de Scene Builder."

    # Installation
    chmod +x SceneBuilder.deb
    dpkg -i SceneBuilder.deb || err "Échec de l'installation de Scene Builder."
    apt-get install -f -y || err "Échec de la résolution des dépendances."
    apt autoremove -y

    # Nettoyage
    rm -rf "$TEMP_DIR"
    ok "Scene Builder installé."
else
    ok "Scene Builder déjà présent."
fi

# --- WebStorm ---
if ! has webstorm then
    info "Installation de WebStorm via Snap..."
    sudo snap install webstorm --classic || err "Échec installation WebStorm"
    ok "WebStorm installé."
else
    ok "WebStorm déjà présent."
fi


# --- Node.js ---
if ! has node; then
    info "Installation de Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs || err "Échec installation Node.js"
    ok "Node.js installé ($(node -v))."
else
    ok "Node.js déjà présent ($(node -v))."
fi

ok "✅ Installation terminée avec succès."
exit 0