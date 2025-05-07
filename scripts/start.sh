#!/usr/bin/env bash
set -euo pipefail

echo "==> Removing stale Xvfb lock (if any)"
[ -f /tmp/.X99-lock ] && rm -f /tmp/.X99-lock

echo "==> Starting Xvfb on :99"
Xvfb :99 -screen 0 1920x1080x24 &
sleep 2

echo "==> Launching LM Studio GUI"
/opt/lmstudio/squashfs/lm-studio --no-sandbox &
sleep 20

# Определяем путь к CLI (новый и старый варианта)
CLI="$HOME/.cache/lm-studio/bin/lms"
if [ ! -x "$CLI" ]; then
  CLI="$HOME/.lmstudio/bin/lms"
fi

echo "==> Bootstrapping CLI (if нужно)"
# Bootstrap не падает, если уже был выполнен
printf "y\n" | "$CLI" bootstrap || true

if [ ! -x "${HOME}/.cache/lm-studio/bin/lms" ]; then
  echo "ERROR: lms не найден после bootstrap" >&2
  exit 1
fi
CLI="${HOME}/.cache/lm-studio/bin/lms"

echo "==> Starting API server via lms"
"$CLI" server start --cors &
sleep 5

# Если указана модель, загружаем её
if [ -n "${MODEL_PATH:-}" ]; then
  echo "==> Loading model ${MODEL_PATH}"
  "$CLI" load \
    --gpu max \
    --context-length "${CONTEXT_LENGTH:-4096}" \
    "${MODEL_PATH}"
  sleep 10
fi

echo "==> Applying HTTP-server config"
mkdir -p "$HOME/.cache/lm-studio/.internal"
cp -f /opt/lmstudio/http-server-config.json \
      "$HOME/.cache/lm-studio/.internal/http-server-config.json"

echo "==> Starting x11vnc on :99"
x11vnc \
  -display :99 \
  -forever \
  -rfbauth /root/.vnc/passwd \
  -quiet \
  -listen 0.0.0.0 \
  -xkb &

echo "==> All services started — dropping to shell"

${CLI} log stream
