#!/bin/bash
# Start the port, steer the pointer onto menu entry N with the right stick, click with R1, report memory
cd "$(dirname "$0")/.."; T=tests/dev.sh
n=$1; dy=$2
$T stop >/dev/null; sleep 5; $T launch >/dev/null; sleep 28
$T k "python3 /tmp/stick.py 1 0 0.4; python3 /tmp/stick.py 0 1 $dy" >/dev/null
$T pad 'press R1' >/dev/null; sleep 30
$T shot g$n >/dev/null; convert tests/out/g$n.png -resize 40% -quality 60 tests/out/g$n.jpg 2>/dev/null
$T k 'P=$(pidof ruffle_sdl); grep VmHWM /proc/$P/status; free -m|sed -n 2p'
