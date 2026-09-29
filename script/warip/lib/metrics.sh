#!/usr/bin/env bash
#
# Helpers for sampling the resource usage of a Warp/warip process tree on Linux.
# Sourced by script/warip/measure. Only reads /proc and `ss`; never needs root.

CLK_TCK="$(getconf CLK_TCK)"

# Prints all descendant PIDs of $1, depth first.
descendants() {
  local child
  for child in $(pgrep -P "$1"); do
    echo "$child"
    descendants "$child"
  done
}

# Prints the PIDs in the tree rooted at $1 whose executable resolves to $2.
# This keeps the app and its helper processes (e.g. terminal-server) and
# excludes the shells and programs running inside the terminal.
app_pids() {
  local root="$1" exe="$2" pid
  for pid in "$root" $(descendants "$root"); do
    if [ "$(readlink -f "/proc/$pid/exe" 2>/dev/null)" = "$exe" ]; then
      echo "$pid"
    fi
  done
}

# Sum of PSS in KiB over the given PIDs.
pss_kb() {
  local pid total=0 value
  for pid in "$@"; do
    value="$(awk '/^Pss:/ {print $2}' "/proc/$pid/smaps_rollup" 2>/dev/null)" || true
    total=$((total + ${value:-0}))
  done
  echo "$total"
}

# Sum of threads over the given PIDs.
thread_count() {
  local pid total=0 value
  for pid in "$@"; do
    value="$(awk '/^Threads:/ {print $2}' "/proc/$pid/status" 2>/dev/null)" || true
    total=$((total + ${value:-0}))
  done
  echo "$total"
}

# Sum of user+system CPU ticks over the given PIDs.
cpu_ticks() {
  local pid total=0 value
  for pid in "$@"; do
    # Fields after the ")" of the command name: utime and stime are the 12th and 13th.
    value="$(sed 's/^.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $12 + $13}')" || true
    total=$((total + ${value:-0}))
  done
  echo "$total"
}

# Sum of voluntary + involuntary context switches over all threads of the given PIDs.
# Used as a root-free proxy for wakeups.
ctx_switches() {
  local pid total=0 value
  for pid in "$@"; do
    value="$(cat "/proc/$pid/task/"*/status 2>/dev/null |
      awk '/ctxt_switches:/ {sum += $2} END {print sum + 0}')" || true
    total=$((total + ${value:-0}))
  done
  echo "$total"
}

# Number of open TCP/UDP sockets owned by the given PIDs.
net_connections() {
  local pid total=0 value
  local sockets
  sockets="$(ss -tunpH 2>/dev/null)"
  for pid in "$@"; do
    value="$(grep -c "pid=$pid," <<<"$sockets")" || true
    total=$((total + ${value:-0}))
  done
  echo "$total"
}

# Remote endpoints of open TCP/UDP sockets owned by the given PIDs, one per line.
net_peers() {
  local pid sockets
  sockets="$(ss -tunpH 2>/dev/null)"
  for pid in "$@"; do
    grep "pid=$pid," <<<"$sockets" | awk '{print $6}' || true
  done | sort -u
}

# Number of open file descriptors pointing at NVIDIA device files.
nvidia_fds() {
  local pid total=0 value
  for pid in "$@"; do
    value="$(find "/proc/$pid/fd" -maxdepth 1 -type l -printf '%l\n' 2>/dev/null | grep -c '^/dev/nvidia')" || true
    total=$((total + ${value:-0}))
  done
  echo "$total"
}

# Samples the app tree rooted at $1 (executable $2) for $3 seconds and prints
# "pss_kb threads cpu_pct ctx_per_sec net nvidia" as one line.
sample_idle() {
  local root="$1" exe="$2" secs="$3"
  local pids ticks_start ctx_start ticks_end ctx_end
  mapfile -t pids < <(app_pids "$root" "$exe")
  ticks_start="$(cpu_ticks "${pids[@]}")"
  ctx_start="$(ctx_switches "${pids[@]}")"
  sleep "$secs"
  mapfile -t pids < <(app_pids "$root" "$exe")
  ticks_end="$(cpu_ticks "${pids[@]}")"
  ctx_end="$(ctx_switches "${pids[@]}")"
  awk -v pss="$(pss_kb "${pids[@]}")" \
      -v threads="$(thread_count "${pids[@]}")" \
      -v dticks="$((ticks_end - ticks_start))" \
      -v dctx="$((ctx_end - ctx_start))" \
      -v secs="$secs" -v hz="$CLK_TCK" \
      -v net="$(net_connections "${pids[@]}")" \
      -v nv="$(nvidia_fds "${pids[@]}")" \
      'BEGIN {printf "%d %d %.2f %.1f %d %d\n", pss, threads, dticks / (hz * secs) * 100, dctx / secs, net, nv}'
}
