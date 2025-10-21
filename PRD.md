Product Requirements Document: KDE Plasma Audio Pass-Through Widget
1. Introduction
The Audio Pass-Through Widget is a KDE Plasma 6+ panel widget that allows users to toggle audio pass-through from a selected input device (e.g., a microphone) to a selected output device (e.g., speakers or headphones). This functionality enables real-time audio routing for testing or monitoring purposes, similar to the "Listen" checkbox in Windows. The widget is fully configurable, allowing users to select from available audio devices and resize the widget to their preferred dimensions.

This PRD provides a detailed specification for building the widget using QML, JavaScript, and KDE Plasma APIs, ensuring compatibility with both PulseAudio and PipeWire (via PipeWire’s PulseAudio compatibility layer). The document is structured to guide AI tools like Cursor or Claude CLI in implementing the project without requiring additional user intervention beyond this PRD.

2. Features
The widget must include the following features:

Toggle Audio Pass-Through
A clickable icon in the Plasma panel to enable or disable audio pass-through.
Visual feedback on the icon (e.g., color change or overlay) to indicate whether pass-through is active.
Device Selection
A configuration dialog with dropdown menus to select the input device (source) and output device (sink).
Displays user-friendly device names for easy identification.
Persistence
Saves the selected input and output devices, as well as the widget's dimensions, across Plasma sessions.
Includes an optional setting to automatically enable pass-through on startup (disabled by default).
Dynamic Device Handling
Updates the list of available devices in real-time as they are connected or disconnected.
Gracefully handles cases where selected devices become unavailable (e.g., by disabling pass-through or selecting default devices).
Error Handling
Manages errors such as failure to enable pass-through due to unavailable devices or system issues.
Provides user feedback (e.g., tooltip or notification) when pass-through cannot be activated.
Internationalization
Supports multiple languages using KDE’s i18n framework for global accessibility.
Resizable Widget
Allows users to set the widget's width and height (in pixels) via the configuration dialog.
Enforces minimum (24x24 pixels) and maximum (128x128 pixels) size constraints.
Includes a "Reset to Default Size" option to revert to automatic sizing based on panel orientation.
3. Technical Requirements
The widget must adhere to the following technical specifications:

Development Environment
Written in QML and JavaScript, utilizing the KDE Plasma API.
Must follow KDE’s coding standards and best practices.
Audio Management
Uses PulseAudio Qt bindings to interact with audio devices and manage routing.
Ensures compatibility with both PulseAudio and PipeWire (via PipeWire’s PulseAudio compatibility layer).
Configuration Storage
Stores settings (selected devices, widget size, auto-start option) in the widget’s configuration file using Plasma’s configuration API.
Design Standards
Follows the KDE Human Interface Guidelines for a consistent and intuitive user experience.
4. User Interface
The widget's user interface consists of two main components:

Panel Widget
Appearance: An icon (e.g., a microphone with an arrow to a speaker) in the system tray that toggles pass-through when clicked.
Feedback: A tooltip displaying the current pass-through state and selected devices.
Resizing: The widget respects user-defined dimensions (width and height in pixels) set via the configuration dialog, within enforced minimum (24x24 pixels) and maximum (128x128 pixels) limits.
Configuration Dialog
Components:
Two dropdown menus: one for selecting the input device and one for selecting the output device.
Two input fields: for setting the widget's width and height in pixels.
A checkbox to enable auto-start of pass-through on login.
A "Reset to Default Size" button to revert to automatic sizing.
"Apply" and "Cancel" buttons to save or discard changes.
Behavior:
Populates dropdowns with available devices and recalls saved selections.
Validates size inputs to ensure they are within the allowed range (24-128 pixels).
Applies changes immediately upon clicking "Apply."
5. Implementation Details
The following details outline how key functionalities should be implemented:

Audio Routing
Use PulseAudio.Context from PulseAudio Qt bindings to:
List available input devices (sources) and output devices (sinks).
Load the module-loopback with the selected source and sink to enable pass-through.
Unload the loopback module to disable pass-through.
Track the loaded loopback module’s index to ensure proper unloading and prevent duplicate modules.
Configuration Storage
Save selected device names, widget dimensions, and auto-start preference in the widget’s configuration file.
Use Plasma’s plasmoid.configuration API to read and write settings.
Resizable Widget
Use QML’s plasmoid object to set the widget’s width and height based on user input.
Enforce size constraints in JavaScript, adjusting to minimum (24x24 pixels) or maximum (128x128 pixels) if necessary.
Listen for panel resize events and adapt the widget’s size dynamically while prioritizing user settings.
Dynamic Device Handling
Monitor device changes using PulseAudio’s subscription mechanism.
Update dropdown menus in the configuration dialog when devices are added or removed.
If a selected device becomes unavailable, disable pass-through and notify the user.
Error Handling
Catch errors when loading or unloading the loopback module.
Display a notification or update the tooltip to inform the user of any issues.
Internationalization
Use KDE’s i18n framework for all user-facing strings to support multiple languages.
6. Testing
The widget must undergo thorough testing to ensure functionality and robustness:

Functionality Testing
Verify that the widget correctly lists all available input and output devices.
Test toggling pass-through to ensure audio routes correctly from the selected input to the output device.
Confirm that the widget respects user-defined dimensions and adjusts appropriately on the panel.
Robustness Testing
Test the widget’s behavior when devices are connected or disconnected.
Ensure that configuration settings (devices, size, auto-start) persist across Plasma sessions.
Verify that the widget handles errors gracefully (e.g., unavailable devices) without crashing.
Compatibility Testing
Test with both PulseAudio and PipeWire backends to ensure seamless operation.
Confirm that the widget functions correctly in both horizontal and vertical panel orientations.
User Experience Testing
Ensure that the configuration dialog is intuitive and that size inputs are validated properly.
Verify that the "Reset to Default Size" option works as expected.
7. Distribution
The widget should be packaged as a Plasma add-on for easy installation:

Packaging
Include all necessary QML, JavaScript, and metadata files.
Ensure the widget is installable via the KDE Store or manually by users.
Documentation
Provide a brief user guide within the widget’s metadata or as a separate file.
Include instructions on how to configure the widget and troubleshoot common issues.