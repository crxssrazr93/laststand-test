#!/bin/bash
# dev.sh: drive the Last Stand port on a Knulli test device through EmulationStation's API.
#   dev.sh k '<cmd>'            run a command on the device
#   dev.sh launch               start "The Last Stand Collection.sh" through ES (refuses if a game runs)
#   dev.sh stop                 emukill (only when this port is the running game)
#   dev.sh pad '<devpad steps>' inject pad input with devpad.py (copied to the device first)
#   dev.sh shot <name>          framebuffer to out/<name>.png (needs magick on the PC)
#   dev.sh log [n]              last n lines of the port log without colour codes
# DEVICE_HOST (default 192.168.2.234), DEVICE_PASS (default ~/.ssh/knulli.pass)
here=$(cd "$(dirname "$0")" && pwd)
HOST=${DEVICE_HOST:-192.168.2.234}; PASS=${DEVICE_PASS:-$HOME/.ssh/knulli.pass}
LAUNCHER="/userdata/roms/ports/The Last Stand Collection.sh"
OUT=$here/out; mkdir -p "$OUT"
K() { sshpass -f "$PASS" ssh -o ConnectTimeout=10 -o LogLevel=ERROR "root@$HOST" "$@"; }
case $1 in
  k) shift; K "$@";;
  launch)
    r=$(K 'curl -s -m 5 localhost:1234/runningGame'); echo "$r" | grep -q 'NO GAME RUNNING' || { echo "a game is running: $r"; exit 1; }
    K "curl -s -m 5 localhost:1234/systems/ports/games | grep -qF 'Last Stand Collection.sh'" || { echo "ES does not list the launcher"; exit 1; }
    K "curl -s -m 5 -d '$LAUNCHER' localhost:1234/launch";;
  stop)
    K 'curl -s -m 5 localhost:1234/runningGame' | grep -qi 'last stand' || { echo "not our game: refusing"; exit 1; }
    K 'curl -s -m 5 localhost:1234/emukill';;
  pad) K 'cat > /tmp/devpad.py' < "$here/devpad.py"; K "python3 /tmp/devpad.py '$2'";;
  shot)
    K 'cat /sys/class/graphics/fb0/virtual_size /sys/class/graphics/fb0/pan; dd if=/dev/fb0 of=/tmp/fb.raw bs=1M 2>/dev/null' > "$OUT/.info"
    sshpass -f "$PASS" scp -q -o LogLevel=ERROR "root@$HOST:/tmp/fb.raw" "$OUT/.fb.raw"
    W=$(head -1 "$OUT/.info" | cut -d, -f1); VH=$(head -1 "$OUT/.info" | cut -d, -f2); PY=$(sed -n 2p "$OUT/.info" | cut -d, -f2)
    H=$(( $(stat -c %s "$OUT/.fb.raw") / (W * 4) ))
    magick -size ${W}x${H} -depth 8 bgra:"$OUT/.fb.raw" -alpha off -crop ${W}x$((VH / 2))+0+${PY} +repage "$OUT/$2.png" && echo "$OUT/$2.png";;
  log) K "sed 's/\x1b\[[0-9;]*m//g' /userdata/roms/ports/laststand/log.txt | tail -n ${2:-30}";;
  *) sed -n '2,10p' "$0"; exit 1;;
esac
