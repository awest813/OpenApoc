# Versioning Policy

OpenApoc uses [Semantic Versioning](https://semver.org/) for tagged releases:

- `MAJOR.MINOR.PATCH` for stable releases (for example `v1.2.3`)
- Optional pre-release suffixes for release candidates (`-alpha.N`, `-beta.N`, `-rc.N`)

## Rules

1. **MAJOR** increments for incompatible changes to gameplay data formats, save compatibility, or public modding interfaces.
2. **MINOR** increments for backward-compatible feature additions.
3. **PATCH** increments for backward-compatible fixes and maintenance updates.

## Development versions

- Unreleased mainline work may use `-dev` suffixes in metadata (for example `0.1.0-dev` in manifests).
- Only tags matching `v*` are considered release artifacts by CI.

## Tag format

- Release tags must be prefixed with `v` (for example `v0.2.0`, `v1.0.0-rc.1`).
- Tags are immutable once published.
