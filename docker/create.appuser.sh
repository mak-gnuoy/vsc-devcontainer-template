#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME="$1"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ $ID == "rhel" || $ID == "centos" || $ID == "fedora" || $ID_LIKE =~ "rhel" ]]; then
        # Red Hat 계열
        useradd -u 5678 -m -s /bin/bash "$USERNAME"
    elif [[ $ID == "debian" || $ID == "ubuntu" || $ID_LIKE =~ "debian" ]]; then
        # Debian 계열
        adduser -u 5678 --disabled-password --gecos "" "$USERNAME"
    else
        echo "Unsupported OS: $ID"
        exit 1
    fi
else
    echo "/etc/os-release not found"
    exit 1
fi

