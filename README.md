# ScrDex

Turn your Android device into a desktop-like experience using Taskbar and scrcpy.

ScrDex is a Bash-based automation tool designed to configure an Android device for a desktop-style experience and control it from a Windows PC.

It combines Android ADB commands, Taskbar, and scrcpy to configure the device, enable desktop-oriented Android features, and start a high-quality screen mirroring session.

---

## Features

- Automatic Android device detection through ADB
- USB debugging setup guidance
- ADB connection and device status checks
- Device information and log checks
- Automatic Taskbar configuration
- Taskbar Accessibility Service setup
- Android Freeform Window support
- External display support
- Automatic restoration of the original Android configuration
- Up to 60 FPS screen mirroring
- Turn off the physical phone screen while mirroring

---

## How ScrDex Works

ScrDex acts as an automation layer between the Android device and the desktop software used to control it.
```

                 ┌──────────────┐
                 │   ScrDex    │
                 │ automation   │
                 └──────┬───────┘
                        │
             ┌──────────┼──────────┐
             │          │          │
             ▼          ▼          ▼
            ADB      Taskbar    scrcpy
             │          │          │
             └──────────┼──────────┘
                        │
                        ▼
                  Android device
```
- **ADB** is used to communicate with the Android device and configure system settings.
- **Taskbar** provides the desktop-style Android interface, including its taskbar, launcher functionality, and multitasking features.
- **scrcpy** provides video mirroring and computer-side control of the Android device.

---

## Requirements

### PC
- Linux
- A USB cable capable of data transfer (2.0 or above)
- Patience

### Android Device
- Android device with USB debugging support
- USB debugging enabled
- Permission to enable the required Android accessibility and system settings

---

## Dependencies & Credits

### scrcpy
ScrDex uses scrcpy, developed and maintained by Genymobile and its contributors.

scrcpy is free and open-source software that mirrors and controls Android devices from a computer.

- **Official Repository:** [https://github.com/Genymobile/scrcpy](https://github.com/Genymobile/scrcpy)

The official scrcpy project is the only official source for scrcpy releases. ScrDex may distribute an official Linux scrcpy release together with its own release package.

> **Note:** ScrDex does not claim ownership of scrcpy or its source code. scrcpy is licensed under the Apache License, Version 2.0. For the complete scrcpy license and copyright information, see the files included with the corresponding scrcpy release.

### ADB
ScrDex uses Android Debug Bridge (ADB) to communicate with the Android device.

The Linux release of scrcpy includes the required ADB components, so a separate ADB installation is not required when using the bundled scrcpy release.

ADB is used by ScrDex for operations such as:
- Detecting the Android device
- Reading device information
- Installing and configuring Taskbar
- Changing Android system settings
- Configuring accessibility services
- Configuring input methods
- Starting applications
- Restoring the original configuration

### Taskbar
ScrDex uses Taskbar by Braden Farmer and contributors.

Taskbar provides the desktop-style Android interface used by ScrDex.

- **Official Repository:** [https://github.com/farmerbb/Taskbar](https://github.com/farmerbb/Taskbar)

ScrDex does not include the Taskbar source code. Taskbar will automaticaly be installed separately on the Android device.

---

## Installation

### 1. Download ScrDex
Download the latest ScrDex release from the GitHub Releases page.

If the release includes scrcpy, extract the complete ScrDex package to a folder on your Linux PC. **Do not remove the files included with the scrcpy release.**


### 2. Enable USB Debugging
On the Android device:
1. Open **Settings**
2. Open **About phone / System information**
3. Find **Build number / Version build**
4. Tap it seven times (or as required) to enable Developer Options
5. Return to **Settings**
6. Open **Developer options**
7. Enable **USB debugging**
8. Connect the Android device to the PC
9. Accept the *"Allow USB debugging?"* RSA prompt on your device

### 3. Start ScrDex
Run the ScrDex script from the ScrDex directory.

ScrDex will check the ADB connection and guide you through the required Taskbar configuration.

---

## Android Configuration

During execution, ScrDex may temporarily modify Android system settings. These can include:
- Display size
- Display density
- Font scale
- Enabled input methods
- Default input method
- Accessibility services
- Freeform window support
- External display support
- Default home application

Before changing these settings, ScrDex stores the original values whenever possible. When the scrcpy session ends, ScrDex attempts to restore the original configuration. **PLEASE DO NOT UNPLUG THE CABLE. CLOSE SCRDEX FIRST, THEN WAIT 1 SECOND TO RESTORE YOUR SETTINGS.**

### Display Configuration
ScrDex configures the Android display for the desktop-style environment.

The temporary configuration used by the current release is:
- **Resolution:** 2160x3840
- **Density:** 400
- **Font scale:** 1.5

The original display configuration is saved before these changes are applied and restored after the session.

### Keyboard / IME Handling
ScrDex temporarily manages Android input methods while the desktop environment is active.

The script:
- Detects enabled input methods
- Saves the original configuration
- Temporarily disables enabled keyboards
- Removes the Google Voice Input service from the active IME configuration
- Disables Google TTS when required
- Restores the original keyboard configuration when the session ends

The original enabled input method configuration is preserved so that ScrDex can attempt to return the device to its previous state.

---

## scrcpy Configuration

The current ScrDex session starts scrcpy using:

```bash
./scrcpy \
    --video-bit-rate=25M \
    --max-fps=60 \
    --video-codec=h265 \
    --turn-screen-off
```
## License

ScrDex is licensed under the [MIT License](LICENSE).

### Third-Party Software
This package bundles or uses third-party software:

- **scrcpy**: Developed by [Genymobile](https://github.com/Genymobile/scrcpy) and contributors, licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0). 
  - The original copyright and license files for `scrcpy` are preserved and included alongside its binaries in this release.

##**BIG DISCLAMER**
  **ONLY TESTED ON SAMSUNG PHONES**
