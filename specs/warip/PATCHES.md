# warip — Upstream patches

Every edit warip makes to a file that exists upstream (`warpdotdev/warp`). New files are not listed.
Review this list on every upstream merge (see SPEC.md §7.1 and §7.8).

Conflict risk: **low** = small and isolated, **medium** = touches code upstream changes often, **high** = large or central.

| File | Change | Why | Phase | Conflict risk |
|---|---|---|---|---|
| `app/Cargo.toml` | Added the `warip` feature and the `warip` `[[bin]]` (requires `warip`) | Build target for warip | P3 | low |
| `crates/warp_core/src/paths.rs` | `gui_app_id_for_channel`: only the OSS **TUI** (`WarpTui`) maps to `WarpOss`; other OSS-channel GUIs keep their own app ID | Otherwise warip would read its GUI config and MCP files from `warp-oss` directories | P3 | low |
| `crates/warp_core/src/paths_tests.rs` | Added `test_gui_app_id_keeps_other_oss_gui_ids` | Covers the change above | P3 | low |
| `app/src/root_view.rs` | `WINDOW_TITLE` is `"warip"` under the `warip` feature; the four hard-coded `"Warp"` window titles now use `WINDOW_TITLE` | Window title and Alt+Tab show warip | P3 | low (medium if upstream edits window creation) |
