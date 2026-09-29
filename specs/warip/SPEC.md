# warip — Specification

**Status:** Draft v0.2 · **Date:** 2026-09-29 · **Upstream:** [warpdotdev/warp](https://github.com/warpdotdev/warp) `master` @ `569db5e`

warip is a lightweight soft fork of the open-source Warp terminal for Ubuntu. It keeps Warp's terminal
experience (blocks, modern input, tabs/panes, themes, file tree and code editor) and **Warp Drive sync**.
It removes the AI layer and the cloud features that aren't needed, while staying mergeable with upstream.

---

## 1. Implementation overview

1. Set up the environment (Rust toolchain, `gh`, GitHub fork, clone into `warip/`)
2. Build unmodified `warp-oss` and record a reproducible **baseline**
3. Give warip its own **identity** (binary, app ID, config/data dirs)
4. **Trim features** via a `warip` Cargo feature set (AI, cloud, extras off)
5. **Trim services**: stop AI/cloud/indexing/watcher background work at startup
6. **GPU tuning**: keep the NVIDIA dGPU untouched on hybrid laptops
7. **Theme import** from an existing Warp install
8. **Install**: release build, `.desktop` file, install script
9. Re-measure after every phase against the baseline

---

## 2. Goals

| # | Goal |
|---|---|
| G1 | Lower **memory** use than stock `warp-oss` |
| G2 | Close to **zero idle CPU** and few wakeups when nothing is happening (battery) |
| G3 | Faster **startup** to first usable prompt |
| G4 | No **GPU / fan** impact: render on the iGPU, never wake the dGPU |
| G5 | **Zero network traffic** while logged out. When logged in, only auth and Warp Drive sync. |
| G6 | Stay **mergeable with upstream** with a small, documented patch set |

## 3. Non-goals

- Rewriting the renderer, UI framework or terminal emulator core
- Supporting macOS or Windows (Linux/Ubuntu only; other platforms may still compile but are untested)
- Shipping binaries or packages to others (build from source for personal use)
- Adding new user-facing features beyond theme import

---

## 4. Context

### 4.1 Target system

| Item | Value |
|---|---|
| OS | Ubuntu 24.04.5, kernel 6.8, GNOME on **Wayland** |
| CPU / RAM | Intel i5-10210U (4C/8T) / 15 GB |
| GPU | **Hybrid:** Intel UHD 620 (Mesa 25.2, i915) + NVIDIA MX250 (proprietary driver) |
| Display | 1 × eDP, 60 Hz |
| Vulkan ICDs | Intel, NVIDIA, nouveau, lvp, and others in `/usr/share/vulkan/icd.d/` |
| Installed Warp | `warp-terminal` 0.2026.09.16 stable (.deb), config in `~/.config/warp-terminal`, themes in `~/.local/share/warp-terminal/themes` |

### 4.2 Stock Warp observations (informal, one sample)

These are one-off readings from the installed stable Warp. They are **not** the baseline;
Phase 2 produces the real one.

| Metric | Value |
|---|---|
| Main process PSS | ~466 MB (plus `terminal-server` and `minidump-server` helpers at ~2 MB each) |
| Threads | 70 |
| CPU over a 10 s sample | ~1.6 % of one core-second per second (~16 % of one core); idle state not guaranteed |
| GPU | Renders on the iGPU (`prefer_low_power_gpu = true`), but has `/dev/nvidia0` and `/dev/nvidiactl` open. This is most likely from Vulkan enumerating every adapter. |

### 4.3 Codebase facts that shape the design

- About **1.75M lines of Rust** in 80 crates. The `app` crate alone is about 1.16M lines.
- UI is `warpui` (MIT) rendered with **wgpu 30** on Warp's `winit` fork. Everything else is **AGPL-3.0**.
- About **300 Cargo features**, about 200 on by default. Most Cargo features **only set runtime `FeatureFlag`s**.
  For example, `agent_mode` has 1 `#[cfg(feature)]` use against 82 `FeatureFlag::AgentMode` checks.
  Turning features off hides UI but does **not** remove code or stop services.
- `initialize_app` (`app/src/lib.rs:1457`) registers about 140 singleton models, including
  `HomeDirectoryWatcher`, `DirectoryWatcher`, `GitRepoModels`, `DetectedRepositories`,
  `RepoOutlines` (indexing), `SystemStats`, `NetworkStatus`, `LanguageServerShutdownManager`,
  `VoiceInput`, `RemoteServerManager` and many AI, pricing and cloud models.
- The OSS channel (`app/src/bin/oss.rs`) already has telemetry, crash reporting and autoupdate set to `None`,
  but still points at Warp's **production server**.
- On Linux, `GPUSettings::prefer_low_power_gpu` already defaults to `true` (`app/src/settings/gpu.rs`).
- Paths come from `warp_core::paths` via the channel's `AppId`. For `Channel::Oss` this is hard-coded to
  `dev.warp.WarpOss` (`gui_app_id_for_channel`).

---

## 5. Scope

### 5.1 Keep

| Area | Includes |
|---|---|
| Terminal core | PTY, shells (bash/zsh/fish), alt screen, OSC hyperlinks, kitty images, ligatures |
| Blocks | Command blocks, block selection, filtering, find |
| Modern input | Input editor, completions (`warp_completer` + command signatures), history search, autosuggestions, vim mode |
| Layout | Windows, tabs, split panes, undo-close pane |
| Look & feel | Themes, fonts, UI zoom, command palette, keybindings |
| Settings | Local `settings.toml`, settings UI for the kept features |
| Warp Drive | Drive panel; workflows, notebooks and env-var collections; offline cache; live sync with other machines through the `get_warp_drive_updates` subscription |
| Workflows | Local YAML workflows and Drive workflows. Drive already depends on the workflow code, so keeping local ones costs almost nothing. |
| Account | Login and auth, **required only for Drive** |
| Editor | File tree, code editor panes, find/replace, vim mode in the editor |

### 5.2 Remove (disabled by default)

| Area | Examples |
|---|---|
| AI / agents | Agent mode, AI command suggestions, MCP, codebase indexing, voice input, computer use, code review AI, "Drive objects as context" |
| Cloud (non-Drive) | Session sharing, pricing/billing/usage, server experiments, changelog fetch, cloud environments |
| IDE extras | LSP (can be enabled later), code review pane, "Get started" tab, onboarding upsells |
| Background extras | Home-directory and repo watchers (unless the file tree needs them), system stats polling |

### 5.3 Login and network

Login is **optional** and only needed for Drive.

- **Logged out:** warip opens **no network connections**. Local workflows, themes and the terminal all work offline.
- **Logged in:** auth, the GraphQL API for Drive, and a single WebSocket for Drive updates. No AI, telemetry,
  experiments or pricing traffic.

---

## 6. Success metrics

Targets are final as of 2026-09-29. They're based on the logged-out Phase 2 baseline of unmodified `warp-oss`
(`measurements/2026-09-29-oss-baseline.md`), and the logged-in baseline with Warp Drive synced
(`measurements/2026-09-29-oss-loggedin.md`). warip is used logged in, for Drive, so the **b** rows are the
primary targets.

| ID | Metric | Baseline | Target |
|---|---|---|---|
| M1 | PSS, 1 window / 1 tab, idle 60 s, logged out | 379 MB | ≤ 225 MB (−40 %) |
| M1b | PSS, 1 window / 1 tab, idle 60 s, logged in | 619 MB | ≤ 370 MB (−40 %) |
| M2 | PSS, 1 window / 5 tabs incl. 2 split panes, logged out | 415 MB | ≤ 250 MB |
| M2b | PSS, 1 window / 5 tabs incl. 2 split panes, logged in | 652 MB | ≤ 390 MB |
| M3 | Idle CPU, 1 tab, logged out | 0.32 % of one core | ≤ 0.3 % |
| M3b | Idle CPU, 1 tab, logged in | 0.63 % | ≤ 0.3 % |
| M4 | Idle context switches/s (a root-free proxy for wakeups), logged out | 94 | ≤ 47 (−50 %) |
| M4b | Idle context switches/s, logged in | 124 | ≤ 60 (−50 %) |
| M5 | Start to first prompt, median of 5, logged out | 1.22 s | ≤ 0.85 s (−30 %) |
| M5b | Start to first prompt, median of 5, logged in | 1.42 s | ≤ 1.0 s (−30 %) |
| M6 | Network sockets while logged out (`ss -tunp`) | 0 | 0 |
| M6b | Network sockets while logged in and idle | 3 (Warp API on GCP, Google) | ≤ 3; only Warp API and Google auth hosts |
| M7 | NVIDIA device files open (`/proc/<pid>/fd`) | 12 | 0 |
| M8 | PSS after heavy output (`seq 1 2000000`) and 60 s idle, vs. before | +1 % | ≤ +10 % |
| M9 | 1-hour soak, idle | deferred | PSS growth ≤ 5 % |

For reference, the installed stable Warp in daily use (logged in, long-running session) measured 503 MB,
3.5 % idle CPU, about 425 context switches/s and 8 sockets (`measurements/2026-09-29-stable-passive.md`).
Its lower PSS than the logged-in `warp-oss` (503 vs 619 MB) is probably partly the build: official releases are
likely built with LTO and stripped, while our baseline uses the plain `release` profile. Keep the build profile
the same when comparing warip against the baseline.

### 6.1 Measurement method

- `script/warip/measure` (helpers in `script/warip/lib/metrics.sh`) writes Markdown reports to
  `specs/warip/measurements/<date>-<label>.md`. Modes:
  - `setup` does the one-time manual onboarding in an isolated bench profile.
  - `run` covers S5 (startup), S1 (1 tab), S2 (5 tabs, 2 splits) and S3 (heavy output).
  - `passive` samples an already running Warp, such as the installed stable.
- Bench profiles are isolated through `XDG_{CONFIG,DATA,STATE,CACHE}_HOME` under `~/.cache/warip-bench/<label>`.
  Warp's own `WARP_DATA_PROFILE` only works in debug builds.
- Tabs, panes and the S3 command are **manual steps**. The script prompts for them and waits for Enter.
  Warp's `warpctrl` would need the non-default `warp_control_cli` feature, which would change the build
  under test.
- `setup` writes the bench `settings.toml` itself (`restore_session = false`, `prefer_low_power_gpu = true`).
  `stop_app` signals the whole process group.
- Metrics cover only the app's own processes: the tree filtered by executable, so shells are excluded.
  - PSS comes from `smaps_rollup`, CPU from `/proc/<pid>/stat` ticks, and context switches from `/proc/<pid>/task/*/status`.
  - Sockets come from `ss -tunp`, and NVIDIA file descriptors from `/proc/<pid>/fd`.
  - No root is needed.
- Startup time runs from launch to the first prompt. A guarded `~/.bashrc` block writes a timestamp when
  `WARIP_BENCH_MARKER` is set. The result is the median of 5 runs with a warm page cache.
- Same machine, AC power, same shell config for every run. Don't type in the window during a run.
- S4 (1-hour soak) is deferred.

---

## 7. Design

### 7.1 Patch strategy (soft fork)

Keep the diff against upstream **small, isolated and documented**:

- All warip behaviour sits behind a single Cargo feature, **`warip`**, plus the new `warip` binary.
  Upstream code paths stay intact when the feature is off.
- Prefer **new files** (`app/src/warip/…`, `app/src/bin/warip.rs`) over editing upstream files.
  Where an upstream edit is unavoidable, keep it to a small `#[cfg(feature = "warip")]` hook.
- Every upstream-file edit is listed in `specs/warip/PATCHES.md` (file, reason, conflict risk).

### 7.2 Identity (Phase 3)

- New binary `warip` (`app/src/bin/warip.rs`) modelled on `oss.rs`, using the OSS channel.
- Own `AppId` (for example `dev.warip.Warip`), which gives its own `~/.config/warip`, `~/.local/share/warip`
  and `~/.local/state/warip`. It **coexists** with the installed Warp.
- Requires a small patch to `gui_app_id_for_channel` so `Channel::Oss` doesn't force `WarpOss`.
- Own name, window title and icon; no Warp logos or trademarks.

### 7.3 Feature trimming (Phase 4)

- Add a `warip` feature set in `app/Cargo.toml` that lists only the kept features from §5.1.
- Build with `--no-default-features --features warip`.
- Keep a list, derived from upstream's `default` list, of what was dropped and why, so upstream additions
  can be reviewed on each merge.

### 7.4 Service trimming (Phase 5)

Main source of RAM and idle-CPU savings. For each startup singleton, choose one of:

| Action | When |
|---|---|
| **Keep** | Required by a kept feature |
| **Register, but inert** | Other code expects the singleton to exist (a missing singleton can panic at lookup), but its timers, network, polling or watchers must not start |
| **Skip** | Nothing reachable depends on it (verified by build and tests) |

Order of work, by expected payoff: network clients and polling → AI and pricing models → indexing and
repo outlines → file watchers → LSP and voice.

Always **Keep** the services Drive needs: auth, the server/GraphQL client, the Drive WebSocket
subscription, cloud object persistence (SQLite cache) and the workflow models. Their network activity
must start **only after login**.

The result is recorded as a table in `specs/warip/services.md`.

### 7.5 GPU (Phase 6)

- Keep `prefer_low_power_gpu = true`.
- **Crash recovery switches to the dGPU.** When `prefer_low_power_gpu` isn't set explicitly, Warp starts a
  crash-recovery child process (`app/src/crash_recovery.rs`). If the parent dies before that child is
  cleaned up, the child relaunches Warp and **permanently writes `prefer_low_power_gpu = false`**. A
  SIGTERM is enough to trigger this; it happened during baseline setup. warip should write the preference
  explicitly on first run, or drop the `DedicatedGpu` recovery mechanism on Linux.
- Stop the dGPU from being opened. First test is launch-time only: set `VK_DRIVER_FILES` to the Intel ICD
  in the `.desktop` file and wrapper. If that satisfies M7, keep it and don't patch code.
- Only if needed: restrict adapter enumeration in `warpui` rendering to the preferred adapter.
- Check that rendering doesn't redraw while idle (frame pacing and cursor blink) as part of M3 and M4.

### 7.6 Theme import (Phase 7)

- On first run, if `~/.local/share/warip/themes` is empty and `~/.local/share/warp-terminal/themes` exists,
  offer to copy the themes (YAML files and their background images). The format is identical, so no
  conversion is needed.
- Optionally also import `keybindings.yaml`.
- Never modify the Warp install's files.

### 7.7 Build and install (Phase 8)

- Toolchain pinned by upstream `rust-toolchain.toml` (1.92.0) via rustup.
- Setup: **don't run `script/bootstrap`**. It installs the gcloud CLI and its apt repo, linuxdeploy, musl, a
  protoc download into `/usr/local`, and agent skills, and it asks for a gcloud login. warip needs none of that.
  Install a curated set instead:
  - apt: `libssl-dev libfontconfig1-dev libgit2-dev libclang-dev protobuf-compiler`. Ubuntu 24.04's protoc 3.21
    meets the ≥3.15 requirement from `crates/remote_server/build.rs`. The other build dependencies are already installed.
  - rustup with toolchain 1.92.0 (`--profile minimal`, plus rustfmt and clippy).
  - Git LFS isn't needed. The only LFS files are Windows `.pdb` files and ONNX models for the non-default
    `nld_classifier_*` features.
- `cargo build --release -p warp --bin warip --no-default-features --features warip`
- `script/warip/install` copies the binary to `~/.local/bin/warip` and installs a `.desktop` file and icon
  to `~/.local/share/applications` and `~/.local/share/icons`.
- Disk: keep at least 40 GB free for `target/`. Use `cargo clean` or `kondo` between large upstream merges.

### 7.8 Git and branch model

| Branch | Purpose |
|---|---|
| `master` | Clean mirror of `upstream/master`. Never commit warip changes here. |
| `warip` | Default branch with all warip work. Upstream is **merged** in, not rebased, to preserve history. |
| `feat/*` | One branch per phase or patch, merged into `warip` |

- Remotes: `origin` is the user's GitHub fork, `upstream` is `warpdotdev/warp`.
- Merge upstream about every 2–4 weeks. After each merge: build, run tests and `measure`, and review
  upstream's new default features against §7.3.

---

## 8. Phases and exit criteria

| Phase | Deliverable | Exit criteria |
|---|---|---|
| P1 Setup | Fork, clone, toolchain, `upstream` remote | `cargo check -p warp` passes |
| P2 Baseline | `measure` script, baseline report | Report committed; §6 targets confirmed |
| P3 Identity | `warip` binary, own AppId and dirs | Runs next to installed Warp without sharing config |
| P4 Features | `warip` feature set | AI and cloud UI absent; kept features work; tests pass |
| P5 Services | Service table, patches | M1–M6 met, or the gap explained |
| P6 GPU | Launch config or patch | M7 met |
| P7 Themes | Import flow | Existing Warp themes appear in warip |
| P8 Install | Install script and `.desktop` file | Launchable from GNOME; M5 verified |

---

## 9. Testing

- Run upstream tests for touched crates: `cargo nextest run -p warp` and `-p warp_core`. Existing tests must keep passing.
- New tests for warip logic: AppId and path resolution, theme import (empty, existing, conflicting names),
  and a feature-set check that AI and cloud flags are off under `warip`.
- `measure` acts as the performance regression test after each phase and each upstream merge.
- Manual smoke checklist: shells, blocks, completions, history, tabs and panes, themes, alt-screen apps
  (vim, htop), copy/paste, links, and IME/Unicode.

---

## 10. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Code is heavily entangled; skipping singletons causes panics | P5 slows down | Default to "register, but inert"; skip only when proven safe |
| Upstream moves fast (many commits/day) | Merge conflicts | Small isolated patches, `PATCHES.md`, regular merges |
| Savings are modest if most memory is renderer, glyph atlas or block storage | Misses M1/M2 | Baseline first; profile with `dhat` (feature already exists) before cutting |
| Build needs a lot of RAM and disk (15 GB RAM, 1.75M LOC) | Slow or OOM links | Limit `CARGO_BUILD_JOBS`, release builds with incremental builds off, monitor disk |
| `script/bootstrap` changes the system (apt installs, skills) | Unwanted changes | Review the script before running; use `--skip-common-skills` |
| AGPL-3.0 and trademarks | Legal | Keep the fork public/AGPL, keep notices, don't use Warp branding |
| OSS channel is wired to Warp's production server | Unexpected traffic | M6 check; gate server clients while logged out |
| Drive depends on Warp's hosted service and account | The server could reject old or OSS clients, or change the API | Merge upstream regularly so the client protocol stays current; the Drive offline cache keeps content readable |
| Removing AI or cloud code breaks Drive by accident | Sync regressions | Smoke test after each phase: create, edit and delete a Drive workflow and confirm it syncs to another machine |

---

## 11. Open questions

| # | Question | Status |
|---|---|---|
| Q1 | What should login still provide? | **Resolved:** Warp Drive sync only (§5.3) |
| Q2 | App ID and naming: is `dev.warip.Warip` OK? Do you have an icon preference? | Open (Phase 3) |
| Q3 | Keep local Workflows? | **Resolved:** keep; the code is shared with Drive |
| Q4 | Keep the file tree and code editor panes? | **Resolved:** keep |
| Q5 | Should the Warp install be removed or left alone once warip works? | Open (Phase 8) |
| Q6 | Should Warp settings sync (`SyncToCloud`) be kept together with Drive? | Open (Phase 5) |
