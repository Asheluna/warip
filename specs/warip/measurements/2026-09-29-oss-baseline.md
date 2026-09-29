# Measurement: oss-baseline

| | |
|---|---|
| Date | 2026-09-29 23:16:58 |
| Kind | run |
| Target | `target/release/warp-oss` |
| warip commit | `fa2afeb6` |
| Kernel / session | 6.8.0-139-generic / wayland |
| Idle window | 60 s |

## Startup (S5)

Time from launch to first shell prompt, warm page cache.

| Runs (s) | Median (s) |
|---|---|
| 1.218 1.199 1.217 1.257 1.232 | 1.218 |

## Idle scenarios

| Scenario | PSS (MB) | Threads | CPU (% of 1 core) | Ctx switches/s | Net sockets | NVIDIA fds |
|---|---|---|---|---|---|---|
| S1: 1 tab idle | 379 | 57 | 0.32 | 94.2 | 0 | 12 |
| S2: 5 tabs, 2 splits | 415 | 63 | 0.22 | 80.6 | 0 | 12 |
| S3: right after heavy output | 419 | 63 | 0.00 | 55.0 | 0 | 12 |
| S3: idle after heavy output | 419 | 63 | 0.22 | 78.7 | 0 | 12 |

## Network peers during S1

```
none
```
