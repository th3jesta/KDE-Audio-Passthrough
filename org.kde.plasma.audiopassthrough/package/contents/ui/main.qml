import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

// Use Plasma5Support for command execution in Plasma 6
import org.kde.plasma.plasma5support 2.0 as P5Support

PlasmoidItem {
    id: root
    
    // Widget sizing properties
    Layout.minimumWidth: Math.max(24, plasmoid.configuration.widgetWidth || 32)
    Layout.minimumHeight: Math.max(24, plasmoid.configuration.widgetHeight || 32)
    Layout.preferredWidth: Math.min(128, plasmoid.configuration.widgetWidth || 32)
    Layout.preferredHeight: Math.min(128, plasmoid.configuration.widgetHeight || 32)
    
    // Audio pass-through state
    property bool isPassThroughActive: false
    property string inputDevice: plasmoid.configuration.inputDevice || ""
    property string outputDevice: plasmoid.configuration.outputDevice || ""
    property bool autoStart: plasmoid.configuration.autoStart || false
    
    // Loopback module tracking
    property int loopbackModuleIndex: -1
    property bool commandInProgress: false
    property string lastError: ""
    
    // Debug lastError changes
    onLastErrorChanged: {
        console.log("🔴 lastError changed to:", lastError)
        console.log("   Icon should now be:", lastError !== "" ? "RED" : (root.isPassThroughActive ? "GREEN" : "DEFAULT"))
        
        // Also write to a debug file
        var debugMsg = new Date().toISOString() + " - lastError changed to: " + lastError + "\n"
        debugMsg += "   Icon should be: " + (lastError !== "" ? "RED" : (root.isPassThroughActive ? "GREEN" : "DEFAULT")) + "\n"
        writeDebugFile(debugMsg)
    }
    
    // Command execution using Plasma5Support
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            console.log("=== COMMAND RESULT ===")
            console.log("Command:", sourceName)
            console.log("Exit code:", data["exit code"])
            console.log("Raw stdout:", JSON.stringify(data.stdout))
            console.log("Raw stderr:", JSON.stringify(data.stderr))
            console.log("Full data object:", JSON.stringify(data))
            console.log("=======================")
            
            // Debug to file
            writeDebugFile("COMMAND: " + sourceName + " | Exit: " + data["exit code"] + " | Stdout: " + JSON.stringify(data.stdout) + " | Stderr: " + JSON.stringify(data.stderr))
            
            disconnectSource(sourceName)
            commandInProgress = false
            
            if (sourceName.includes("load-module")) {
                handleLoadModuleResult(data)
            } else if (sourceName.includes("unload-module")) {
                handleUnloadModuleResult(data)
            }
        }
    }
    
    // Timer for clearing errors after a delay
    Timer {
        id: errorClearTimer
        interval: 5000
        onTriggered: {
            if (lastError.includes("Failed to disable")) {
                lastError = ""
            }
        }
    }
    
    Component.onCompleted: {
        // Debug: Widget loaded
        writeDebugFile("Widget loaded at " + new Date().toISOString())
        
        // Auto-start if enabled and devices configured
        if (autoStart && inputDevice && outputDevice && inputDevice !== "" && outputDevice !== "") {
            Qt.callLater(function() {
                togglePassThrough()
            })
        }
    }
    
    // Tooltip
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        icon: "audio-speakers"
        mainText: i18n("Audio Pass-Through")
        subText: {
            if (commandInProgress) {
                return i18n("Processing...")
            } else if (lastError) {
                return i18n("Error: %1", lastError)
            } else if (root.isPassThroughActive) {
                return i18n("Active: %1 → %2", getDeviceDisplayName(root.inputDevice), getDeviceDisplayName(root.outputDevice))
            } else {
                return i18n("Inactive - Click to enable")
            }
        }
    }
    
    // Main widget content
    PlasmaComponents3.Button {
        id: toggleButton
        anchors.fill: parent
        enabled: !commandInProgress
        
        // Icon with visual feedback
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width - 4, parent.height - 4)
            height: width
            source: "audio-speakers"
            color: {
                var result
                if (lastError !== "") {
                    result = Kirigami.Theme.negativeTextColor
                    console.log("🎨 Icon color: RED (error:", lastError, ")")
                } else if (root.isPassThroughActive) {
                    result = Kirigami.Theme.positiveTextColor
                    console.log("🎨 Icon color: GREEN (active)")
                } else {
                    result = Kirigami.Theme.textColor
                    console.log("🎨 Icon color: DEFAULT (inactive)")
                }
                return result
            }
            
            // Animated indicator overlay
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 8
                height: 8
                radius: 4
                color: root.isPassThroughActive ? Kirigami.Theme.positiveTextColor : "transparent"
                border.color: Kirigami.Theme.backgroundColor
                border.width: 1
                visible: root.isPassThroughActive
                
                SequentialAnimation on opacity {
                    running: root.isPassThroughActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800 }
                    NumberAnimation { to: 1.0; duration: 800 }
                }
            }
            
            // Processing indicator
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.3
                height: parent.height * 0.3
                radius: width / 2
                color: Kirigami.Theme.highlightColor
                visible: commandInProgress
                
                RotationAnimation on rotation {
                    running: commandInProgress
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
        }
        
        onClicked: togglePassThrough()
        
        // Hover effect
        background: Rectangle {
            color: toggleButton.hovered ? Kirigami.Theme.highlightColor : "transparent"
            opacity: toggleButton.hovered ? 0.1 : 0
            radius: 4
            
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }
    
    // Functions
    function togglePassThrough() {
        console.log("=== TOGGLE PASS-THROUGH ===")
        console.log("isPassThroughActive:", root.isPassThroughActive)
        console.log("commandInProgress:", commandInProgress)
        console.log("lastError before toggle:", lastError)
        
        // Debug to file
        writeDebugFile("TOGGLE clicked - isActive: " + root.isPassThroughActive + ", lastError: " + lastError)
        
        if (commandInProgress) {
            console.log("Command in progress, returning")
            return
        }
        
        if (!inputDevice || !outputDevice || inputDevice === "" || outputDevice === "") {
            lastError = "Please configure input and output devices first"
            console.log("No devices configured, setting error:", lastError)
            return
        }
        
        // Clear previous error and stop any error clear timer
        lastError = ""
        errorClearTimer.stop()
        console.log("Cleared errors, proceeding with toggle")
        
        if (root.isPassThroughActive) {
            console.log("Currently active, calling disablePassThrough()")
            disablePassThrough()
        } else {
            console.log("Currently inactive, calling enablePassThrough()")
            enablePassThrough()
        }
        console.log("============================")
    }
    
    function enablePassThrough() {
        if (commandInProgress) {
            return
        }
        
        commandInProgress = true
        
        // Build pactl command to load loopback module
        var command = "pactl load-module module-loopback"
        
        // Add source parameter
        if (inputDevice !== "default") {
            command += " source=" + inputDevice
        }
        
        // Add sink parameter  
        if (outputDevice !== "default") {
            command += " sink=" + outputDevice
        }
        
        // Add latency settings for better real-time performance
        command += " latency_msec=50"
        
        console.log("=== ENABLE PASS-THROUGH ===")
        console.log("Input device:", inputDevice)
        console.log("Output device:", outputDevice)
        console.log("Final command:", command)
        console.log("============================")
        
        // Debug to file
        writeDebugFile("ENABLE command: " + command)
        
        executable.connectSource(command)
    }
    
    function disablePassThrough() {
        console.log("=== DISABLE PASS-THROUGH ===")
        console.log("commandInProgress:", commandInProgress)
        console.log("loopbackModuleIndex:", loopbackModuleIndex)
        
        if (commandInProgress) {
            console.log("Command in progress, returning")
            return
        }
        
        if (loopbackModuleIndex === -1) {
            console.log("No module index, setting inactive and returning")
            root.isPassThroughActive = false
            return
        }
        
        commandInProgress = true
        
        var command = "pactl unload-module " + loopbackModuleIndex
        console.log("Executing command:", command)
        executable.connectSource(command)
        console.log("==============================")
    }
    
    function handleLoadModuleResult(data) {
        console.log("=== LOAD MODULE RESULT ===")
        console.log("Exit code:", data["exit code"])
        console.log("Raw stdout:", JSON.stringify(data.stdout))
        console.log("Raw stderr:", JSON.stringify(data.stderr))
        
        if (data["exit code"] === 0) {
            // Command successful - extract module index from stdout
            var output = data.stdout.trim()
            console.log("Trimmed output:", JSON.stringify(output))
            console.log("Output length:", output.length)
            console.log("Is numeric?", !isNaN(output))
            console.log("parseInt result:", parseInt(output))
            
            if (output && !isNaN(output)) {
                loopbackModuleIndex = parseInt(output)
                root.isPassThroughActive = true
                console.log("✅ Loopback module loaded with index:", loopbackModuleIndex)
                lastError = ""  // Clear any previous errors
            } else {
                console.error("❌ Failed to parse module index - output was:", JSON.stringify(output))
                lastError = "Failed to parse module index: '" + output + "'"
                root.isPassThroughActive = false
            }
        } else {
            // Command failed
            var error = data.stderr || "Unknown error"
            console.error("❌ Failed to load loopback module:", error)
            lastError = "Failed to enable: " + error
            root.isPassThroughActive = false
        }
        console.log("==========================")
    }
    
    function handleUnloadModuleResult(data) {
        console.log("=== UNLOAD RESULT HANDLER ===")
        console.log("Exit code:", data["exit code"])
        console.log("loopbackModuleIndex before:", loopbackModuleIndex)
        console.log("isPassThroughActive before:", root.isPassThroughActive)
        console.log("lastError before:", lastError)
        
        if (data["exit code"] === 0) {
            // Command successful
            console.log("✅ Unload successful")
            root.isPassThroughActive = false
            loopbackModuleIndex = -1
            lastError = ""  // Clear any previous errors
        } else {
            // Command failed, but this is often not a real problem
            var error = data.stderr || "Unknown error"
            console.log("❌ Unload failed with error:", error)
            
            // For unload operations, don't show error to user since module might already be gone
            // Just reset state and clear any previous errors
            root.isPassThroughActive = false
            loopbackModuleIndex = -1
            lastError = ""  // Clear errors since we're resetting state anyway
        }
        
        console.log("isPassThroughActive after:", root.isPassThroughActive)
        console.log("lastError after:", lastError)
        console.log("==============================")
        
        // Debug to file
        writeDebugFile("UNLOAD result - exit code: " + data["exit code"] + ", stderr: " + (data.stderr || "none") + ", lastError after: " + lastError)
    }
    
    function getDeviceDisplayName(deviceName) {
        if (!deviceName || deviceName === "default") {
            return "Default"
        }
        
        // Try to make device names more readable
        if (deviceName.includes("usb")) {
            if (deviceName.includes("PreSonus")) return "PreSonus AudioBox"
            if (deviceName.includes("Logitech")) return "USB Headset"
            return "USB Device"
        } else if (deviceName.includes("pci")) {
            if (deviceName.includes("hdmi")) return "HDMI Output"
            return "Built-in Audio"
        }
        
        return deviceName.substring(0, 20) + (deviceName.length > 20 ? "..." : "")
    }
    
    // Configuration handling
    Connections {
        target: plasmoid.configuration
        function onInputDeviceChanged() {
            root.inputDevice = plasmoid.configuration.inputDevice
            
            if (root.isPassThroughActive) {
                // Restart with new device
                disablePassThrough()
                Qt.callLater(enablePassThrough)
            }
        }
        
        function onOutputDeviceChanged() {
            root.outputDevice = plasmoid.configuration.outputDevice
            
            if (root.isPassThroughActive) {
                // Restart with new device
                disablePassThrough()
                Qt.callLater(enablePassThrough)
            }
        }
        
        function onWidgetWidthChanged() {
            // Widget width changed
        }
        
        function onWidgetHeightChanged() {
            // Widget height changed
        }
        
        function onAutoStartChanged() {
            root.autoStart = plasmoid.configuration.autoStart
        }
    }
    
    // Debug function to write to file
    function writeDebugFile(message) {
        try {
            // Simple approach - just use console.log for now to avoid interference
            console.log("DEBUG:", message)
        } catch (e) {
            // If this fails, at least we tried
            console.log("Debug write failed:", e)
        }
    }
} 