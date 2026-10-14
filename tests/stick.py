#!/usr/bin/env python3
"""Runs ON the device: hold the right stick (ABS_RY drives REL_X and ABS_RZ drives REL_Y on the
RG35XX H, see probe_axes.py) for a time. Usage: stick.py <x -1..1> <y -1..1> <seconds>
Prints the REL sums gptokeyb's virtual device produced, so the pixel travel is known."""
import glob, sys, time, os, fcntl
from evdev import InputDevice, ecodes as e
pad = next(InputDevice(p) for p in glob.glob('/dev/input/event*') if 'Controller' in InputDevice(p).name)
fake = next(InputDevice(p) for p in glob.glob('/dev/input/event*') if 'Fake' in InputDevice(p).name)
fcntl.fcntl(fake.fd, fcntl.F_SETFL, os.O_NONBLOCK)
x, y, secs = float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])
sx = sy = 0
end = time.time() + secs
def drain():
    global sx, sy
    try:
        for ev in fake.read():
            if ev.type == e.EV_REL:
                if ev.code == e.REL_X: sx += ev.value
                if ev.code == e.REL_Y: sy += ev.value
    except BlockingIOError:
        pass
while time.time() < end:
    pad.write(e.EV_ABS, e.ABS_RY, int(x * 4096)); pad.write(e.EV_ABS, e.ABS_RZ, int(y * 4096))
    pad.write(e.EV_SYN, e.SYN_REPORT, 0); time.sleep(0.02); drain()
pad.write(e.EV_ABS, e.ABS_RY, 0); pad.write(e.EV_ABS, e.ABS_RZ, 0); pad.write(e.EV_SYN, e.SYN_REPORT, 0)
time.sleep(0.3); drain()
print('rel_x', sx, 'rel_y', sy)
