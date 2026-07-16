#!/usr/bin/env bash

set -e

DESTINO="SwarmUI/Models/Lora"
mkdir -p "$DESTINO"

echo "Cole a URL ou apenas o domínio do Cloudflare Tunnel:"
read -rp "> " HOST

HOST="${HOST#https://}"
HOST="${HOST#http://}"
HOST="${HOST%/}"

BASE_URL="https://$HOST"

echo "Obtendo lista de arquivos..."

curl -s "$BASE_URL/" \
| grep -oE 'href="[^"]+\.safetensors"' \
| cut -d'"' -f2 \
| while read -r arquivo; do
    echo "Baixando $arquivo..."
    wget -c -P "$DESTINO" "$BASE_URL/$arquivo"
done

echo "Concluído!"
