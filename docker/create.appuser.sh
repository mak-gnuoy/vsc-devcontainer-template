#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <username> <app_path>"
    exit 1
fi

USERNAME="$1"
APP_PATH="$2"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ $ID == "rhel" || $ID == "centos" || $ID == "fedora" || $ID_LIKE =~ "rhel" ]]; then
        # Red Hat family
        useradd -u 5678 -m -s /bin/bash "$USERNAME" && chown -R "$USERNAME" "$APP_PATH"
    elif [[ $ID == "debian" || $ID == "ubuntu" || $ID_LIKE =~ "debian" ]]; then
        # Debian family
        adduser -u 5678 --disabled-password --gecos "" "$USERNAME" && chown -R "$USERNAME" "$APP_PATH"
    else
        echo "Unsupported OS: $ID"
        exit 1
    fi
else
    echo "/etc/os-release not found"
    exit 1
fi