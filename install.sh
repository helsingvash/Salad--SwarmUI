#!/bin/bash
set -e

echo "🚀 Iniciando instalação do SwarmUI..."

# =========================
# Atualização do sistema
# =========================
apt install sudo
sudo apt update -y
sudo apt upgrade -y

# =========================
# Dependências do sistema
# =========================
sudo apt install -y \
    libcairo2-dev \
    libgl1 \
    libglib2.0-0 \
    pkg-config \
    libjpeg-turbo8-dev \
    libpng-dev \
    unzip \
    wget \
    curl \
    git \
    nano \
    python3-pip

# =========================
# Atualizar ipykernel
# =========================
pip install --upgrade ipykernel

# =========================
# Clonar SwarmUI
# =========================
if [ ! -d "SwarmUI" ]; then
    echo "📥 Clonando SwarmUI..."
    git clone https://github.com/mcmonkeyprojects/SwarmUI.git
else
    echo "📁 SwarmUI já existe, pulando clone."
fi

# =========================
# Instalar .NET 8
# =========================
echo "⬇️ Instalando .NET 8..."
wget -q https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version 8.0.413

# Adiciona dotnet ao PATH
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$HOME/.dotnet"

# =========================
# Instalar zrok
# =========================
echo "🌐 Instalando zrok..."
curl -sSf https://get.openziti.io/install.bash | bash -s zrok

# =========================
# Configurar token zrok
# =========================

read -rsp "Cole seu token do zrok: " ZROK_TOKEN
echo

export ZROK_TOKEN

echo "Instalando PyWavelets"
python -m pip install PyWavelets pytorch-lightning

echo "✅ Instalação do SwarmUI concluída!"
echo "ℹ️ Reinicie o terminal ou execute: source ~/.bashrc"
