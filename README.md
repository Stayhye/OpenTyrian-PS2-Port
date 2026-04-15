# OpenTyrian PS2 Port

A work-in-progress port of [OpenTyrian](https://github.com/opentyrian/opentyrian) (the open-source port of the DOS shoot-em-up Tyrian 2000) to the PlayStation 2 using the [PS2DEV](https://github.com/ps2dev) homebrew toolchain.

![Tyrian Title Screen on PS2](screenshots/title_screen.jpg)

## Current Status: Title Screen Reached — Input WIP

The game compiles, links, boots on real PS2 hardware, loads all game data from USB, and renders the full title screen with menu items. Controller input is the current focus — SDL's joystick layer detects the DualShock 2 but input mapping is still being debugged.

### What Works

- **Compiles and links** against PS2DEV toolchain (ee-gcc targeting MIPS R5900)
- **Boots on real PS2 hardware** via uLaunchELF from USB
- **IOP module loading** — SIO2MAN, PADMAN, USBD, BDM, FATFS, and USBMASS_BD are embedded in the ELF and loaded at startup
- **USB filesystem access** — reads Tyrian data files from `mass0:/` using the BDM/FATFS driver stack
- **SDL 1.2 video** — 320x200x16bpp via PS2 SDL port with gsKit backend, using nn_16 scaler
- **Game data loading** — palette, sprites, shapes, music data, sound effects, level data, help text all load successfully
- **Title screen rendering** — full title screen with Tyrian logo, menu items, and animations
- **Audio initialization** — SDL audio subsystem initializes (sound playback untested)
- **File-based debug logging** — writes diagnostic log to USB for debugging without serial/network

### What Doesn't Work Yet

- **Controller input** — SDL detects 2 joysticks (DualShock 2) with correct axes/buttons/hats, and hat + button input has been confirmed readable via SDL joystick API, but the input→keyboard event pipeline isn't fully connected yet. A custom `ps2_pad_poll` system is in progress to read the pad via SDL joystick and inject SDL keyboard events
- **Audio playback** — audio init succeeds but no sound output has been confirmed yet
- **Save/load** — save directory is configured (`mass0:/OPENTYRI/SAVE/`) but no save files are written yet since gameplay hasn't been reached
- **Palette fading** — `SDL_GetTicks()` doesn't work properly on PS2, so all fade effects are bypassed (instant palette changes instead of gradual fades)
- **Timing** — `wait_delay` and `service_wait_delay` use simplified PS2 bypasses since the SDL timer subsystem doesn't behave correctly

## Building

### Prerequisites

- PS2DEV toolchain installed (`ps2dev/ps2dev` on GitHub)
- Environment variables configured:

```bash
export PS2DEV=/usr/local/ps2dev
export PS2SDK=$PS2DEV/ps2sdk
export GSKIT=$PS2DEV/gsKit
export PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin:$PS2SDK/bin
```

- SDL 1.2 PS2 port built and installed in `$PS2SDK/ports/` (from `ps2dev/ps2sdk-ports`)
- gsKit built and installed (from `ps2dev/gsKit`)

### Source

This is based on OpenTyrian **v2.1.20130907** — the last release that uses SDL 1.2. The current `master` branch of OpenTyrian uses SDL2, which has a PS2 backend but would require different porting work.

### Generating Embedded IOP Modules

The PS2 port embeds IOP driver modules (IRX files) directly into the ELF binary so they can be loaded after the IOP reset without needing external files. These must be generated before building:

```bash
bin2c $PS2SDK/iop/irx/usbd.irx src/usbd_irx.c usbd_irx
bin2c $PS2SDK/iop/irx/bdm.irx src/bdm_irx.c bdm_irx
bin2c $PS2SDK/iop/irx/bdmfs_fatfs.irx src/bdmfs_fatfs_irx.c bdmfs_fatfs_irx
bin2c $PS2SDK/iop/irx/usbmass_bd.irx src/usbmass_bd_irx.c usbmass_bd_irx
bin2c $PS2SDK/iop/irx/sio2man.irx src/sio2man_irx.c sio2man_irx
bin2c $PS2SDK/iop/irx/padman.irx src/padman_irx.c padman_irx
```

### Compiling

```bash
mkdir -p obj
make -f Makefile.ps2
```

This produces `opentyrian.elf`.

## Running on PS2

### USB Setup

Format a USB drive as FAT32 and create the following structure:

```
USB Drive
└── OPENTYRI/
    ├── opentyrian.elf
    ├── SAVE/              (empty directory for future saves)
    └── DATA/
        ├── tyrian1.lvl
        ├── tyrian.shp
        ├── palette.dat
        ├── music.mus
        ├── tyrian.snd
        ├── voices.snd
        ├── tyrian.hdt
        ├── tyrian.pic
        └── ... (all Tyrian 2.1 data files, lowercase)
```

Tyrian 2.1 data files are freeware and can be downloaded from: https://camanis.net/tyrian/tyrian21.zip

### Booting

1. Install FreeMCBoot (FMCB) on a PS2 memory card if you haven't already
2. Copy uLaunchELF to the memory card
3. Plug the USB drive into the PS2
4. Boot uLaunchELF, navigate to `mass:/OPENTYRI/`
5. Run `opentyrian.elf`

### Debug Log

The port writes a diagnostic log to `mass0:/OPENTYRI/log.txt` on the USB drive. This logs every file open attempt, initialization step, and various checkpoints. Pull the USB drive and check this file on a PC to debug issues.

## Architecture & Porting Notes

### PS2-Specific Files

| File | Purpose |
|------|---------|
| `Makefile.ps2` | PS2 build system using ps2sdk's Makefile.pref/Makefile.eeglobal |
| `src/ps2_init.c/h` | IOP reset, module loading, USB driver init, `ps2_log()` function |
| `src/ps2_pad.c/h` | DualShock 2 controller reading via SDL joystick API, injects SDL keyboard events |
| `src/*_irx.c` | Embedded IOP modules (generated by `bin2c`) |

### Key Porting Changes

**IOP Module Loading (`ps2_init.c`):**
After IOP reset, the port loads embedded IRX modules in this order: SIO2MAN → PADMAN → USBD → BDM → BDMFS_FATFS → USBMASS_BD. A 4-second delay follows to allow USB device enumeration.

**Video (`src/video.c`):**
The scaler system is bypassed on PS2. Video is initialized at 320x200x16bpp using `SDL_SetVideoMode`, and the `nn_16` nearest-neighbor scaler converts the game's 8bpp paletted surfaces to 16bpp for display.

**File Paths (`src/file.c`, `src/config.c`):**
`data_dir()` is hardcoded to return `mass0:/OPENTYRI/DATA` on PS2. User directory (saves/config) points to `mass0:/OPENTYRI/SAVE`.

**Timing (`src/nortsong.c`, `src/palette.c`):**
`SDL_GetTicks()` doesn't work reliably on PS2, causing infinite loops in fade and delay functions. All fade functions (`fade_palette`, `fade_solid`) skip the gradual fade and apply the final palette immediately. `wait_delay` and `service_wait_delay` use minimal `SDL_Delay(1)` bypasses.

**Missing Headers:**
Several source files needed explicit `#include <string.h>`, `#include <stdlib.h>`, `#include <ctype.h>`, and `#include <unistd.h>` added — the PS2 newlib is stricter about implicit declarations than desktop GCC.

**Multiple Definition Errors (`opl.h`):**
The OPL (AdLib emulation) header defines global variables directly in the header. Compiled with `-fcommon` to allow this without linker errors on newer GCC versions.

## What's Next

1. **Fix controller input** — complete the SDL joystick → keyboard event pipeline so the DualShock 2 can navigate menus and play the game
2. **Test audio output** — verify sound effects and music play through the PS2's SPU2 via SDL audio
3. **Fix timing** — investigate why `SDL_GetTicks()` returns incorrect values and implement a proper PS2 timer
4. **Gameplay testing** — once input works, test actual gameplay (shooting, movement, level progression)
5. **Performance optimization** — profile and optimize if needed (though a 2D DOS game from 1995 should run fine on PS2)
6. **Clean up debug logging** — remove verbose logging once stable
7. **CD/DVD boot** — create a bootable disc image with SYSTEM.CNF

## Credits

- **OpenTyrian** — The OpenTyrian Development Team (GPL v2)
- **Original Tyrian** — Jason Emery / Epic MegaGames (released as freeware)
- **PS2DEV** — The ps2dev community for the homebrew SDK
- **PS2 SDL Port** — Contributors to the SDL 1.2 PS2 port in ps2sdk-ports

## License

This port inherits OpenTyrian's license: **GNU General Public License v2**.
