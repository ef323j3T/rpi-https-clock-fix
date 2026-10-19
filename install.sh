
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="rpi-https-clock-fix"
SERVICE_NAME="rpi-https-clock-fix.service"
TIMER_NAME="rpi-https-clock-fix.timer"

SCRIPT_DEST="/usr/local/sbin/${SCRIPT_NAME}"
SYSTEMD_DIR="/etc/systemd/system"
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$EUID" -ne 0 ]]; then
    echo "Run with sudo: sudo ./install.sh" >&2
    exit 1
fi

for cmd in systemctl install; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Required command not found: $cmd" >&2
        exit 1
    }
done

[[ -f "$REPO_DIR/$SCRIPT_NAME" ]] ||
    { echo "Missing $SCRIPT_NAME in repository." >&2; exit 1; }

[[ -f "$REPO_DIR/$SERVICE_NAME" ]] ||
    { echo "Missing $SERVICE_NAME in repository." >&2; exit 1; }

[[ -f "$REPO_DIR/$TIMER_NAME" ]] ||
    { echo "Missing $TIMER_NAME in repository." >&2; exit 1; }

bash -n "$REPO_DIR/$SCRIPT_NAME"

grep -Fq "ExecStart=$SCRIPT_DEST" "$REPO_DIR/$SERVICE_NAME" ||
    { echo "Service ExecStart path doesn't match." >&2; exit 1; }

grep -Fq "Unit=$SERVICE_NAME" "$REPO_DIR/$TIMER_NAME" ||
    { echo "Timer service reference doesn't match." >&2; exit 1; }

install -o root -g root -m 755 \
    "$REPO_DIR/$SCRIPT_NAME" "$SCRIPT_DEST"

install -o root -g root -m 644 \
    "$REPO_DIR/$SERVICE_NAME" "$SYSTEMD_DIR/$SERVICE_NAME"

install -o root -g root -m 644 \
    "$REPO_DIR/$TIMER_NAME" "$SYSTEMD_DIR/$TIMER_NAME"

systemctl daemon-reload
systemctl enable --now "$TIMER_NAME"

echo "Installed and enabled $TIMER_NAME."
echo "Running an initial check..."
systemctl start "$SERVICE_NAME" || {
    echo "WARNING: Initial check failed; inspect the service logs."
}

systemctl status "$TIMER_NAME" --no-pager
journalctl -u "$SERVICE_NAME" -n 10 --no-pager || true
