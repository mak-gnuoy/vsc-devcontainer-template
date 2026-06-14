#!/bin/bash
# Shared Linux distribution detection for docker/scripts/*.sh.
#
# Source this file, then call detect_distro. On success it exports:
#   DISTRO_FAMILY : "debian" | "rhel"
#   PKG_MGR       : "apt-get" | "dnf" | "yum"
#
# Detection uses the freedesktop /etc/os-release standard — the ID field plus
# ID_LIKE — so derivatives (Linux Mint, Rocky, AlmaLinux, Oracle Linux, ...)
# resolve to the right family without enumerating every distro by name.
#
# detect_distro returns non-zero (instead of exiting) when the OS cannot be
# identified, so each caller decides whether that is fatal:
#
#   detect_distro || exit 1                 # hard requirement
#   detect_distro || { echo skip; ...; }    # best-effort

detect_distro() {
    if [ ! -r /etc/os-release ]; then
        echo "ERROR: /etc/os-release not found; cannot detect Linux distribution." >&2
        return 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    # Wrap ID + ID_LIKE in spaces so we can match whole words; ID_LIKE may hold
    # several space-separated families (e.g. "rhel centos fedora").
    case " ${ID:-} ${ID_LIKE:-} " in
        *" debian "*|*" ubuntu "*)
            DISTRO_FAMILY="debian"
            PKG_MGR="apt-get"
            ;;
        *" rhel "*|*" fedora "*|*" centos "*)
            DISTRO_FAMILY="rhel"
            if command -v dnf >/dev/null 2>&1; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            ;;
        *)
            echo "ERROR: unsupported Linux distribution (ID=${ID:-unknown}, ID_LIKE=${ID_LIKE:-none})." >&2
            return 1
            ;;
    esac

    export DISTRO_FAMILY PKG_MGR
}
