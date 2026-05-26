#!/usr/bin/env bash
# tools/macos-setup.sh
#
# One-command setup for OpenApoc on macOS (Apple Silicon and Intel).
# Usage:
#   bash tools/macos-setup.sh            # auto-detect architecture
#   bash tools/macos-setup.sh arm64      # force Apple Silicon preset
#   bash tools/macos-setup.sh x86_64    # force Intel preset
#
# What it does:
#   1. Checks for Xcode Command Line Tools
#   2. Installs / verifies Homebrew dependencies
#   3. Updates git submodules
#   4. Configures + builds via the correct CMake preset
#
# After this script succeeds, run the game with:
#   bash tools/macos-run.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m[setup]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[setup]\033[0m %s\n' "$*" >&2; }
die()     { printf '\033[1;31m[setup]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Locate the repo root (script may be invoked from any directory)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Detect / select architecture and CMake preset
# ---------------------------------------------------------------------------
HOST_ARCH="$(uname -m)"  # arm64 or x86_64

REQUESTED_ARCH="${1:-}"
if [[ -n "$REQUESTED_ARCH" ]]; then
    case "$REQUESTED_ARCH" in
        arm64|x86_64) ARCH="$REQUESTED_ARCH" ;;
        *) die "Unknown architecture '$REQUESTED_ARCH'. Use 'arm64' or 'x86_64'." ;;
    esac
else
    ARCH="$HOST_ARCH"
fi

CMAKE_PRESET="macos-${ARCH}"
info "Target architecture : $ARCH"
info "CMake preset        : $CMAKE_PRESET"

# ---------------------------------------------------------------------------
# Homebrew prefix (differs between Apple Silicon and Intel)
# ---------------------------------------------------------------------------
if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools
# ---------------------------------------------------------------------------
info "Checking for Xcode Command Line Tools …"
if ! xcode-select -p &>/dev/null; then
    warn "Xcode Command Line Tools not found. Launching installer …"
    xcode-select --install
    die "Re-run this script after the installation completes."
fi
success "Xcode Command Line Tools OK"

# ---------------------------------------------------------------------------
# 2. Homebrew
# ---------------------------------------------------------------------------
info "Checking for Homebrew at $BREW_PREFIX …"
BREW="${BREW_PREFIX}/bin/brew"
if [[ ! -x "$BREW" ]]; then
    warn "Homebrew not found at $BREW_PREFIX."
    info "Install Homebrew from https://brew.sh and then re-run this script."
    if [[ "$ARCH" == "arm64" ]]; then
        info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
        info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
    die "Homebrew required."
fi
success "Homebrew found at $BREW"

# ---------------------------------------------------------------------------
# 3. Dependencies
# ---------------------------------------------------------------------------
DEPS=(cmake ninja boost sdl2 libvorbis pkg-config)

info "Installing / verifying Homebrew dependencies: ${DEPS[*]}"
"$BREW" install "${DEPS[@]}"

# Qt is optional (only needed for the launcher)
if [[ "${OPENAPOC_BUILD_LAUNCHER:-0}" == "1" ]]; then
    info "OPENAPOC_BUILD_LAUNCHER=1 — installing qt@6 …"
    "$BREW" install qt@6
fi

success "Homebrew dependencies OK"

# ---------------------------------------------------------------------------
# 4. Git submodules
# ---------------------------------------------------------------------------
info "Updating git submodules …"
cd "$REPO_ROOT"
git submodule update --init --recursive
success "Submodules OK"

# ---------------------------------------------------------------------------
# 5. cd.iso reminder (non-blocking)
# ---------------------------------------------------------------------------
if [[ ! -f "$REPO_ROOT/data/cd.iso" ]]; then
    warn "data/cd.iso not found."
    warn "Copy your X-Com: Apocalypse disc image to data/cd.iso before running the game:"
    warn "  cp /path/to/cd.iso \"$REPO_ROOT/data/\""
    warn "(Build will proceed; game data extraction is automatically disabled until cd.iso is present.)"
fi

# ---------------------------------------------------------------------------
# 6. CMake configure + build
# ---------------------------------------------------------------------------
info "Configuring with preset '$CMAKE_PRESET' …"
cmake --preset "$CMAKE_PRESET" -S "$REPO_ROOT"

info "Building …"
cmake --build --preset "$CMAKE_PRESET" --parallel

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
BUILD_DIR="$REPO_ROOT/build/$CMAKE_PRESET"
success "Build complete!"
echo ""
echo "  App bundle : $BUILD_DIR/bin/OpenApoc.app"
echo ""
echo "To run the game:"
echo "  bash \"$SCRIPT_DIR/macos-run.sh\""
echo ""
echo "Remember to place your cd.iso in $REPO_ROOT/data/ if you haven't already."
