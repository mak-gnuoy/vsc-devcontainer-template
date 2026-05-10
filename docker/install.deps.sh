#!/bin/bash
set -e

if [ -f /etc/os-release ]; then
    source /etc/os-release
    case "$ID" in
        debian|ubuntu|linuxmint)
            apt-get update && apt-get install -y \
                ca-certificates \
                curl \
                bash \
                git \
                nodejs npm \
                zstd \
                && rm -rf /var/lib/apt/lists/*
            ;;
        rhel|centos|fedora|rocky|almalinux|ol)
            if command -v dnf >/dev/null 2>&1; then
                pkg_mgr=dnf
            else
                pkg_mgr=yum
            fi
            "$pkg_mgr" install -y \
                ca-certificates \
                curl \
                bash \
                git \
                nodejs npm \
                zstd 
            ;;
        *)
            echo "Unsupported OS: $ID"
            exit 1
            ;;
    esac
else
    echo "/etc/os-release not found"
    exit 1
fi
