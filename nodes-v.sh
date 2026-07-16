#!/bin/bash

set -e

COMFY_DIR="SwarmUI/dlbackend/ComfyUI"
VENV="$COMFY_DIR/venv"
CUSTOM_NODES="$COMFY_DIR/custom_nodes"

echo "====================================="
echo " Instalando Custom Nodes do ComfyUI"
echo "====================================="

# Ativa venv do ComfyUI
if [ -f "$VENV/bin/activate" ]; then
    echo "🐍 Ativando venv do ComfyUI..."
    source "$VENV/bin/activate"
else
    echo "❌ Venv não encontrado: $VENV"
    exit 1
fi

mkdir -p "$CUSTOM_NODES"

install_node () {
    REPO="$1"
    FOLDER="$2"

    DEST="$CUSTOM_NODES/$FOLDER"

    if [ -d "$DEST/.git" ]; then
        echo ""
        echo "🔄 Atualizando $FOLDER..."
        git -C "$DEST" pull
    else
        echo ""
        echo "⬇️ Clonando $FOLDER..."
        git clone "$REPO" "$DEST"
    fi

    if [ -f "$DEST/requirements.txt" ]; then
        echo "📦 Instalando dependências de $FOLDER..."
        pip install -q -r "$DEST/requirements.txt"
    fi
}

install_node \
https://github.com/kijai/ComfyUI-SUPIR.git \
ComfyUI-SUPIR

install_node \
https://github.com/prodogape/ComfyUI-clip-interrogator.git \
ComfyUI-clip-interrogator

install_node \
https://github.com/Fannovel16/comfyui_controlnet_aux.git \
comfyui_controlnet_aux

install_node \
https://github.com/huchenlei/ComfyUI-openpose-editor.git \
openpose-editor

install_node \
https://github.com/ClownsharkBatwing/RES4LYF.git \
RES4LYF

echo ""
echo "✅ Todos os nodes foram instalados/atualizados!"
