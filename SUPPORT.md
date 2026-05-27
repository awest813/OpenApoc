# OpenApoc macOS Support

This fork targets macOS as a first-class platform, with Apple Silicon as the
primary target and Intel as a secondary (best-effort) target. Windows and Linux
remain upstream compatibility concerns and are not release-blocking for this
fork.

## Quick start

```sh
git clone https://github.com/awest813/OpenApoc.git
cd OpenApoc
bash tools/macos-setup.sh   # installs deps, configures, and builds
# …copy data/cd.iso…
bash tools/macos-run.sh     # launches from the correct working directory
```

See [README.md §Building on macOS](README.md#building-on-macos) for full
instructions including manual CMake preset usage and troubleshooting.

## Support Tiers

| Tier | Platform | Architecture | macOS versions | Status |
|---|---|---|---|---|
| Tier 1 | Apple Silicon | ARM64 (arm64) | 14 Sonoma, 15 Sequoia | **Primary** — CI-tested on every push |
| Tier 2 | Intel Mac | x86\_64 | 13 Ventura | **Secondary** — CI-tested on every push while runners are available, best-effort |
| Out of scope | Windows / Linux | n/a | n/a | Upstream compatibility only |

### Primary (Apple Silicon)

* CI runs on `macos-15` (GitHub-hosted Apple Silicon runner).
* All regressions on this platform are treated as blocking issues.
* Tagged releases publish a pre-built app bundle for this platform.

### Secondary (Intel)

* CI runs on `macos-13` (last GitHub-hosted Intel runner).
* Regressions are addressed on a best-effort basis and are not blocking for
  releases.
* Intel support may be dropped in a future release as Apple's transition to
  Apple Silicon is complete and GitHub's Intel macOS runners are being retired.

### Windows / Linux

* This fork does not publish Windows or Linux release artifacts.
* Non-mac build checks are manual, non-blocking upstream compatibility checks.
* Windows and Linux fixes are welcome when they do not weaken the macOS-first
  support contract.

## Governance

See [`APPLE_SILICON_INTEL_FORK.md`](APPLE_SILICON_INTEL_FORK.md) for the full
fork policy, QA matrix, CI/CD policy, release requirements, and Intel
deprecation playbook.

### Branch protection expectation

The `macOS` GitHub Actions workflow should be the required merge and release
gate for this fork. Apple Silicon failures block merges and releases. Intel
failures should be investigated, but may be waived for release if the issue is
Intel-only, low-impact, or caused by hosted runner retirement.

### Intel deprecation triggers

Intel release artifacts should be reassessed if any of the following occur:

1. GitHub-hosted `macos-13` Intel runners are retired.
2. No trusted self-hosted Intel runner is available.
3. Intel-only defects require invasive changes that risk Apple Silicon stability.
4. Intel usage and issue volume no longer justify release maintenance.

If Intel release artifacts are removed, keep source-build notes for one release
cycle and announce the change in release notes.

## Build Requirements

| Tool / Library | Minimum version | Install |
|---|---|---|
| Xcode Command Line Tools | 15 | `xcode-select --install` |
| CMake | 3.30 | `brew install cmake` |
| Ninja | any | `brew install ninja` |
| SDL2 | 2.x | `brew install sdl2` |
| Boost | 1.80+ | `brew install boost` |
| libvorbis | any | `brew install libvorbis` |
| Qt 6 *(launcher only, optional)* | 6.x | `brew install qt@6` |

> **Homebrew prefixes:** Apple Silicon uses `/opt/homebrew`; Intel uses `/usr/local`.
> The setup script and CMake presets handle this automatically.

## CMake Presets

The repository ships [`CMakePresets.json`](CMakePresets.json) with three macOS
presets:

| Preset | Use |
|---|---|
| `macos-arm64` | Apple Silicon dev build (RelWithDebInfo) |
| `macos-x86_64` | Intel dev build (RelWithDebInfo) |
| `macos-universal` | Release-optimised universal binary (arm64 + x86_64) |

```sh
cmake --preset macos-arm64 && cmake --build --preset macos-arm64
```

Universal binaries are release-oriented validation artifacts. Routine CI and
user downloads use separate per-architecture builds so dependency and runtime
issues are easier to diagnose.

## QA Matrix

| Check | Apple Silicon | Intel |
|---|---|---|
| Configure/build via CMake preset | Required | Required while runners exist |
| Unit tests via `ctest` | Required | Required while runners exist |
| App bundle structure check | Required | Required |
| Startup probe (`--help`) | Required | Required |
| Game data load smoke | Required before stable release | Best-effort |
| Rendering/audio/save-load smoke | Required before stable release | Best-effort |
| Performance profiling | Required before stable release | Optional |

## Issue Triage

macOS bugs should use the macOS issue template and include:

```sh
bash tools/macos-diag.sh
```

Use labels consistently when triaging:

* `platform:macos`
* `arch:arm64`
* `arch:x86_64`

Apple Silicon correctness bugs are release-blocking unless explicitly accepted
as known issues. Intel-only bugs are evaluated by impact, implementation risk,
and runner availability.

## Known Limitations

* OpenGL is deprecated on macOS since 10.14 Mojave; the project uses the
  compatibility path via `GL_ARB_ES3_compatibility`.  Metal/MoltenVK support is
  a future goal.
* macOS sandbox restrictions may require running the app bundle from the correct
  working directory; `tools/macos-run.sh` handles this automatically.
* App bundles built locally are unsigned and may be blocked by Gatekeeper.
  Right-click → Open, or run:
  ```sh
  xattr -dr com.apple.quarantine build/macos-arm64/bin/OpenApoc.app
  ```

## Gatekeeper & Code Signing

Apps distributed outside the Mac App Store must be **signed** (with an Apple
Developer ID) and **notarized** (submitted to Apple's scan service) to bypass
Gatekeeper without user intervention.

### Current state

All builds — including CI artifacts and tagged releases — are **unsigned**.
First launch therefore triggers a Gatekeeper warning ("app is damaged" or
"developer cannot be verified").

### Workaround for unsigned builds

```sh
# Strip the quarantine flag that macOS attaches when a file is downloaded:
xattr -dr com.apple.quarantine /path/to/OpenApoc.app

# Or right-click the .app → Open → click Open in the security dialog.
```

### Future: signing & notarization roadmap

1. Obtain an Apple Developer Program membership (~$99/year).
2. Create a **Developer ID Application** certificate in Xcode / Keychain.
3. Sign the app bundle:
   ```sh
   codesign --deep --force --options runtime \
     --sign "Developer ID Application: <Name> (<TeamID>)" \
     build/macos-arm64/bin/OpenApoc.app
   ```
4. Notarize with `notarytool`:
   ```sh
   xcrun notarytool submit OpenApoc-macOS-apple-silicon.zip \
     --apple-id "<email>" --team-id "<TeamID>" \
     --password "<app-specific-password>" --wait
   ```
5. Staple the notarization ticket:
   ```sh
   xcrun stapler staple build/macos-arm64/bin/OpenApoc.app
   ```

Once notarized, users can launch the app without any quarantine workaround.

## Roadmap

### Short-term — "Builds reliably"
- [x] macOS CI (ARM64 + x86\_64) on every push / PR
- [x] Replace deprecated NS\* OpenGL symbol APIs with modern `dlopen`/`dlsym`
- [x] Remove obsolete `BROKEN_THREAD_LOCAL` workaround
- [x] One-command setup script (`tools/macos-setup.sh`)
- [x] One-command run script (`tools/macos-run.sh`)
- [x] One-command diagnostics script (`tools/macos-diag.sh`)
- [x] CMake presets for arm64, x86\_64, and universal
- [x] Remove configure-time blocker for missing `cd.iso`
- [x] CI artifact upload (downloadable app bundles per architecture)
- [x] Post-build verification in setup script (bundle check + startup probe)
- [x] Automated smoke tests in CI
- [x] Release workflow — tagged releases publish arm64 + x86\_64 zip artifacts with SHA-256 checksums
- [x] "Which build do I need?" decision table in release notes
- [x] macOS-specific GitHub issue template with diagnostics prompt
- [x] macOS CI badge in README
- [x] Code signing and notarization documentation (this file)
- [ ] Resolve any remaining Clang/AppleClang compiler warnings
- [ ] Confirm test suite passes on both architectures

### Mid-term — "Stable release"
- [ ] Signed and notarized release builds
- [ ] Performance profiling on Apple Silicon

### Long-term — Modernization
- [ ] Evaluate Metal/MoltenVK rendering backend
- [ ] Universal Binary (`lipo` ARM64 + x86\_64) release artifact
- [ ] Homebrew formula or cask for easy installation
