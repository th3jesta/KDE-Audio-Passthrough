import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasma5support 2.0 as P5Support

Item {
    id: configPage
    
    // Configuration properties - cfg_ properties are needed for Apply button detection
    // We'll manually manage these instead of relying on broken auto-binding
    property string cfg_inputDevice: ""
    property string cfg_outputDevice: ""
    property alias cfg_widgetWidth: widthSpinBox.value
    property alias cfg_widgetHeight: heightSpinBox.value
    property alias cfg_autoStart: autoStartCheck.checked
    
    // Track cfg_ property changes (enable the Apply button)
    onCfg_inputDeviceChanged: {
        if (!isInitializing) {
            try {
                configurationChanged()
            } catch (e) {
                console.log("Error enabling Apply button:", e.toString())
            }
        }
    }
    
    onCfg_outputDeviceChanged: {
        if (!isInitializing) {
            try {
                configurationChanged()
            } catch (e) {
                console.log("Error enabling Apply button:", e.toString())
            }
        }
    }
    
    // Handle Apply button click - write cfg_ properties to plasmoid.configuration
    function saveConfiguration() {
        try {
            if (plasmoid && plasmoid.configuration) {
                plasmoid.configuration.inputDevice = cfg_inputDevice
                plasmoid.configuration.outputDevice = cfg_outputDevice
                
                // Update our tracking properties
                currentInputDevice = cfg_inputDevice
                currentOutputDevice = cfg_outputDevice
            }
        } catch (e) {
            console.log("Error saving configuration:", e.toString())
        }
    }
    
    // Connect to Apply button
    Connections {
        target: configPage.parent ? configPage.parent : null
        
        function onApplyClicked() {
            saveConfiguration()
        }
    }
    
    // Manual configuration properties that we'll sync with plasmoid.configuration
    property string currentInputDevice: ""
    property string currentOutputDevice: ""
    
    // Flag to prevent configuration changes during initialization
    property bool isInitializing: true
    
    // Update ComboBox display when configuration changes
    onCurrentInputDeviceChanged: {
        // Update the ComboBox if it exists
        if (inputDeviceCombo) {
            // Try to find friendly name for the device
            var friendlyName = findDeviceDescription(currentInputDevice, inputDevices)
            if (friendlyName) {
                inputDeviceCombo.editText = friendlyName
            } else {
                inputDeviceCombo.editText = currentInputDevice
            }
        }
    }
    
    onCurrentOutputDeviceChanged: {
        // Update the ComboBox if it exists
        if (outputDeviceCombo) {
            // Try to find friendly name for the device
            var friendlyName = findDeviceDescription(currentOutputDevice, outputDevices)
            if (friendlyName) {
                outputDeviceCombo.editText = friendlyName
            } else {
                outputDeviceCombo.editText = currentOutputDevice
            }
        }
    }
    
    // Helper functions to access configuration
    function getConfiguredInputDevice() {
        try {
            if (plasmoid && plasmoid.configuration) {
                return plasmoid.configuration.inputDevice || ""
            }
        } catch (e) {
            console.log("Error accessing inputDevice config:", e.toString())
        }
        return ""
    }
    
    function getConfiguredOutputDevice() {
        try {
            if (plasmoid && plasmoid.configuration) {
                return plasmoid.configuration.outputDevice || ""
            }
        } catch (e) {
            console.log("Error accessing outputDevice config:", e.toString())
        }
        return ""
    }
    
    function setConfiguredInputDevice(value) {
        if (isInitializing) {
            return
        }
        
        try {
            if (plasmoid && plasmoid.configuration) {
                plasmoid.configuration.inputDevice = value
                currentInputDevice = value
                cfg_inputDevice = value  // Update cfg_ property for Apply button detection
            }
        } catch (e) {
            console.log("Error saving input device configuration:", e.toString())
        }
    }
    
    function setConfiguredOutputDevice(value) {
        if (isInitializing) {
            return
        }
        
        try {
            if (plasmoid && plasmoid.configuration) {
                plasmoid.configuration.outputDevice = value
                currentOutputDevice = value
                cfg_outputDevice = value  // Update cfg_ property for Apply button detection
            }
        } catch (e) {
            console.log("Error saving output device configuration:", e.toString())
        }
    }
    
    // Real device lists (will be populated by pactl)
    property var inputDevices: []
    property var outputDevices: []
    property bool devicesLoading: false
    property string debugInfo: ""
    
    // Command execution using Plasma5Support
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            
            if (sourceName.includes("list sources")) {
                handleInputDevicesResult(data)
            } else if (sourceName.includes("list sinks")) {
                handleOutputDevicesResult(data)
            }
        }
    }
    
    // Timer for timeout handling
    Timer {
        id: timeoutTimer
        interval: 5000
        onTriggered: {
            loadFallbackDevices()
        }
    }
    
    Component.onCompleted: {
        // Load configuration using our helper functions
        var configuredInput = getConfiguredInputDevice()
        var configuredOutput = getConfiguredOutputDevice()
        
        // Initialize our manual properties
        currentInputDevice = configuredInput
        currentOutputDevice = configuredOutput
        
        // Initialize cfg_ properties for Apply button detection
        cfg_inputDevice = configuredInput
        cfg_outputDevice = configuredOutput
        
        // Start device loading
        Qt.callLater(function() {
            initializeSavedDevices()
            loadAudioDevices()
        })
    }
    

    
    function initializeSavedDevices() {
        // Get configuration using our helper functions
        var configuredInput = getConfiguredInputDevice()
        var configuredOutput = getConfiguredOutputDevice()
        
        // Add configuration info to debug box
        debugInfo += "=== CURRENT CONFIGURATION ===\n"
        debugInfo += "Input Device: " + (configuredInput && configuredInput !== "default" ? configuredInput : "System Default") + "\n"
        debugInfo += "Output Device: " + (configuredOutput && configuredOutput !== "default" ? configuredOutput : "System Default") + "\n"
        debugInfo += "Widget Size: " + (cfg_widgetWidth || "32") + "×" + (cfg_widgetHeight || "32") + "px\n"
        debugInfo += "Auto Start: " + (cfg_autoStart ? "Yes" : "No") + "\n\n"
        
        // Clear models (actual device population will happen in device loading)
        inputDeviceModel.clear()
        outputDeviceModel.clear()
    }
    
    function loadAudioDevices() {
        devicesLoading = true
        debugInfo = "Detecting audio devices...\n"
        
        // Start timeout timer
        timeoutTimer.start()
        
        // Load input devices first
        debugInfo += "Querying PulseAudio for input devices...\n"
        executable.connectSource("pactl list sources")
    }
    
    function handleInputDevicesResult(data) {
        if (data["exit code"] === 0) {
            debugInfo += "✓ Input devices detected\n"
            parseInputDevices(data.stdout)
            
            // Now load output devices
            debugInfo += "Querying PulseAudio for output devices...\n"
            executable.connectSource("pactl list sinks")
        } else {
            debugInfo += "✗ Failed to get input devices: " + data.stderr + "\n"
            loadFallbackDevices()
        }
    }
    
    function handleOutputDevicesResult(data) {
        timeoutTimer.stop() // Cancel timeout since we got a response
        
        if (data["exit code"] === 0) {
            debugInfo += "✓ Output devices detected\n"
            parseOutputDevices(data.stdout)
            finalizeDeviceLoading()
        } else {
            debugInfo += "✗ Failed to get output devices: " + data.stderr + "\n"
            loadFallbackDevices()
        }
    }
    
    function parseInputDevices(output) {
        debugInfo += "Parsing input devices...\n"
        
        var newInputDevices = [
            { name: "default", description: "Default Input Device" }
        ]
        
        var lines = output.split('\n')
        var deviceCount = 0
        var currentSource = {}
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            
            if (line.startsWith("Source #")) {
                // Start of a new source, reset current source
                currentSource = {}
            } else if (line.startsWith("Name: ")) {
                currentSource.name = line.substring(6)
            } else if (line.startsWith("Description: ")) {
                currentSource.description = line.substring(13)
                
                // If we have both name and description, process this source
                if (currentSource.name && currentSource.description) {
                    // Skip monitor sources (they're outputs being monitored)
                    if (currentSource.name.indexOf('.monitor') === -1) {
                        newInputDevices.push({
                            name: currentSource.name,
                            description: currentSource.description
                        })
                        
                        deviceCount++
                        debugInfo += "  • " + currentSource.description + "\n"
                    }
                }
            }
        }
        
        inputDevices = newInputDevices
        debugInfo += "Found " + deviceCount + " input devices\n\n"
    }
    
    function parseOutputDevices(output) {
        debugInfo += "Parsing output devices...\n"
        
        var newOutputDevices = [
            { name: "default", description: "Default Output Device" }
        ]
        
        var lines = output.split('\n')
        var deviceCount = 0
        var currentSink = {}
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            
            if (line.startsWith("Sink #")) {
                // Start of a new sink, reset current sink
                currentSink = {}
            } else if (line.startsWith("Name: ")) {
                currentSink.name = line.substring(6)
            } else if (line.startsWith("Description: ")) {
                currentSink.description = line.substring(13)
                
                // If we have both name and description, process this sink
                if (currentSink.name && currentSink.description) {
                    newOutputDevices.push({
                        name: currentSink.name,
                        description: currentSink.description
                    })
                    
                    deviceCount++
                    debugInfo += "  • " + currentSink.description + "\n"
                }
            }
        }
        
        outputDevices = newOutputDevices
        debugInfo += "Found " + deviceCount + " output devices\n\n"
    }
    
    function loadFallbackDevices() {
        timeoutTimer.stop()
        devicesLoading = false
        
        debugInfo += "⚠ Using fallback device list\n"
        debugInfo += "This usually means PulseAudio isn't running or accessible.\n\n"
        
        inputDevices = [
            { name: "default", description: "Default Input Device" }
        ]
        
        outputDevices = [
            { name: "default", description: "Default Output Device" }
        ]
        
        updateDeviceComboBoxes()
        setCurrentDeviceSelections()
        
        // Enable configuration changes after fallback loading is complete
        isInitializing = false
    }
    
    function finalizeDeviceLoading() {
        devicesLoading = false
        
        if (inputDevices.length <= 1 && outputDevices.length <= 1) {
            debugInfo += "⚠ No devices found. Check PulseAudio configuration.\n"
        } else {
            debugInfo += "✓ Device detection completed successfully!\n"
        }
        
        // Check if configured devices are available
        var savedInputDevice = getConfiguredInputDevice()
        var savedOutputDevice = getConfiguredOutputDevice()
        
        // Check input device
        if (savedInputDevice && savedInputDevice !== "" && savedInputDevice !== "default") {
            var foundInput = false
            var inputFriendlyName = ""
            for (var i = 0; i < inputDevices.length; i++) {
                if (inputDevices[i].name === savedInputDevice) {
                    foundInput = true
                    inputFriendlyName = inputDevices[i].description
                    break
                }
            }
            
            if (foundInput) {
                debugInfo += "✓ Configured input device found: " + inputFriendlyName + "\n"
            } else {
                debugInfo += "⚠ Configured input device not found (may be disconnected)\n"
            }
        }
        
        // Check output device
        if (savedOutputDevice && savedOutputDevice !== "" && savedOutputDevice !== "default") {
            var foundOutput = false
            var outputFriendlyName = ""
            for (var j = 0; j < outputDevices.length; j++) {
                if (outputDevices[j].name === savedOutputDevice) {
                    foundOutput = true
                    outputFriendlyName = outputDevices[j].description
                    break
                }
            }
            
            if (foundOutput) {
                debugInfo += "✓ Configured output device found: " + outputFriendlyName + "\n"
            } else {
                debugInfo += "⚠ Configured output device not found (may be disconnected)\n"
            }
        }
        
        updateDeviceComboBoxes()
        
        // Use Qt.callLater to ensure comboboxes update after models are populated
        Qt.callLater(function() {
            setCurrentDeviceSelections()
            
            // IMPORTANT: Enable configuration changes after initialization is complete
            isInitializing = false
        })
    }
    
    function updateDeviceComboBoxes() {
        // Get current configuration using helper functions
        var currentInputDevice = getConfiguredInputDevice()
        var currentOutputDevice = getConfiguredOutputDevice()
        
        // Clear models
        inputDeviceModel.clear()
        outputDeviceModel.clear()
        
        // Track if we found the saved devices
        var foundInputDevice = false
        var foundOutputDevice = false
        
        // Add all detected input devices
        for (var i = 0; i < inputDevices.length; i++) {
            var inputDevice = inputDevices[i]
            inputDeviceModel.append({
                text: inputDevice.description,
                value: inputDevice.name
            })
            
            // Check if this matches the saved device
            if (inputDevice.name === currentInputDevice) {
                foundInputDevice = true
            }
        }
        
        // Add all detected output devices
        for (var j = 0; j < outputDevices.length; j++) {
            var outputDevice = outputDevices[j]
            outputDeviceModel.append({
                text: outputDevice.description,
                value: outputDevice.name
            })
            
            // Check if this matches the saved device
            if (outputDevice.name === currentOutputDevice) {
                foundOutputDevice = true
            }
        }
        
        // If saved input device wasn't found, add it as unavailable
        if (currentInputDevice && !foundInputDevice && currentInputDevice !== "default") {
            inputDeviceModel.append({
                text: currentInputDevice + " " + i18n("(unavailable)"),
                value: currentInputDevice
            })
        }
        
        // If saved output device wasn't found, add it as unavailable
        if (currentOutputDevice && !foundOutputDevice && currentOutputDevice !== "default") {
            outputDeviceModel.append({
                text: currentOutputDevice + " " + i18n("(unavailable)"),
                value: currentOutputDevice
            })
        }
    }
    
    function setCurrentDeviceSelections() {
        // Get current configuration using helper functions
        var configuredInput = getConfiguredInputDevice()
        var configuredOutput = getConfiguredOutputDevice()
        
        // Find and set input device selection
        var inputFound = false
        for (var i = 0; i < inputDeviceModel.count; i++) {
            var inputItem = inputDeviceModel.get(i)
            if (inputItem.value === configuredInput) {
                inputDeviceCombo.currentIndex = i
                inputDeviceCombo.editText = inputItem.text  // Set to friendly name
                inputFound = true
                break
            }
        }
        
        // Find and set output device selection
        var outputFound = false
        for (var j = 0; j < outputDeviceModel.count; j++) {
            var outputItem = outputDeviceModel.get(j)
            if (outputItem.value === configuredOutput) {
                outputDeviceCombo.currentIndex = j
                outputDeviceCombo.editText = outputItem.text  // Set to friendly name
                outputFound = true
                break
            }
        }
        
        // If device not found in model but we have a saved value, try to find friendly name
        if (!inputFound && configuredInput && configuredInput !== "") {
            var inputDescription = findDeviceDescription(configuredInput, inputDevices)
            if (inputDescription) {
                inputDeviceCombo.editText = inputDescription
            } else {
                inputDeviceCombo.editText = configuredInput
            }
        }
        
        if (!outputFound && configuredOutput && configuredOutput !== "") {
            var outputDescription = findDeviceDescription(configuredOutput, outputDevices)
            if (outputDescription) {
                outputDeviceCombo.editText = outputDescription
            } else {
                outputDeviceCombo.editText = configuredOutput
            }
        }
    }
    
    function refreshDevices() {
        debugInfo = ""
        loadAudioDevices()
    }
    
    // Helper function to find device description by name
    function findDeviceDescription(deviceName, deviceList) {
        for (var i = 0; i < deviceList.length; i++) {
            if (deviceList[i].name === deviceName) {
                return deviceList[i].description
            }
        }
        return null
    }
    
    // Helper function to find device description from model
    function findDeviceDescriptionInModel(deviceName, model) {
        for (var i = 0; i < model.count; i++) {
            var item = model.get(i)
            if (item.value === deviceName) {
                return item.text
            }
        }
        return null
    }
    
    // Device models
    ListModel {
        id: inputDeviceModel
    }
    
    ListModel {
        id: outputDeviceModel
    }
    
    // Main configuration layout with scrolling
    ScrollView {
        anchors.fill: parent
        
        ColumnLayout {
            width: parent.width
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
        
        // Header with status
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: headerColumn.implicitHeight + Kirigami.Units.largeSpacing
            
            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.highlightColor
                opacity: 0.15
                radius: 4
                z: 0
            }
            
            ColumnLayout {
                id: headerColumn
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing / 2
                spacing: Kirigami.Units.smallSpacing
                z: 1
                
                Label {
                    text: i18n("Configure Audio Pass-Through Widget")
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                    horizontalAlignment: Text.AlignHCenter
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                
                Label {
                    text: devicesLoading ? i18n("Detecting audio devices...") : i18n("Select your audio devices from the detected list below.")
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
        
        // Device Configuration Section
        GroupBox {
            Layout.fillWidth: true
            title: i18n("Audio Devices")
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: i18n("Input Device:")
                        Layout.preferredWidth: 120
                    }
                    
                    ComboBox {
                        id: inputDeviceCombo
                        Layout.fillWidth: true
                        model: inputDeviceModel
                        textRole: "text"
                        editable: true
                        editText: currentInputDevice || ""
                        displayText: editText || (devicesLoading ? i18n("Loading...") : i18n("Select input device..."))
                        enabled: !devicesLoading
                        
                        onActivated: function(index) {
                            if (index >= 0 && index < inputDeviceModel.count) {
                                var selectedItem = inputDeviceModel.get(index)
                                var deviceValue = selectedItem.value
                                var deviceText = selectedItem.text
                                
                                // Keep the friendly name for display
                                editText = deviceText
                                
                                // Update cfg_ property for Apply button detection
                                cfg_inputDevice = deviceValue
                            }
                        }
                        
                        onEditTextChanged: {
                            // If user typed a raw device name, use it directly
                            // If user typed a friendly name, try to find the corresponding raw name
                            var typedText = editText
                            var foundRawName = null
                            
                            // Check if it's already a raw device name by looking in detected devices
                            for (var i = 0; i < inputDevices.length; i++) {
                                if (inputDevices[i].name === typedText) {
                                    foundRawName = typedText
                                    break
                                }
                                if (inputDevices[i].description === typedText) {
                                    foundRawName = inputDevices[i].name
                                    break
                                }
                            }
                            
                            // Check in model as well
                            if (!foundRawName) {
                                for (var j = 0; j < inputDeviceModel.count; j++) {
                                    var modelItem = inputDeviceModel.get(j)
                                    if (modelItem.value === typedText || modelItem.text === typedText) {
                                        foundRawName = modelItem.value
                                        break
                                    }
                                }
                            }
                            
                            // Update cfg_ property for Apply button detection
                            cfg_inputDevice = foundRawName || typedText
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: i18n("Output Device:")
                        Layout.preferredWidth: 120
                    }
                    
                    ComboBox {
                        id: outputDeviceCombo
                        Layout.fillWidth: true
                        model: outputDeviceModel
                        textRole: "text"
                        editable: true
                        editText: currentOutputDevice || ""
                        displayText: editText || (devicesLoading ? i18n("Loading...") : i18n("Select output device..."))
                        enabled: !devicesLoading
                        
                        onActivated: function(index) {
                            if (index >= 0 && index < outputDeviceModel.count) {
                                var selectedItem = outputDeviceModel.get(index)
                                var deviceValue = selectedItem.value
                                var deviceText = selectedItem.text
                                
                                // Keep the friendly name for display
                                editText = deviceText
                                
                                // Update cfg_ property for Apply button detection
                                cfg_outputDevice = deviceValue
                            }
                        }
                        
                        onEditTextChanged: {
                            // If user typed a raw device name, use it directly
                            // If user typed a friendly name, try to find the corresponding raw name
                            var typedText = editText
                            var foundRawName = null
                            
                            // Check if it's already a raw device name by looking in detected devices
                            for (var i = 0; i < outputDevices.length; i++) {
                                if (outputDevices[i].name === typedText) {
                                    foundRawName = typedText
                                    break
                                }
                                if (outputDevices[i].description === typedText) {
                                    foundRawName = outputDevices[i].name
                                    break
                                }
                            }
                            
                            // Check in model as well
                            if (!foundRawName) {
                                for (var j = 0; j < outputDeviceModel.count; j++) {
                                    var modelItem = outputDeviceModel.get(j)
                                    if (modelItem.value === typedText || modelItem.text === typedText) {
                                        foundRawName = modelItem.value
                                        break
                                    }
                                }
                            }
                            
                            // Update cfg_ property for Apply button detection
                            cfg_outputDevice = foundRawName || typedText
                        }
                    }
                }
                
                // Refresh button and help
                RowLayout {
                    Layout.fillWidth: true
                    
                    Button {
                        text: devicesLoading ? i18n("Detecting...") : i18n("Refresh Device List")
                        icon.name: "view-refresh"
                        enabled: !devicesLoading
                        onClicked: refreshDevices()
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Label {
                        text: i18n("Can't find your device? Try refreshing.")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                    }
                }
                
                // Debug info area
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: debugInfo.length > 0
                    spacing: Kirigami.Units.smallSpacing
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: i18n("Debug Information:")
                            font.bold: true
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: i18n("Copy to Clipboard")
                            icon.name: "edit-copy"
                            onClicked: {
                                debugTextArea.selectAll()
                                debugTextArea.copy()
                                debugTextArea.deselect()
                            }
                        }
                        
                        Button {
                            text: i18n("Clear")
                            icon.name: "edit-clear"
                            onClicked: {
                                debugInfo = ""
                            }
                        }
                    }
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(150, debugTextArea.contentHeight + 20)
                        Layout.minimumHeight: 60
                        
                        TextArea {
                            id: debugTextArea
                            text: debugInfo
                            readOnly: true
                            selectByMouse: true
                            selectByKeyboard: true
                            wrapMode: TextArea.Wrap
                            font.family: "monospace"
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                            background: Rectangle {
                                color: Kirigami.Theme.backgroundColor
                                border.color: Kirigami.Theme.disabledTextColor
                                border.width: 1
                                radius: 4
                            }
                        }
                    }
                }
            }
        }
        
        // Widget Size Configuration Section
        GroupBox {
            Layout.fillWidth: true
            title: i18n("Widget Appearance")
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: i18n("Width (pixels):")
                        Layout.preferredWidth: 120
                    }
                    
                    SpinBox {
                        id: widthSpinBox
                        from: 24
                        to: 128
                        value: 32
                        stepSize: 4
                        textFromValue: function(value, locale) {
                            return value + " px"
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: i18n("Height (pixels):")
                        Layout.preferredWidth: 120
                    }
                    
                    SpinBox {
                        id: heightSpinBox
                        from: 24
                        to: 128
                        value: 32
                        stepSize: 4
                        textFromValue: function(value, locale) {
                            return value + " px"
                        }
                    }
                }
                
                Button {
                    text: i18n("Reset to Default Size")
                    icon.name: "edit-undo"
                    onClicked: {
                        widthSpinBox.value = 32
                        heightSpinBox.value = 32
                    }
                }
            }
        }
        
        // Behavior Configuration Section
        GroupBox {
            Layout.fillWidth: true
            title: i18n("Behavior")
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                CheckBox {
                    id: autoStartCheck
                    text: i18n("Enable pass-through on startup")
                    ToolTip.text: i18n("Automatically enable audio pass-through when the widget loads")
                    ToolTip.visible: hovered
                }
            }
        }
        
        // Information Section
        GroupBox {
            Layout.fillWidth: true
            title: i18n("Information")
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                Label {
                    Layout.fillWidth: true
                    text: i18n("• Click the widget in the panel to toggle audio pass-through")
                    wrapMode: Text.WordWrap
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                
                Label {
                    Layout.fillWidth: true
                    text: i18n("• The widget icon will change color when pass-through is active")
                    wrapMode: Text.WordWrap
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                
                Label {
                    Layout.fillWidth: true
                    text: i18n("• Hover over the widget to see current status and device information")
                    wrapMode: Text.WordWrap
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                
                Label {
                    Layout.fillWidth: true
                    text: i18n("• All available PulseAudio devices are automatically detected and listed")
                    wrapMode: Text.WordWrap
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }
        
        // Spacer to push content to top
        Item {
            Layout.fillHeight: true
        }
    }
    } // End ScrollView
}