# Apple Silicon + Intel Fork Plan

This repository is a macOS-first OpenApoc fork. Apple Silicon is the primary
target, Intel Mac support is maintained on a best-effort basis, and Windows /
Linux remain upstream compatibility concerns rather than release-blocking goals
for this fork.

## Support contract

| Tier | Platform | Architecture | Target macOS | Release policy |
|---|---|---|---|---|
| Tier 1 | Apple Silicon Macs | arm64 | macOS 14 Sonoma and newer | Blocking for merges and releases |
| Tier 2 | Intel Macs | x86_64 | macOS 13 Ventura | Best-effort, non-blocking |
| Out of scope | Windows / Linux | n/a | n/a | Track upstream; not release-blocking here |

Apple Silicon regressions block releases. Intel regressions are fixed when they
are low-risk and runner capacity remains available. Windows and Linux fixes are
welcome when they do not compromise the macOS-first goals, but this fork does
not publish or gate releases on those platforms.

## Canonical build paths

All macOS builds should use the CMake presets in `CMakePresets.json`:

- `macos-arm64` for Apple Silicon development and CI.
- `macos-x86_64` for Intel development and CI.
- `macos-universal` for release-oriented universal binary validation.

The helper scripts in `tools/` are the preferred user entry points:

- `tools/macos-setup.sh` installs/verifies dependencies, configures, builds, and
  probes the app bundle.
- `tools/macos-run.sh` launches from the repository root so game data resolves.
- `tools/macos-diag.sh` gathers bug-report diagnostics.

## CI/CD policy

The `macOS` GitHub Actions workflow is the primary required CI gate. It builds,
tests, smoke-tests, and uploads per-architecture app bundle artifacts for:

- Apple Silicon on `macos-15`.
- Intel on `macos-13`.

Legacy Linux workflows are kept as manual, non-blocking upstream compatibility
checks only. AppVeyor Windows configuration is retired from this fork's active
policy.

If GitHub-hosted Intel macOS runners become unavailable, maintainers should
choose one of the following before the next release:

1. Attach a trusted self-hosted Intel Mac runner.
2. Downgrade Intel to source-build-only support.
3. Remove Intel release artifacts after announcing the deprecation in
   `SUPPORT.md` and release notes.

## Release engineering

Tagged releases publish separate downloads:

- `OpenApoc-macOS-apple-silicon.zip`
- `OpenApoc-macOS-intel.zip`

Each release also publishes SHA-256 checksums. Signing and notarization are
optional until Apple Developer ID credentials are configured in repository
secrets; when configured, release builds should sign, notarize, staple, and
verify the app bundle before publishing artifacts.

Required release checks:

- App bundle exists and contains an executable.
- Startup probe exits cleanly.
- Dynamic library links are inspectable with `otool`.
- Release notes clearly state which artifact users should download.
- Unsigned builds document the Gatekeeper workaround.

## QA matrix

| Area | Apple Silicon | Intel |
|---|---|---|
| Configure/build | Required | Required while runners exist |
| Unit tests | Required | Required while runners exist |
| Startup probe | Required | Required |
| Game data load | Required before stable release | Best-effort |
| Rendering/audio/save-load smoke | Required before stable release | Best-effort |
| Performance profiling | Required before stable release | Optional |

## Issue triage

macOS reports should use `.github/ISSUE_TEMPLATE/bug-report-macos.md` and include
`tools/macos-diag.sh` output. Triage should label issues using:

- `platform:macos`
- `arch:arm64`
- `arch:x86_64`

Apple Silicon correctness bugs are release-blocking unless explicitly accepted
as known issues. Intel-only bugs are evaluated for impact, risk, and runner
availability.

## Maintenance review

Before each stable release, and at least quarterly while releases are active,
review:

- GitHub runner availability for Apple Silicon and Intel.
- Intel user reports and issue volume.
- Signing/notarization status.
- Apple Silicon performance and startup regressions.
- Whether Windows/Linux upstream compatibility checks still add value.

## Done definition

The fork transition is complete when:

- macOS-first policy is explicit in documentation and CI.
- Apple Silicon is a required merge/release gate.
- Intel status and deprecation triggers are documented.
- Release artifacts are consistently named, checksummed, and user-guided.
- Signing/notarization is either automated or documented as unavailable.
- Non-mac automation is removed from required branch policy or marked manual and
  non-blocking.
