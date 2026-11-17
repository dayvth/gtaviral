#!/bin/bash
# Instalador do GTAVIral para Mac (Apple Silicon). Uso:
#   curl -fsSL https://raw.githubusercontent.com/dayvth/gtaviral/main/install.sh | bash
# Opções: --voz-local  (instala também a voz grátis Chatterbox, ~3 GB)   --sem-app  (só o motor)
set -euo pipefail

REPO="dayvth/gtaviral"
REL="${GTAVIRAL_REL:-https://github.com/$REPO/releases/latest/download}"
DATA="$HOME/Library/Application Support/GTAVIral"
FFVER="b6.1.1"
FFMPEG_SHA="a90e3db6a3fd35f6074b013f948b1aa45b31c6375489d39e572bea3f18336584"
FFPROBE_SHA="bb2db6f5d8cef919da12fbf592119a987202a8c060a886f3cab091f9cab90b64"
VOZ_LOCAL=0; SEM_APP=0
for a in "$@"; do case "$a" in --voz-local) VOZ_LOCAL=1;; --sem-app) SEM_APP=1;; esac; done

rosa=$'\033[38;5;205m'; ok=$'\033[32m'; err=$'\033[31m'; fim=$'\033[0m'
passo() { printf "\n%s▸ %s%s\n" "$rosa" "$1" "$fim"; }
falha() { printf "\n%s✗ %s%s\n" "$err" "$1" "$fim"; exit 1; }
sha_ok() { [ "$(shasum -a 256 "$1" | awk '{print $1}')" = "$2" ]; }

printf "%s\n  GTAVIral — instalação\n%s" "$rosa" "$fim"
[ "$(uname -s)" = "Darwin" ] || falha "Este instalador é para Mac. Para Windows, veja o guia em PDF."
[ "$(uname -m)" = "arm64" ] || falha "O GTAVIral precisa de um Mac com chip Apple (M1, M2, M3, M4 ou M5)."
LIVRE=$(df -g "$HOME" | awk 'NR==2{print $4}')
[ "${LIVRE:-0}" -ge 15 ] || falha "Pouco espaço livre (${LIVRE} GB). Libere pelo menos 15 GB e rode de novo."
mkdir -p "$DATA/bin"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

passo "1/5 · Gerenciador do motor (uv)"
UV=""
for c in "$HOME/.local/bin/uv" /opt/homebrew/bin/uv /usr/local/bin/uv "$(command -v uv 2>/dev/null || true)"; do
  [ -n "$c" ] && [ -x "$c" ] && UV="$c" && break
done
if [ -z "$UV" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh >/dev/null
  UV="$HOME/.local/bin/uv"
fi
[ -x "$UV" ] || falha "Não consegui instalar o uv. Verifique a internet e rode de novo."
echo "${ok}✓${fim} uv pronto"

passo "2/5 · FFmpeg (edição de vídeo)"
if [ -z "${GTAVIRAL_FORCE_FFMPEG:-}" ] && [ -x /opt/homebrew/bin/ffmpeg ] && [ -x /opt/homebrew/bin/ffprobe ]; then
  echo "${ok}✓${fim} usando o FFmpeg do Homebrew"
else
  for b in ffmpeg ffprobe; do
    curl -fsSL -o "$TMP/$b.gz" "https://github.com/eugeneware/ffmpeg-static/releases/download/$FFVER/$b-darwin-arm64.gz"
    gunzip -f "$TMP/$b.gz"
  done
  sha_ok "$TMP/ffmpeg" "$FFMPEG_SHA" && sha_ok "$TMP/ffprobe" "$FFPROBE_SHA" || falha "O FFmpeg baixado não confere (download corrompido). Rode de novo."
  install -m 755 "$TMP/ffmpeg" "$TMP/ffprobe" "$DATA/bin/"
  echo "${ok}✓${fim} FFmpeg instalado"
fi

passo "3/5 · Motor do GTAVIral"
curl -fsSL -o "$TMP/SHA256SUMS" "$REL/SHA256SUMS"
curl -fsSL -o "$TMP/gtaviral-engine.tar.gz" "$REL/gtaviral-engine.tar.gz"
(cd "$TMP" && grep " gtaviral-engine.tar.gz$" SHA256SUMS | shasum -a 256 -c - >/dev/null) || falha "O motor baixado não confere. Rode de novo."
rm -rf "$DATA/engine.new"; mkdir -p "$DATA/engine.new"
tar -xzf "$TMP/gtaviral-engine.tar.gz" -C "$DATA/engine.new"
if [ -d "$DATA/engine/tts_worker/.venv" ]; then mv "$DATA/engine/tts_worker/.venv" "$DATA/engine.new/tts_worker/.venv"; fi
rm -rf "$DATA/engine" && mv "$DATA/engine.new" "$DATA/engine"
echo "  preparando o Python do motor (primeira vez leva alguns minutos)…"
"$UV" sync --project "$DATA/engine" --python 3.11 -q || falha "Falha ao preparar o motor. Rode de novo; se repetir, veja a seção Problemas do guia."
echo "${ok}✓${fim} motor pronto"

passo "4/5 · Voz local grátis (opcional)"
if [ "$VOZ_LOCAL" = 1 ]; then
  echo "  baixando a voz Chatterbox (~3 GB)…"
  "$UV" sync --project "$DATA/engine/tts_worker" --python 3.11 -q || echo "  aviso: a voz local não instalou; o app usa a voz rápida (Kokoro) ou a ElevenLabs."
  echo "${ok}✓${fim} voz local instalada"
else
  echo "  pulado (use --voz-local para instalar; com ElevenLabs não precisa)"
fi

passo "5/5 · Aplicativo"
if [ "$SEM_APP" = 1 ]; then
  echo "  pulado (--sem-app)"
else
  curl -fsSL -o "$TMP/GTAVIral-mac-arm64.zip" "$REL/GTAVIral-mac-arm64.zip"
  (cd "$TMP" && grep " GTAVIral-mac-arm64.zip$" SHA256SUMS | shasum -a 256 -c - >/dev/null) || falha "O aplicativo baixado não confere. Rode de novo."
  DEST="/Applications"; [ -w "$DEST" ] || DEST="$HOME/Applications"; mkdir -p "$DEST"
  osascript -e 'quit app "GTAVIral"' >/dev/null 2>&1 || true
  rm -rf "$DEST/GTAVIral.app"
  ditto -x -k "$TMP/GTAVIral-mac-arm64.zip" "$DEST"
  xattr -dr com.apple.quarantine "$DEST/GTAVIral.app" 2>/dev/null || true
  echo "${ok}✓${fim} GTAVIral instalado em $DEST"
fi

printf "\n%s✔ Pronto!%s Abra o GTAVIral (Launchpad ou Aplicativos). Na primeira abertura ele baixa os modelos de IA.\n" "$ok" "$fim"
[ "$SEM_APP" = 1 ] || open -a "$DEST/GTAVIral.app" || true
