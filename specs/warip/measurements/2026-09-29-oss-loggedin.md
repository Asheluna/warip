# Measurement: oss-loggedin

| | |
|---|---|
| Date | 2026-09-29 23:38:02 |
| Kind | run |
| Target | `target/release/warp-oss` |
| warip commit | `85518189` |
| Kernel / session | 6.8.0-139-generic / wayland |
| Idle window | 60 s |

## Startup (S5)

Time from launch to first shell prompt, warm page cache.

| Runs (s) | Median (s) |
|---|---|
| 1.349 1.475 1.417 1.474 1.407 | 1.417 |

## Idle scenarios

| Scenario | PSS (MB) | Threads | CPU (% of 1 core) | Ctx switches/s | Net sockets | NVIDIA fds |
|---|---|---|---|---|---|---|
| S1: 1 tab idle | 619 | 57 | 0.63 | 124.1 | 3 | 12 |
| S2: 5 tabs, 2 splits | 652 | 63 | 0.23 | 86.9 | 3 | 12 |
| S3: right after heavy output | 656 | 63 | 0.00 | 58.0 | 2 | 12 |
| S3: idle after heavy output | 656 | 63 | 0.22 | 88.0 | 2 | 12 |

## Network peers during S1

```
172.217.119.4:443
34.117.41.85:443
```
