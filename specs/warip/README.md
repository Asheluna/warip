# warip

warip is a lightweight soft fork of the open-source [Warp](https://github.com/warpdotdev/warp) terminal for
Ubuntu/Linux. It keeps Warp's terminal experience (blocks, modern input, tabs and panes, themes, file tree
and code editor) and Warp Drive sync, and removes the AI layer and the cloud features it doesn't need.

The repository root `README.md` belongs to upstream Warp and stays unchanged, so it merges cleanly.
warip's own documentation lives in `specs/warip/`:

| File | Contents |
|---|---|
| [`SPEC.md`](SPEC.md) | Goals, scope, targets, design and phases |
| [`PATCHES.md`](PATCHES.md) | Every edit to upstream files |
| [`measurements/`](measurements/) | Measurement reports (baseline and per phase) |
| [`../../CHANGELOG.md`](../../CHANGELOG.md) | Changelog |

## Status

| Phase | State |
|---|---|
| P1 Setup | ✅ Done |
| P2 Baseline | ✅ Done (logged out and logged in) |
| P3 Identity | ✅ Done: `warip` binary, app ID `dev.warip.Warip`, desktop entry |
| P4 Features | Planned |
| P5 Services | Planned |
| P6 GPU | Planned |
| P7 Themes | Planned |
| P8 Install | Planned (the desktop entry is already available) |

Until P4–P6 are done, warip behaves like the stock OSS build, with its own identity.

## Requirements

- Ubuntu 24.04 (other Debian-based distros probably work too)
- About 15 GB RAM for release builds (peak is about 11.5 GB), and at least 40 GB of free disk space for `target/`
- apt packages. The other build dependencies are usually already installed:
  ```bash
  sudo apt install -y build-essential cmake pkg-config libssl-dev libfontconfig1-dev libgit2-dev libclang-dev protobuf-compiler
  ```
- Rust through rustup. The repo pins the toolchain (1.92.0) in `rust-toolchain.toml`:
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.92.0 -c rustfmt -c clippy
  ```

Don't run upstream's `script/bootstrap`. It installs things warip doesn't need (see SPEC.md §7.7).

## Build

```bash
cargo build --release -j 6 -p warp --bin warip --features warip
```

`-j 6` limits parallel jobs so the build fits in 15 GB of RAM. A first build takes about 50 minutes; after
changes to the `app` crate, expect about 25 minutes.

## Run

```bash
target/release/warip
```

To start warip from the GNOME app grid and dock, with the name "warip" instead of `dev.warip.Warip`, install
the desktop entry once:

```bash
script/warip/install-desktop-entry
```

warip runs next to an installed Warp and keeps its own data:

| What | Where |
|---|---|
| Settings | `~/.config/warip/` |
| Themes, workflows | `~/.local/share/warip/` |
| Logs, database | `~/.local/state/warip/` (`warip.log`) |
| Login token | System keyring, service for `dev.warip.Warip` (separate from Warp) |

To use Warp Drive, log in once in warip. If the browser can't hand the login back to the app, use
"Click here to paste your token".

## Measure

`script/warip/measure` compares builds in isolated bench profiles (`~/.cache/warip-bench/<label>`):

```bash
script/warip/measure setup <label> target/release/warip [--login]   # one-time onboarding
script/warip/measure run   <label> target/release/warip             # writes specs/warip/measurements/<date>-<label>.md
```

See SPEC.md §6 for the metrics and targets.

## License

warip is a fork of Warp and keeps its licenses. The `warpui_core` and `warpui` crates are MIT; everything
else is AGPL-3.0. warip doesn't use Warp's name or logo for its app identity.
