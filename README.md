# KDE Plasma Audio Pass-Through

A Plasma 6 widget that lets you route live audio from any available input device to any output device with a single click. Perfect for quick monitoring, ad-hoc routing, and accessibility scenarios.

## Key Features
- Toggle pass-through instantly from your panel
- Keep your preferred input/output devices persistent across sessions
- Optional auto-start to enable routing as soon as Plasma loads
- Visual feedback: green when active, red on error, animated indicator while routing
- Friendly tooltips with device names and status
- Configurable widget size (24–128 px) to fit any panel layout
- Graceful handling of device changes and errors, with logging for debugging

## Requirements
- KDE Plasma 6.0+
- PipeWire or PulseAudio (with the PulseAudio compatibility layer when using PipeWire)
- `pactl` available in `PATH`

## Installation

### One-liner
```bash
plasmapkg2 --install org.kde.plasma.audiopassthrough.plasmoid
```
(Generate the plasmoid package with `plasmapkg2 --pack package --output org.kde.plasma.audiopassthrough.plasmoid` if you prefer manual packaging.)

### Using the included script
```bash
cd org.kde.plasma.audiopassthrough
./install.sh
```

### Manual setup
```bash
mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.audiopassthrough
cp -r package/* ~/.local/share/plasma/plasmoids/org.kde.plasma.audiopassthrough/
```
Restart Plasma or log out/in if the widget list doesn’t refresh automatically.

## Adding the Widget
1. Right-click your panel → `Add Widgets…`
2. Search for `Audio Pass-Through`
3. Drag it onto your panel and release

## Configuration
Open `Configure Audio Pass-Through…` from the widget’s context menu to adjust:
- `Input Device` and `Output Device` (pulls live data from PipeWire/PulseAudio)
- `Auto-start on load`
- `Widget width/height` with live validation and reset-to-default option

Changing devices while pass-through is active will restart the loopback with the new selection.

## How It Works
Under the hood the widget issues `pactl load-module module-loopback source=<input> sink=<output> latency_msec=50`. The module index is tracked so that `pactl unload-module` reverses routing cleanly. Errors are surfaced in the UI and logged to an internal debug file for easier troubleshooting.

## Troubleshooting
- `Please configure input and output devices first`: open the config dialog and pick devices.
- `Failed to enable …`: usually indicates PipeWire/PulseAudio could not load the loopback module—check if the devices are in use elsewhere.
- Widget disappeared? Make sure you’re running Plasma 6 and refresh your panel: `systemctl --user restart plasma-plasmashell`.

## Packaging for KDE Store
1. Update `metadata.json` with accurate `Version`, `Website`, and `BugReportUrl` values.
2. Run `plasmapkg2 --pack package --output org.kde.plasma.audiopassthrough.plasmoid`.
3. Prepare screenshots, changelog, and a short description.
4. Upload the `.plasmoid` archive to the KDE Store.

## Development Notes
Project layout:
```
org.kde.plasma.audiopassthrough/
├── package/
│   ├── metadata.json
│   ├── contents/
│   │   ├── ui/
│   │   │   ├── main.qml
│   │   │   └── configGeneral.qml
│   │   └── config/
│   │       ├── config.qml
│   │       └── main.xml
├── install.sh
└── README.md (this file)
```

`main.qml` manages toggle logic, status UI, and loopback module handling. `configGeneral.qml` builds the device selection and sizing UI, issuing live `pactl` queries via Plasma’s `DataSource` executable engine.

## License
Copyright © 2025 <Your Name>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. 