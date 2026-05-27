#!/usr/bin/env bash
# tools/macos-setup.sh
#
# One-command setup for OpenApoc on macOS (Apple Silicon and Intel).
# Usage:
#   bash tools/macos-setup.sh            # auto-detect architecture
#   bash tools/macos-setup.sh arm64      # force Apple Silicon (M1/M2/M3/M4)
#   bash tools/macos-setup.sh x86_64    # force Intel
#
# What it does:
#   1. Checks for Xcode Command Line Tools
#   2. Installs / verifies Homebrew dependencies
#   3. Updates git submodules
#   4. Configures + builds via the correct CMake preset
#   5. Verifies the resulting app bundle is runnable
#
# After this script succeeds, run the game with:
#   bash tools/macos-run.sh
#
# Troubleshooting:
#   brew not found    → install from https://brew.sh then re-run
#   No C++ compiler   → run: xcode-select --install  then re-run
#   Missing cd.iso    → copy your disc image to data/cd.iso
#   Gatekeeper block  → run: xattr -dr com.apple.quarantine <app-bundle-path>

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m[setup]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[setup]\033[0m %s\n' "$*" >&2; }
die()     { printf '\033[1;31m[setup]\033[0m ERROR: %s\n' "$*" >&2; exit 1; }

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
info "Target architecture : $ARCH (${HOST_ARCH} host)"
info "CMake preset        : $CMAKE_PRESET"
if [[ "$ARCH" != "$HOST_ARCH" ]]; then
    warn "Cross-compiling for $ARCH on a $HOST_ARCH host — libraries must match the target arch."
fi

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
    warn "Xcode Command Line Tools not found."
    info "Launching installer — re-run this script after the installation completes:"
    info "  xcode-select --install"
    xcode-select --install 2>/dev/null || true
    die "Re-run this script after the installation completes."
fi
success "Xcode Command Line Tools OK ($(xcode-select -p))"

# ---------------------------------------------------------------------------
# 2. Homebrew
# ---------------------------------------------------------------------------
info "Checking for Homebrew at $BREW_PREFIX …"
BREW="${BREW_PREFIX}/bin/brew"
if [[ ! -x "$BREW" ]]; then
    warn "Homebrew not found at $BREW_PREFIX."
    if [[ "$ARCH" == "arm64" ]]; then
        warn "Apple Silicon Macs use /opt/homebrew as the Homebrew prefix."
    else
        warn "Intel Macs use /usr/local as the Homebrew prefix."
    fi
    info "Install Homebrew by running:"
    info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    info "Then re-run this script."
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
# 7. Post-build verification
# ---------------------------------------------------------------------------
BUILD_DIR="$REPO_ROOT/build/$CMAKE_PRESET"
APP_BUNDLE="$BUILD_DIR/bin/OpenApoc.app"
EXEC="$APP_BUNDLE/Contents/MacOS/OpenApoc"

info "Verifying app bundle …"
if [[ ! -d "$APP_BUNDLE" ]]; then
    die "App bundle not found at $APP_BUNDLE — build may have failed."
fi
if [[ ! -x "$EXEC" ]]; then
    die "Executable not found or not runnable inside app bundle: $EXEC"
fi

# Verify all dynamically linked libraries are resolvable.
# `otool -L` lists them; DYLD_PRINT_LIBRARIES would require a running process.
if command -v otool &>/dev/null; then
    MISSING_LIBS=0
    while IFS= read -r line; do
        lib_path="$(echo "$line" | awk '{print $1}')"
        # Skip system frameworks and @rpath / @executable_path / @loader_path entries
        if [[ "$lib_path" == /System/* || "$lib_path" == /usr/lib/* || "$lib_path" == @* ]]; then
            continue
        fi
        if [[ ! -f "$lib_path" ]]; then
            warn "Linked library not found on disk: $lib_path"
            MISSING_LIBS=1
        fi
    done < <(otool -L "$EXEC" | tail -n +2)
    if [[ "$MISSING_LIBS" -eq 1 ]]; then
        warn "Some linked libraries could not be verified — the game may fail to start."
        warn "Try running: bash tools/macos-run.sh"
    else
        success "Library links OK"
    fi
fi

# Quick start-up probe: run with --help (exits before SDL/display init).
# A crash here (SIGSEGV etc.) would return exit code > 1.
info "Running startup probe (--help) …"
set +e
"$EXEC" --help >/dev/null 2>&1
PROBE_EXIT=$?
set -e
if [[ "$PROBE_EXIT" -eq 1 ]]; then
    # EXIT_FAILURE from --help is normal (parseOptions returns true → EXIT_FAILURE)
    success "Startup probe passed (binary launches and exits cleanly)"
elif [[ "$PROBE_EXIT" -eq 0 ]]; then
    success "Startup probe passed"
else
    warn "Startup probe exited with code $PROBE_EXIT (may indicate a crash or missing library)."
    warn "Try running 'bash tools/macos-run.sh' and check the output for errors."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
success "Build complete!"
echo ""
echo "  App bundle : $APP_BUNDLE"
echo ""
if [[ ! -f "$REPO_ROOT/data/cd.iso" ]]; then
    echo "  ⚠  Game data not found. Copy your disc image before running:"
    echo "       cp /path/to/cd.iso \"$REPO_ROOT/data/\""
    echo ""
fi
echo "To run the game:"
echo "  bash \"$SCRIPT_DIR/macos-run.sh\""
echo ""
echo "Architecture override (if needed):"
echo "  bash \"$SCRIPT_DIR/macos-setup.sh\" arm64    # Apple Silicon (M1/M2/M3/M4)"
echo "  bash \"$SCRIPT_DIR/macos-setup.sh\" x86_64   # Intel"
