#!/bin/sh

# Initializes a SafeNet HSM if it is present.

set -eu

log() {
    echo "$@"
}

translate_windows_path() {
    if [ -n "${WSL_DISTRO_NAME-}" ]; then
        wslpath "$1"
    else
        printf '%s' "$1" | tr "\\\\" '/'
    fi
}

trim_dir_end_char() {
    printf '%s\n' "$1" | awk '{ sub(/[\/]$/, ""); print }'
}

get_arch() {
    case "$(uname -m)" in
    i?86)
        echo x32
        ;;
    x86_64)
        echo x64
        ;;
    aarch64 | arm64)
        echo arm64
        ;;
    *)
        echo "Unable to determine machine architecture." >&2
        return 1
        ;;
    esac
}

run_on_windows() {
    AUTH_INSTALL_DIR=$(reg.exe query 'HKLM\SOFTWARE\SafeNet\Authentication' -v 'Path' 2>/dev/null |
        tr -d '\r' |
        awk -F'    ' '/Path/ {print $NF}')
    if [ -z "$AUTH_INSTALL_DIR" ]; then
        return 0
    fi

    SAC_INSTALL_DIR="$(trim_dir_end_char "$(translate_windows_path "$AUTH_INSTALL_DIR")")/SAC"
    if ! [ -d "$SAC_INSTALL_DIR" ]; then
        return 0
    fi

    log "HSM: SafeNet Authentication Client (SAC) is installed at '$SAC_INSTALL_DIR'."

    SAC_BIN_DIR="$SAC_INSTALL_DIR/$(get_arch)"
    SAC_MONITOR_PATH="$SAC_BIN_DIR/SACMonitor.exe"

    if [ -f "$SAC_MONITOR_PATH" ]; then
        log "HSM: launching SAC Monitor to propagate HSM certificates to a certificate store."
        exec "$SAC_MONITOR_PATH" </dev/null >/dev/null 2>&1 &
    fi
}

case $(uname -o) in
Cygwin | Msys | MS/Windows)
    # Windows
    run_on_windows
    ;;
*) ;;
esac
