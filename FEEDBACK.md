# Feedback on the Last Stand Legacy Collection port

Hi! Nice port, the idea and the structure are good. I tested it and found why muOS, Rocknix (RP5) and dArkOS testers cannot get past the main screen. The fixed zip is attached to the latest release of this repository.

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

1. **Visible pointer.** Build ruffle_sdl with the optional software cursor patch (0100, included in ruffle-patch/) and turn it on in the launcher. The patched aarch64 binary (glibc 2.30 max, same libraries) is in the zip. Verified on Knulli: the arrow follows the stick and R1 clicks menu entries; The Last Stand and Union City started from the menu with the pad only.

```
export RUFFLE_SW_CURSOR=1
export RUFFLE_SW_CURSOR_IDLE_MS="$LS_CURSOR_IDLE_MS"
export RUFFLE_SW_CURSOR_SIZE="${LS_CURSOR_SIZE:-$(( ${DISPLAY_HEIGHT:-480} / 20 ))}"
```

2. **Mouse speed follows the screen width** (generated gptk copy, base value is for 640 wide):

```
sed "s/^mouse_scale = .*/mouse_scale = $(( 512 * LS_MOUSE_SPEED * ${DISPLAY_WIDTH:-640} / 64000 ))/" \
  "$GAMEDIR/laststand.gptk" > "$GAMEDIR/laststand.run.gptk"
$GPTOKEYB "ruffle_sdl" -c "$GAMEDIR/laststand.run.gptk" &    # same for GPTOKEYB2 on muOS
```

3. **Do not patch the user's Steam file in place.** Your launcher writes two bytes into `TheLastStandLegacyCollection.swf` on every start. A failed write or an interrupted run damages the user's own file, and a Steam update or "verify files" fights it. The fix patches a copy, `TheLastStandLegacyCollection-port.swf`, checks the bytes first, and still runs the untouched original if the file is a different version. A file you already patched in place is accepted. Side effect: menu settings saved by Ruffle are keyed by the SWF path, so they reset once.

4. **Debug log fix** in the same copy: one byte at offset 1011117 (`0a` to `00`), so the corner test can never be true.

5. **Docs match the gptk**: A is Space (switch weapon), B is R (reload), X is Esc (options), Y is Shift. The old table was garbled and said Start was Pause (it sends Space). I also added that R1 is the click.

6. cfg settings added: `LS_MOUSE_SPEED`, `LS_CURSOR_IDLE_MS`, `LS_CURSOR_SIZE` (the launcher has defaults, so an old cfg still works).

## Device results (Knulli, RG35XX H, with the fixes)

* Select + Start exits cleanly through the gptokeyb hotkey.
* The Last Stand and Union City load from the menu. Ruffle peaked at about 205 MB in the menu, 290 MB in The Last Stand and 418 MB in Union City, so on 1 GB devices zram is needed for Union City (your notes already say so).
* The Last Stand 2: I did not manage to land the pointer on its entry in the time I had, so it is not verified on the device. Please test it.
* No frame rate measurements were done.

## Still needs testing

muOS (gptokeyb2 with the mouse mappings: please check the arrow moves), Rocknix RP5 (pointer speed on 1080p), dArkOS R36S (this build uses SDL on the firmware's own libs), and The Last Stand 2 everywhere. Please ask testers to send `ports/laststand/log.txt`. Note the pointer starts at the top left corner; a small follow up would be to start it in the window centre.

## Suggestions for the PortMaster PR

* Keep the `# PORTMASTER:` line 2 in your own release zip, but PortMaster reviewers ask for it to be removed in the PR launcher.
* gameinfo.xml points to `./laststand/cover.png` but the zip has no cover or screenshot (port.json `image` is null). Add `cover.png` and `screenshot.png`, each under 100 KB.
* Add the source for the ruffle_sdl build (patch list) to the README, and keep the Ruffle licence file with the binary.
* Keep the testing blocks and extra logging out of the final launcher.

## Update: author's zip of 14 October

Compared against the earlier zip. The `ruffle_sdl` binary is unchanged.

Addressed by the update:
* Menu pointer: the collection menu now draws its own arrow (xdelta patch `patches/menu-cursor.xdelta`), on by default except on ROCKNIX (`LS_SOFT_CURSOR`).
* The Steam file is still rewritten in place, but a pristine `.orig` copy is kept and the patch is applied by MD5, so the change is now reversible and version safe.
* gptokeyb2 (new `laststand.ini`) is used on every firmware that has it, not only muOS.

Still open:
* The arrow is drawn by the collection menu only. The three games are separate SWFs and their mouse driven menus still have no visible pointer. The native cursor in our `ruffle_sdl` build covers every SWF.
* ROCKNIX defaults to no arrow on the assumption that its SDL shows a cursor; the RP5 report (Rocknix) had the same problem, so this needs confirming there.
* Pointer speed: `mouse_scale 512` is unchanged (and `laststand.ini` sets no speed), still slow on large screens.
* Red debug log when the pointer has not moved: not addressed.
* `laststand.md`: Start is still listed as Pause (it sends Space), and the L1 change (m to e) is not in the table.
* `gameinfo.xml` still references a `cover.png` that is not in the zip; the `# PORTMASTER:` line is still in the launcher.
