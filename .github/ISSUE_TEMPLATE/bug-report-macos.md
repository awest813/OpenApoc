---
name: Bug Report — macOS
about: Report a problem running OpenApoc on Apple Silicon or Intel Mac
title: '[macOS] '
labels: 'platform:macos'
assignees: ''

---

**Before posting:** please search existing issues for your problem. Many macOS issues are Gatekeeper, Homebrew prefix, or architecture mismatches — check [SUPPORT.md](../../SUPPORT.md) and the README troubleshooting section first.

---

## System information

Run the diagnostics script and paste the full output here:

```sh
bash tools/macos-diag.sh
```

<details>
<summary>Diagnostics output</summary>

```
(paste output here)
```

</details>

## Architecture label

- [ ] Apple Silicon (`arch:arm64`)
- [ ] Intel (`arch:x86_64`)

---

## What happened?

<!-- A clear and concise description of the problem. -->

## Steps to reproduce

1. 
2. 
3. 

## What did you expect to happen?

<!-- What should have happened instead. -->

## Screenshots / log output

<!-- Paste any crash output, terminal output, or screenshots here. -->

## Game data

- [ ] Using Steam `cd.iso`
- [ ] Using GOG `.cue`/`.bin`
- [ ] Other (please describe):

## How did you install OpenApoc?

- [ ] Downloaded pre-built `.zip` from the [Releases page](https://github.com/awest813/OpenApoc/releases)
- [ ] Built from source using `bash tools/macos-setup.sh`
- [ ] Built from source manually with CMake

## OpenApoc version / build

<!-- If using a release download, state the tag (e.g. v0.1.0).
     If built from source, paste the output of: git log --oneline -1 -->
