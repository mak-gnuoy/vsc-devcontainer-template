#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <username> <app_path>"
    exit 1
fi

USERNAME="$1"
APP_PATH="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.distro.sh
. "${SCRIPT_DIR}/lib.distro.sh"
detect_distro || exit 1

case "$DISTRO_FAMILY" in
    rhel)
        useradd -u 5678 -m -s /bin/bash "$USERNAME" && chown -R "$USERNAME" "$APP_PATH"
        ;;
    debian)
        adduser -u 5678 --disabled-password --gecos "" "$USERNAME" && chown -R "$USERNAME" "$APP_PATH"
        ;;
esac