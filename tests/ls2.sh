#!/bin/bash
# Deterministic launch of a game from the collection menu on the device, no stick needed.
#   ls2.sh <1|2|uc> [wait seconds after the click]
# Needs a ruffle_sdl with RUFFLE_SW_CURSOR_WARP_FILE (the cursor patch) and a /tmp/ls_test_env on the
# device that exports RUFFLE_SW_CURSOR=1 RUFFLE_SW_CURSOR_LOG=1 RUFFLE_SW_CURSOR_WARP_FILE=/tmp/warp
# (the launcher sources it when present, see tests/README in the repo). Menu entries are at
# x=70, y=263 (The Last Stand), 303 (The Last Stand 2), 343 (Union City) in a 640x480 window.
cd "$(dirname "$0")/.."; T=tests/dev.sh
case $1 in 1) y=263;; 2) y=303;; uc) y=343;; *) echo "usage: $0 1|2|uc [wait]"; exit 1;; esac
$T stop >/dev/null; sleep 5; $T launch >/dev/null || exit 1; sleep 26
$T k "echo '70 $y' > /tmp/warp; sleep 1.5; grep swcursor /userdata/roms/ports/laststand/log.txt | tail -1"
$T shot hover_$1 >/dev/null
$T pad 'press R1' >/dev/null; sleep ${2:-30}
$T shot game_$1 >/dev/null
$T k 'P=$(pidof ruffle_sdl); grep VmHWM /proc/$P/status; free -m | sed -n 2p'
