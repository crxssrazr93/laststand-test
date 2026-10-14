#!/usr/bin/env python3
"""Runs ON the device: push each stick axis to full deflection and print what gptokeyb's virtual
device (Fake Keyboard) emits. Usage: probe_axes.py"""
import glob, threading, time, collections
from evdev import InputDevice, ecodes as e
pad = next(InputDevice(p) for p in glob.glob('/dev/input/event*') if 'Controller' in InputDevice(p).name)
fake = next(InputDevice(p) for p in glob.glob('/dev/input/event*') if 'Fake' in InputDevice(p).name)
cnt = collections.Counter(); run = [True]
def rd():
    while run[0]:
        try:
            for ev in fake.read():
                cnt[(e.EV[ev.type], ev.code if ev.type != e.EV_REL else e.REL[ev.code], ev.value if ev.type == e.EV_KEY else '')] += 1
                if ev.type == e.EV_REL: cnt['sum_' + e.REL[ev.code]] += ev.value
        except BlockingIOError:
            time.sleep(0.01)
import fcntl, os
fcntl.fcntl(fake.fd, fcntl.F_SETFL, os.O_NONBLOCK)
t = threading.Thread(target=rd); t.start()
for name in ('ABS_Z', 'ABS_RZ', 'ABS_RX', 'ABS_RY'):
    cnt.clear(); code = getattr(e, name)
    end = time.time() + 1.5
    while time.time() < end:
        pad.write(e.EV_ABS, code, 4000); pad.write(e.EV_SYN, e.SYN_REPORT, 0); time.sleep(0.02)
    pad.write(e.EV_ABS, code, 0); pad.write(e.EV_SYN, e.SYN_REPORT, 0); time.sleep(0.4)
    print(name, dict(cnt), flush=True)
run[0] = False; t.join()
