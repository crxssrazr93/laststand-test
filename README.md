# The Last Stand Legacy Collection: PortMaster test fixes

Test results and fixes for the PortMaster port of The Last Stand Legacy Collection by thelaggypyro (Ruffle, `ruffle_sdl`). This repository does not contain the port itself or any game files.

## Contents

| Path | What it is |
|---|---|
| `FEEDBACK.md` | Problems found, fixes, and test results for the port author |
| `ruffle-patch/` | Software cursor patch for `ruffle_sdl`, so the mouse pointer is visible on handhelds |
| `tests/` | Scripts used to drive and check the port on a device |

The fixed port zip is attached to the latest release.

## Main finding

The collection menu and the game menus are mouse only, and `ruffle_sdl` hides the system cursor. On devices without a touch screen the pointer moves but cannot be seen, so testers could not get past the main screen. The cursor patch draws the pointer in `ruffle_sdl` itself, which works on every firmware and in every game of the collection. The Last Stand 2 also drew a black screen on the Mali GPU; the launcher sets `RUFFLE_EMPTY_TEXTURES=0` to fix it.

Tested on an Anbernic RG35XX H with Knulli. See `FEEDBACK.md` for details.

## Status

Test release `test-1`. Checked on the RG35XX H (Knulli): the menu and all three games start with the pad only, the pointer is visible and starts in the centre, and The Last Stand 2 renders and plays.

Not checked yet:

* Select + Start exit in every game, and pointer speed with classic gptokeyb
* Frame rate, audio and saves in each game
* Every button in the controls table
* Second launch, a replaced Steam file, an unknown game version, and the GOG layout
* An option to stretch the picture to fill 4:3 screens
* muOS, ROCKNIX and dArkOS
