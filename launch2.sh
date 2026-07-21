#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURAÇÕES
# ---------------------------------------------------------------------------

SWARMUI_PORT=7801

SWARMUI_SCRIPT=(
    SwarmUI/launch-linux.sh
    --port "${SWARMUI_PORT}"
    --launch_mode none
)

# ---------------------------------------------------------------------------
# INSTALAR NGROK
# ---------------------------------------------------------------------------

install_ngrok() {
    echo "[INFO] Instalando ngrok..."

    ARCH="$(uname -m)"

    case "$ARCH" in
        x86_64)
            NGROK_ARCH="amd64"
            ;;
        aarch64|arm64)
            NGROK_ARCH="arm64"
            ;;
        armv7l)
            NGROK_ARCH="arm"
            ;;
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

    sudo mv "$TMP_DIR/ngrok" /usr/local/bin/ngrok
    sudo chmod +x /usr/local/bin/ngrok

    rm -rf "$TMP_DIR"

    echo "[INFO] ngrok instalado com sucesso."
}

# ---------------------------------------------------------------------------
# VERIFICAÇÕES
# ---------------------------------------------------------------------------

if ! command -v curl >/dev/null 2>&1; then
    echo "[ERRO] curl não encontrado."
    exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
    echo "[ERRO] tar não encontrado."
    exit 1
fi

if ! command -v ngrok >/dev/null 2>&1; then
    install_ngrok
fi

NGROK_BIN="$(command -v ngrok)"

if [ ! -f "${SWARMUI_SCRIPT[0]}" ]; then
    echo "[ERRO] launch-linux.sh não encontrado:"
    echo "${SWARMUI_SCRIPT[0]}"
    exit 1
fi

if [ ! -x "${SWARMUI_SCRIPT[0]}" ]; then
    echo "[INFO] Corrigindo permissão do SwarmUI..."
    chmod +x "${SWARMUI_SCRIPT[0]}"
fi

# ---------------------------------------------------------------------------
# CONFIGURAR NGROK
# ---------------------------------------------------------------------------

read -rsp "Cole seu token do ngrok: " NGROK_TOKEN
echo

if [ -z "$NGROK_TOKEN" ]; then
    echo "[ERRO] Token do ngrok vazio."
    exit 1
fi

echo "[INFO] Configurando Authtoken..."

"$NGROK_BIN" config add-authtoken "$NGROK_TOKEN" >/dev/null

unset NGROK_TOKEN

sleep 2

# ---------------------------------------------------------------------------
# INICIAR SWARMUI
# ---------------------------------------------------------------------------

echo "[INFO] Iniciando SwarmUI em modo headless..."

"${SWARMUI_SCRIPT[@]}" &

SWARMUI_PID=$!

sleep 5

if ! kill -0 "$SWARMUI_PID" 2>/dev/null; then
    echo "[ERRO] O SwarmUI encerrou inesperadamente."
    exit 1
fi

# ---------------------------------------------------------------------------
# ABRIR TÚNEL NGROK
# ---------------------------------------------------------------------------

echo "[INFO] Abrindo túnel público..."

"$NGROK_BIN" http "127.0.0.1:${SWARMUI_PORT}" \
    >/tmp/ngrok.log 2>&1 &

NGROK_PID=$!

# ---------------------------------------------------------------------------
# AGUARDAR URL DO NGROK
# ---------------------------------------------------------------------------

PUBLIC_URL=""

echo "[INFO] Aguardando URL pública do ngrok..."

for i in {1..30}; do

    PUBLIC_URL=$(
        curl -s http://127.0.0.1:4040/api/tunnels \
        | grep -o 'https://[^"]*' \
        | head -n 1
    )

    if [ -n "$PUBLIC_URL" ]; then
        break
    fi

    sleep 1

done

# ---------------------------------------------------------------------------
# VERIFICAR URL
# ---------------------------------------------------------------------------

if [ -z "$PUBLIC_URL" ]; then
    echo
    echo "[ERRO] Não foi possível obter a URL pública do ngrok."
    echo
    echo "================ LOG DO NGROK ================"
    cat /tmp/ngrok.log
    echo "==============================================="
    exit 1
fi

# ---------------------------------------------------------------------------
# EXIBIR URL
# ---------------------------------------------------------------------------

echo
echo "====================================="
echo " SwarmUI disponível em:"
echo
echo " $PUBLIC_URL"
echo
echo "====================================="
echo

# ---------------------------------------------------------------------------
# ENCERRAMENTO
# ---------------------------------------------------------------------------

cleanup() {
    echo
    echo "[INFO] Encerrando..."

    kill "$NGROK_PID" 2>/dev/null || true
    kill "$SWARMUI_PID" 2>/dev/null || true

    echo "[INFO] Processos encerrados."
}

trap cleanup EXIT INT TERM

wait "$SWARMUI_PID"
