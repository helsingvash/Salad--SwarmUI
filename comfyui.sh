#!/bin/bash

set -e

DEST="SwarmUI/dlbackend"
REPO="https://github.com/comfyanonymous/ComfyUI.git"
VENV="../venv"    # ajuste conforme necessário

mkdir -p "$DEST"
cd "$DEST"

if [ -d "ComfyUI/.git" ]; then
    echo "Atualizando ComfyUI..."
    cd ComfyUI
    git pull
else
    echo "Clonando ComfyUI..."
    git clone "$REPO"
    cd ComfyUI
fi

# Cria o ambiente virtual se não existir
if [ ! -d "$VENV" ]; then
    echo "Criando ambiente virtual em $VENV..."
    python3 -m venv "$VENV"
fi

# Ativa o ambiente virtual
if [ -f "$VENV/bin/activate" ]; then
    echo "Ativando ambiente virtual..."
    source "$VENV/bin/activate"
else
    echo "Erro: não foi possível encontrar o ambiente virtual em $VENV"
    exit 1
fi

echo "Atualizando pip..."
python -m pip install --upgrade pip setuptools wheel

echo "Instalando dependências..."
python -m pip install -r requirements.txt

echo "Concluído!"
