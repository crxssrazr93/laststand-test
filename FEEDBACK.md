# Feedback on the Last Stand Legacy Collection port

Hi! Nice port, the idea and the structure are good. I tested it and found why muOS, Rocknix (RP5) and dArkOS testers cannot get past the main screen. The fixed zip is on the [latest release](https://github.com/crxssrazr93/laststand-test/releases/latest) of this repository. It is built on your zip of 14 October, keeps your new features (the menu arrow patch, the `.orig` copy, gptokeyb2 with `laststand.ini`) and adds the fixes below.

## What I tested

* PC: x86_64 ruffle_sdl on a private Xvfb (no window), with a screenshot hook and a scripted mouse.
* Device: RG35XX H on Knulli (640x480, 1 GB), launched through EmulationStation, pad input injected on the real controller.
* Not tested (no hardware): muOS, Rocknix, dArkOS, Rocknix RP5. Those need your testers.

## Root cause of "controls don't work"

The collection menu, and all three games' menus, are mouse only (buttons are clicked, there is no keyboard handling at all). Your gptk maps the right stick to the mouse, which works: on Knulli the stick produces mouse events and clicks reach the game. But `ruffle_sdl` hides the system cursor, so the pointer is invisible and nobody can see where they are. It also starts at the top left corner. Your RG DS (touch) and any device with a real mouse hide the problem.

Two more issues made it worse:

1. The stick speed (`mouse_scale = 512`) is about 300 pixels per second at 640 wide. On a 1080p screen like the RP5 that takes about 8 seconds to cross the screen.
2. If the pointer is still at 0,0 when the intro ends, the menu shows a red debug log (a shell check "mouseX < 10 and mouseY < 10" calls `initLog`). It stays hidden under the menu and pops up when you start a game.

## Fixes

1. **Visible pointer in every game.** Build ruffle_sdl with the optional software cursor patch (0100, in [`ruffle-patch/`](ruffle-patch)). The patched aarch64 binary (glibc 2.30 max, same libraries) is in the zip. The collection menu has its own arrow (your xdelta patch), but the three games are separate SWFs whose menus are mouse driven too, so only the native arrow covers everything. The launcher turns it on with `RUFFLE_SW_CURSOR=1` (`LS_NATIVE_CURSOR`, default on).
2. **No two pointers.** While the native arrow is on, the launcher leaves out your xdelta menu arrow (`LS_SOFT_CURSOR` only matters when `LS_NATIVE_CURSOR="off"`). Checked on the device in both modes: one arrow each.
3. **Pointer starts in the middle of the screen**, not at the top left corner. The patch warps SDL's pointer to the window centre at start, so the first stick movement continues from there.
4. **Pointer speed follows the screen width.** In `mouse_scale` terms nothing changes the speed (on Knulli neither gptokeyb nor gptokeyb2 reacts to it, I measured 200 to 1000 with the same result). The speed comes from `deadzone_scale`. At full stick, 6 (your ini) gives about 255 px/s and 9 gives about 410 px/s on the 640 px screen. The launcher writes run copies (`laststand.run.ini`, `laststand.run.gptk`) with `deadzone_scale` set to 9 (gptokeyb2) or 15 (gptokeyb) at 640 px wide, so 640 pixels take about 1.5 s, scaled linearly with `DISPLAY_WIDTH` and `LS_MOUSE_SPEED` (percent, default 100).
5. **Debug log fix**: one byte (`0a` to `00`, offset 1011117 in the Steam file, 1011380 in the arrow patched file) so the menu's "mouseX < 10" corner test can never be true. It is applied after the copy from `.orig` and the optional xdelta, and only if the bytes match.
6. **The Last Stand 2 was black on the Mali GPU** (RG35XX H). The game started (audio, CPU load, log lines) but the screen stayed black. Cause: ruffle_sdl's GPU zero fill of blank bitmap textures (`RUFFLE_EMPTY_TEXTURES`, default on) on this driver. Exporting `RUFFLE_EMPTY_TEXTURES=0` in the launcher fixes it. The other two games peak at the same memory with it (299 MB and 414 MB), The Last Stand 2 peaks at 382 MB.
7. **Docs match the gptk and the ini**: A is Space, B is R, X is Esc, Y is Shift, L1 is E, L2 is N, Start sends Space (it was listed as Pause), R1 and R2 are the mouse buttons.
8. **Port assets**: `screenshot.png` (a real capture from the device, 76 KB) and `cover.png` (PortMaster cover generator, mixv1 layout, 89 KB), `gameinfo.xml` with players, `port.json` with the images, install text that says where the files come from.
9. cfg settings added: `LS_NATIVE_CURSOR`, `LS_MOUSE_SPEED`, `LS_CURSOR_IDLE_MS`, `LS_CURSOR_SIZE`. The launcher has defaults for all of them, so an old cfg still works.

## Device results (Knulli, RG35XX H, 640x480, 1 GB)

Tested with the zip installed from scratch (fresh Steam file, no `.orig`), started through EmulationStation, input injected on the real controller.

* Menu: loads, patched file is the expected one (`.orig` kept, MD5 of the patched copy matches the PC result), the arrow starts in the centre.
* Pointer placement is deterministic: the test build can warp the pointer (`RUFFLE_SW_CURSOR_WARP_FILE`) and log every position (`RUFFLE_SW_CURSOR_LOG`). [`tests/ls2.sh`](tests/ls2.sh) warps onto a menu entry, takes a device screenshot to confirm the highlight, then clicks with R1 on the pad.
* The Last Stand: starts from the menu, peak 299 MB.
* The Last Stand 2: starts from the menu, intro, skip, diary and the first night run. Moving, aiming with the stick and shooting with R1 change the scene. Peak 382 MB (VmHWM), 460 MB used on the whole system.
* Union City: starts from the menu, peak 414 MB. On 1 GB devices zram is still needed (your notes say so).
* Select + Start exited cleanly in the first round of tests (before the cursor and speed changes). Not re-tested with this build.
* No frame rate measurements were done.

## PC results

x86_64 build on a private Xvfb (no window): the pointer starts at 320,240 on a 640x480 window, the warp file puts it on the exact pixel, and The Last Stand 2 started from the menu by that pointer and a click.

## Still needs testing

Not yet checked on the RG35XX H: Select + Start exit in every game with this build, frame rate, audio and saves per game, every button in the controls table, pointer speed with classic gptokeyb, and a second launch with a replaced Steam file or an unknown game version. GOG copies were not tried.

Other firmwares: muOS (gptokeyb2 with the mouse mappings: please check the arrow and the speed), Rocknix RP5 (pointer speed on 1080p and whether `RUFFLE_EMPTY_TEXTURES=0` is needed there, it is harmless), dArkOS R36S (this build uses SDL on the firmware's own libs), and The Last Stand 2 on every GPU. Please ask testers to send `ports/laststand/log.txt`.

## Suggestions for the PortMaster PR

* Keep the `# PORTMASTER:` line 2 in your own release zip, but PortMaster reviewers ask for it to be removed in the PR launcher.
* Re-make the cover with the PortMaster cover generator if you prefer another screenshot. Each image must stay under 100 KB.
* Add the source for the ruffle_sdl build (patch list) to the README, and keep the Ruffle licence file with the binary.
* Keep the testing blocks and extra logging out of the final launcher.
