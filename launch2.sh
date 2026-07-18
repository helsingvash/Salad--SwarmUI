#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURAÇÕES
# ---------------------------------------------------------------------------
SWARMUI_PORT=7801
SWARMUI_SCRIPT=(SwarmUI/launch-linux.sh --port "${SWARMUI_PORT}")

# ---------------------------------------------------------------------------
# INSTALAR NGROK
# ---------------------------------------------------------------------------
install_ngrok() {
    echo "[INFO] Instalando ngrok..."

    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64) NGROK_ARCH="amd64" ;;
        aarch64|arm64) NGROK_ARCH="arm64" ;;
        armv7l) NGROK_ARCH="arm" ;;
        *)
            echo "[ERRO] Arquitetura não suportada: $ARCH"
            exit 1
            ;;
    esac

    TMP_DIR="$(mktemp -d)"

    curl -fsSL \
        "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-${NGROK_ARCH}.tgz" \
        -o "$TMP_DIR/ngrok.tgz"

    tar -xzf "$TMP_DIR/ngrok.tgz" -C "$TMP_DIR"

    sudo mv "$TMP_DIR/ngrok" /usr/local/bin/
    sudo chmod +x /usr/local/bin/ngrok

    rm -rf "$TMP_DIR"

    echo "[INFO] ngrok instalado com sucesso."
}

# ---------------------------------------------------------------------------
# VERIFICAÇÕES
# ---------------------------------------------------------------------------
if ! command -v curl >/dev/null; then
    echo "[ERRO] curl não encontrado."
    exit 1
fi

if ! command -v tar >/dev/null; then
    echo "[ERRO] tar não encontrado."
    exit 1
fi

if ! command -v ngrok >/dev/null; then
    install_ngrok
fi

NGROK_BIN="$(command -v ngrok)"

if [ ! -x "${SWARMUI_SCRIPT[0]}" ]; then
    echo "[ERRO] launch-linux.sh não encontrado ou sem permissão em SwarmUI"
    ls -l SwarmUI || true
    exit 1
fi

# ---------------------------------------------------------------------------
# CONFIGURAR NGROK
# ---------------------------------------------------------------------------

read -rsp "Cole seu token do ngrok: " NGROK_TOKEN
echo

echo "[INFO] Configurando Authtoken..."
"$NGROK_BIN" config add-authtoken "$NGROK_TOKEN" >/dev/null

unset NGROK_TOKEN

sleep 2

# ---------------------------------------------------------------------------
# INICIAR SWARMUI
# ---------------------------------------------------------------------------
echo "[INFO] Iniciando SwarmUI..."
"${SWARMUI_SCRIPT[@]}" &
SWARMUI_PID=$!

sleep 5

# ---------------------------------------------------------------------------
# ABRIR TÚNEL
# ---------------------------------------------------------------------------
echo "[INFO] Abrindo túnel público..."

"$NGROK_BIN" http "127.0.0.1:${SWARMUI_PORT}" >/tmp/ngrok.log 2>&1 &
NGROK_PID=$!

# Aguarda a API do ngrok subir
for i in {1..20}; do
    if curl -s http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

PUBLIC_URL=$(curl -s http://127.0.0.1:4040/api/tunnels \
    | grep -o '"public_url":"[^"]*"' \
    | head -n1 \
    | cut -d'"' -f4)

echo
echo "====================================="
echo " SwarmUI disponível em:"
echo " $PUBLIC_URL"
echo "====================================="

# ---------------------------------------------------------------------------
# ENCERRAMENTO
# ---------------------------------------------------------------------------
cleanup() {
    echo
    echo "[INFO] Encerrando..."
    kill "$NGROK_PID" 2>/dev/null || true
    kill "$SWARMUI_PID" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

wait "$SWARMUI_PID"
