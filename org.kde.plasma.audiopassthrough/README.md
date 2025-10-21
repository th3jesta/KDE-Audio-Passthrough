# KDE Plasma Audio Pass-Through Widget

A KDE Plasma 6 widget that enables real-time audio pass-through from input devices (microphones) to output devices (speakers/headphones), similar to the "Listen" feature in Windows.

## Features

- **Toggle Button**: Click the panel widget to enable/disable audio pass-through
- **Device Selection**: Configure input and output devices through the settings dialog
- **Visual Feedback**: Icon changes color and shows animation when pass-through is active
- **Tooltips**: Hover to see current status and device information
- **Resizable**: Customize widget size from 24x24 to 128x128 pixels
- **Auto-start**: Optional automatic enabling of pass-through on startup
- **Device Monitoring**: Automatically handles device disconnections gracefully
- **Notifications**: System notifications for status changes and errors

## Requirements

- KDE Plasma 6.0 or later
- PulseAudio or PipeWire (with PulseAudio compatibility layer)
- Qt 6 and QML support

## Installation

### Method 1: Automatic Installation

1. Navigate to the widget directory:
   ```bash
   cd org.kde.plasma.audiopassthrough
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

### Method 2: Manual Installation

1. Copy the package contents to your local widgets directory:
   ```bash
   mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.audiopassthrough
   cp -r package/* ~/.local/share/plasma/plasmoids/org.kde.plasma.audiopassthrough/
   ```

2. Restart Plasma or log out and back in to refresh the widget list.

## Adding the Widget to Your Panel

1. Right-click on your panel
2. Select "Add Widgets..."
3. Search for "Audio Pass-Through"
4. Drag the widget to your panel

## Configuration

1. Right-click on the widget in your panel
2. Select "Configure Audio Pass-Through..."
3. Configure the following options:

### Audio Devices
- **Input Device**: Select the microphone or audio input source
- **Output Device**: Select the speakers or headphones for output
- **Refresh**: Update the device list if you connect/disconnect devices

### Widget Appearance
- **Width**: Set widget width (24-128 pixels)
- **Height**: Set widget height (24-128 pixels)
- **Reset to Default Size**: Restore default 32x32 pixel size

### Behavior
- **Auto-start**: Enable pass-through automatically when the widget loads

## Usage

- **Click** the widget icon to toggle audio pass-through on/off
- **Hover** over the widget to see current status and device information
- The icon changes from microphone (inactive) to volume (active) with color feedback
- A small animated indicator appears when pass-through is active

## Technical Details

The widget uses PulseAudio's `module-loopback` functionality to create real-time audio routing between selected devices. It's compatible with both PulseAudio and PipeWire audio systems.

### Audio Latency
The widget configures a 50ms latency buffer for stable audio pass-through. This provides a good balance between audio quality and system performance.

## Troubleshooting

### No Audio Devices Detected
- Ensure your audio system (PulseAudio/PipeWire) is running
- Check that your input/output devices are recognized by the system
- Try refreshing the device list in the configuration dialog

### Pass-Through Not Working
- Verify both input and output devices are connected and functional
- Check that no other applications are exclusively using the audio devices
- Look at the system notifications for error messages
- Test devices with other audio applications

### Widget Not Appearing
- Ensure you're running KDE Plasma 6.0 or later
- Verify the widget files are correctly installed in `~/.local/share/plasma/plasmoids/`
- Try restarting Plasma: `systemctl --user restart plasma-plasmashell`

### Permission Issues
- Ensure your user has access to audio devices
- Check that you're in the `audio` group: `groups $USER`
- Verify PulseAudio/PipeWire is running in user mode

## Uninstallation

To remove the widget:

```bash
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.audiopassthrough
```

Then restart Plasma or log out and back in.

## Development

This widget is built using:
- QML for the user interface
- JavaScript for audio device management
- KDE Plasma APIs for integration
- PulseAudio Qt bindings for audio control

### File Structure
```
package/
├── metadata.json              # Widget metadata and properties
├── contents/
│   ├── ui/
│   │   ├── main.qml          # Main widget interface
│   │   ├── configGeneral.qml # Configuration dialog
│   │   └── AudioManager.qml  # Audio device management
│   └── config/
│       ├── config.qml        # Configuration dialog structure
│       └── main.xml          # Configuration schema
```

## License

This project follows KDE's licensing practices. Please refer to the individual file headers for specific license information.

## Contributing

Contributions are welcome! Please follow KDE's development guidelines and coding standards when submitting patches or improvements.

## Support

For issues and bug reports, please check the troubleshooting section above first. For additional support, refer to the KDE community forums and documentation. 