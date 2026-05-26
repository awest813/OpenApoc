#!/usr/bin/env bash
# tools/macos-run.sh
#
# Launch OpenApoc from the correct working directory so that the game
# can find its data files (data/, mods/, etc.) regardless of where this
# script is called from.
#
# Usage:
#   bash tools/macos-run.sh            # auto-detect architecture / preset
#   bash tools/macos-run.sh arm64      # force Apple Silicon preset
#   bash tools/macos-run.sh x86_64    # force Intel preset
#
# Extra arguments are forwarded to the OpenApoc binary, e.g.:
#   bash tools/macos-run.sh arm64 --loglevel=debug

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info() { printf '\033[1;34m[run]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[run]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Locate repo root
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Architecture / preset selection
# ---------------------------------------------------------------------------
HOST_ARCH="$(uname -m)"

if [[ "${1:-}" == "arm64" || "${1:-}" == "x86_64" ]]; then
    ARCH="$1"
    shift
else
    ARCH="$HOST_ARCH"
fi

CMAKE_PRESET="macos-${ARCH}"
BUILD_DIR="$REPO_ROOT/build/$CMAKE_PRESET"

# ---------------------------------------------------------------------------
# Locate the executable
# ---------------------------------------------------------------------------
# CMake preset builds place the binary under build/<preset>/bin/
APP_BUNDLE="$BUILD_DIR/bin/OpenApoc.app"
LEGACY_BUNDLE="$REPO_ROOT/build/bin/OpenApoc.app"

if [[ -d "$APP_BUNDLE" ]]; then
    EXEC="$APP_BUNDLE/Contents/MacOS/OpenApoc"
elif [[ -d "$LEGACY_BUNDLE" ]]; then
    # Fallback: manual cmake build into build/
    EXEC="$LEGACY_BUNDLE/Contents/MacOS/OpenApoc"
    BUILD_DIR="$REPO_ROOT/build"
    warn() { printf '\033[1;33m[run]\033[0m %s\n' "$*" >&2; }
    warn "Using legacy build at $LEGACY_BUNDLE"
else
    die "OpenApoc.app not found. Run 'bash tools/macos-setup.sh' first."
fi

if [[ ! -x "$EXEC" ]]; then
    die "Executable not found inside app bundle: $EXEC"
fi

# ---------------------------------------------------------------------------
# Data check (advisory only)
# ---------------------------------------------------------------------------
if [[ ! -f "$REPO_ROOT/data/cd.iso" ]]; then
    info "Warning: data/cd.iso not found — the game will start but may fail to load assets."
    info "Copy your X-Com: Apocalypse disc image to $REPO_ROOT/data/cd.iso"
fi

# ---------------------------------------------------------------------------
# Launch from repo root so relative data paths resolve correctly
# ---------------------------------------------------------------------------
info "Launching OpenApoc from $REPO_ROOT …"
cd "$REPO_ROOT"
exec "$EXEC" "$@"
