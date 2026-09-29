# Changelog

## 2026-09-29

### Added
- `script/warip/measure` and `script/warip/lib/metrics.sh`: reproducible memory, CPU, context-switch, network and GPU measurements for Warp/warip builds (setup, run and passive modes)
- Initial project specification for warip, a lightweight soft fork of Warp (`specs/warip/SPEC.md`)
- Baseline measurements: unmodified `warp-oss` logged out (`specs/warip/measurements/2026-09-29-oss-baseline.md`) and installed stable Warp in daily use (`2026-09-29-stable-passive.md`)

### Fixed
- Measurement script: manual steps replace `warpctrl` (not available in OSS builds), bench settings are written automatically, and stopping the app no longer triggers Warp's crash recovery onto the dedicated GPU

### Changed
- Spec v0.2: keep Warp Drive sync (login optional), local workflows, file tree and code editor; upstream default branch is `master`
- Spec: replace `script/bootstrap` with a curated Linux dependency list (no gcloud, linuxdeploy or Git LFS)
