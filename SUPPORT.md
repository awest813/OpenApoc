# OpenApoc macOS Support

This fork targets macOS as a first-class platform, with Apple Silicon as the
primary target and Intel as a secondary (best-effort) target.

## Support Tiers

| Platform | Architecture | macOS versions | Status |
|---|---|---|---|
| Apple Silicon | ARM64 (arm64) | 14 Sonoma, 15 Sequoia | **Primary** — CI-tested on every push |
| Intel Mac | x86\_64 | 13 Ventura | **Secondary** — CI-tested on every push, best-effort |

### Primary (Apple Silicon)

* CI runs on `macos-15` (GitHub-hosted Apple Silicon runner).
* All regressions on this platform are treated as blocking issues.
* Releases are tested and signed for this platform.

### Secondary (Intel)

* CI runs on `macos-13` (last GitHub-hosted Intel runner).
* Regressions are addressed on a best-effort basis and are not blocking for
  releases.
* Intel support may be dropped in a future release as Apple's transition to
  Apple Silicon is complete and GitHub's Intel macOS runners are being retired.

## Build Requirements

| Tool / Library | Minimum version | Install |
|---|---|---|
| Xcode Command Line Tools | 15 | `xcode-select --install` |
| CMake | 3.30 | `brew install cmake` |
| Ninja | any | `brew install ninja` |
| SDL2 | 2.x | `brew install sdl2` |
| Boost | 1.80+ | `brew install boost` |
| libvorbis | any | `brew install libvorbis` |
| Qt 6 *(launcher only)* | 6.x | `brew install qt@6` |

## Known Limitations

* OpenGL is deprecated on macOS since 10.14 Mojave; the project uses the
  compatibility path via `GL_ARB_ES3_compatibility`.  Metal/MoltenVK support is
  a future goal.
* macOS sandbox restrictions may require running the app bundle from the correct
  working directory; the framework handles this automatically via `SDL_GetBasePath`.

## Roadmap

### Short-term — "Builds reliably"
- [x] macOS CI (ARM64 + x86\_64) on every push / PR
- [x] Replace deprecated NS\* OpenGL symbol APIs with modern `dlopen`/`dlsym`
- [x] Remove obsolete `BROKEN_THREAD_LOCAL` workaround
- [ ] Resolve any remaining Clang/AppleClang compiler warnings
- [ ] Confirm test suite passes on both architectures

### Mid-term — "Stable release"
- [ ] App bundle code signing and notarization documentation
- [ ] Performance profiling on Apple Silicon
- [ ] Automated smoke tests in CI (headless render check)

### Long-term — Modernization
- [ ] Evaluate Metal/MoltenVK rendering backend
- [ ] Universal Binary (`lipo` ARM64 + x86\_64) release artifact
- [ ] Homebrew formula or cask for easy installation
