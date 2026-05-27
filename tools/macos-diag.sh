#!/usr/bin/env bash
# tools/macos-diag.sh
#
# Collect macOS environment diagnostics for OpenApoc bug reports.
# Run this script and paste the output into a GitHub issue or Discord message.
#
# Usage:
#   bash tools/macos-diag.sh            # auto-detect architecture
#   bash tools/macos-diag.sh arm64      # force Apple Silicon preset
#   bash tools/macos-diag.sh x86_64    # force Intel preset

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOST_ARCH="$(uname -m)"
if [[ "${1:-}" == "arm64" || "${1:-}" == "x86_64" ]]; then
    ARCH="$1"
else
    ARCH="$HOST_ARCH"
fi
PRESET="macos-${ARCH}"

echo "=== OpenApoc macOS Diagnostics ==="
echo "Paste everything below this line into your bug report."
echo "-------------------------------------------------------"
echo ""
echo "## System"
echo "Architecture : $(uname -m)"
echo "macOS version:"
sw_vers 2>/dev/null || echo "  (sw_vers not found)"
echo ""

echo "## Toolchain"
echo "Xcode path   : $(xcode-select -p 2>/dev/null || echo 'NOT FOUND — run: xcode-select --install')"
clang --version 2>/dev/null | head -1 || echo "clang        : NOT FOUND"
echo ""

echo "## Homebrew"
if command -v brew &>/dev/null; then
    echo "brew         : $(brew --version | head -1)"
    echo "brew prefix  : $(brew --prefix)"
    for pkg in cmake ninja sdl2 boost libvorbis; do
        version="$(brew list --versions "$pkg" 2>/dev/null || echo 'NOT INSTALLED')"
        printf "  %-12s %s\n" "$pkg" "$version"
    done
else
    echo "brew         : NOT FOUND"
    echo "Install from https://brew.sh then re-run."
fi
echo ""

echo "## CMake"
cmake --version 2>/dev/null | head -1 || echo "cmake        : NOT FOUND"
echo ""

echo "## Build"
APP_BUNDLE="$REPO_ROOT/build/$PRESET/bin/OpenApoc.app"
EXEC="$APP_BUNDLE/Contents/MacOS/OpenApoc"
echo "Preset       : $PRESET"
echo "App bundle   : $APP_BUNDLE"
if [[ -d "$APP_BUNDLE" ]]; then
    echo "Bundle found : YES"
    if [[ -x "$EXEC" ]]; then
        echo "Executable   : YES"
        if command -v otool &>/dev/null; then
            echo ""
            echo "## Dynamic library links"
            otool -L "$EXEC" 2>/dev/null || echo "  (otool failed)"
        fi
    else
        echo "Executable   : NOT FOUND inside bundle"
    fi
else
    echo "Bundle found : NO — run: bash tools/macos-setup.sh"
fi
echo ""

echo "## Git"
git -C "$REPO_ROOT" log --oneline -1 2>/dev/null || echo "git log      : NOT AVAILABLE"
git -C "$REPO_ROOT" submodule status 2>/dev/null | head -10 || true
echo ""

echo "-------------------------------------------------------"
echo "End of diagnostics."
