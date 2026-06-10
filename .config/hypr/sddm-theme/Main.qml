import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1e1e2e"

    // ── Catppuccin Mocha palette ──────────────────────────────────────────
    readonly property color base:    "#1e1e2e"
    readonly property color mantle:  "#181825"
    readonly property color surface0:"#313244"
    readonly property color surface1:"#45475a"
    readonly property color overlay0:"#6c7086"
    readonly property color text:    "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color lavender:"#b4befe"
    readonly property color mauve:   "#cba6f7"
    readonly property color blue:    "#89b4fa"
    readonly property color red:     "#f38ba8"
    readonly property color green:   "#a6e3a1"

    property string currentUser: userModel.lastUser
    property bool loginFailed: false
    property int sessionIndex: {
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
            if (name.indexOf("uwsm") !== -1) return i
            if (name.indexOf("hyprland") !== -1) return i
        }
        return sessionModel.lastIndex
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginFailed = true
            passwordInput.text = ""
            passwordInput.focus = true
            shakeAnim.restart()
        }
        function onLoginSucceeded() {
            root.loginFailed = false
        }
    }

    // ── Background ────────────────────────────────────────────────────────
    Image {
        id: bgImage
        anchors.fill: parent
        source: config.background !== undefined ? config.background : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
    }

    // Dark overlay with subtle gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0x1e/255, 0x1e/255, 0x2e/255, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(0x18/255, 0x18/255, 0x25/255, 0.80) }
        }
    }

    // Animated gradient orbs (decorative blobs)
    Rectangle {
        width: 600; height: 600
        radius: 300
        opacity: 0.08
        color: root.mauve
        x: -150
        y: root.height - 450
        NumberAnimation on x { from: -150; to: -80; duration: 8000; loops: Animation.Infinite; easing.type: Easing.InOutSine }
    }
    Rectangle {
        width: 400; height: 400
        radius: 200
        opacity: 0.06
        color: root.lavender
        x: root.width - 250
        y: -100
        NumberAnimation on y { from: -100; to: -50; duration: 6000; loops: Animation.Infinite; easing.type: Easing.InOutSine }
    }

    // ── Clock (top-left corner) ───────────────────────────────────────────
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 60
        spacing: 4

        Text {
            id: timeLabel
            color: root.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 72
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "HH:mm")
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeLabel.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }
        Text {
            id: dateLabel
            color: root.subtext
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d")
            }
        }
    }

    // ── Central login card ────────────────────────────────────────────────
    Item {
        id: loginCard
        anchors.centerIn: parent
        width: 380
        height: cardColumn.implicitHeight + 60

        // Shake animation on fail
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: loginCard; property: "x"; from: loginCard.x - 12; to: loginCard.x + 12; duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: loginCard; property: "x"; from: loginCard.x + 12; to: loginCard.x - 12; duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: loginCard; property: "x"; from: loginCard.x - 8;  to: loginCard.x + 8;  duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: loginCard; property: "x"; from: loginCard.x + 8;  to: loginCard.x;      duration: 60; easing.type: Easing.InOutQuad }
        }

        // Card background
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0x18/255, 0x18/255, 0x25/255, 0.75)
            radius: 20
            border.color: loginFailed ? root.red : root.surface1
            border.width: 1

            // Subtle inner glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 19
                color: "transparent"
                border.color: loginFailed ? Qt.rgba(0xf3/255, 0x8b/255, 0xa8/255, 0.15) : Qt.rgba(0xb4/255, 0xbe/255, 0xfe/255, 0.08)
                border.width: 1
            }

            Behavior on border.color {
                ColorAnimation { duration: 300 }
            }
        }

        Column {
            id: cardColumn
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 24

            // Avatar circle + username
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                // Avatar circle
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 80; height: 80
                    radius: 40
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.lavender }
                        GradientStop { position: 1.0; color: root.mauve }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.currentUser.length > 0 ? root.currentUser[0].toUpperCase() : "?"
                        color: root.base
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 32
                        font.weight: Font.Bold
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.currentUser
                    color: root.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sddm.hostName
                    color: root.subtext
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: root.surface1
                opacity: 0.6
            }

            // Password field
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Password"
                    color: root.subtext
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                }

                Rectangle {
                    id: passwordBox
                    width: parent.width
                    height: 46
                    radius: 10
                    color: root.surface0
                    border.color: {
                        if (loginFailed) return root.red
                        if (passwordInput.activeFocus) return root.lavender
                        return root.surface1
                    }
                    border.width: loginFailed ? 2 : (passwordInput.activeFocus ? 2 : 1)

                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    // Lock icon
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: loginFailed ? "" : ""
                        color: loginFailed ? root.red : root.overlay0
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: passwordInput
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 40
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: root.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.letterSpacing: 3
                        selectionColor: Qt.rgba(0xb4/255, 0xbe/255, 0xfe/255, 0.3)
                        focus: true

                        onTextChanged: root.loginFailed = false

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                sddm.login(root.currentUser, passwordInput.text, root.sessionIndex)
                                event.accepted = true
                            }
                        }
                    }
                }

                // Error message
                Text {
                    visible: root.loginFailed
                    text: "Incorrect password. Try again."
                    color: root.red
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.loginFailed ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }

            // Login button
            Rectangle {
                id: loginBtn
                width: parent.width
                height: 44
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: loginBtnMouse.containsMouse ? Qt.lighter(root.lavender, 1.1) : root.lavender }
                    GradientStop { position: 1.0; color: loginBtnMouse.containsMouse ? Qt.lighter(root.mauve, 1.1) : root.mauve }
                }

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Sign In"
                    color: root.base
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                }

                MouseArea {
                    id: loginBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.login(root.currentUser, passwordInput.text, root.sessionIndex)
                    onPressed: parent.opacity = 0.8
                    onReleased: parent.opacity = 1.0
                }
            }

            // Power buttons row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Repeater {
                    model: [
                        { icon: "⏻", label: "Shut Down", action: "off" },
                        { icon: "↺", label: "Restart",   action: "reboot" }
                    ]

                    Rectangle {
                        width: 120; height: 34
                        radius: 8
                        color: powerMouse.containsMouse ? root.surface1 : root.surface0
                        border.color: root.surface1
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: modelData.icon
                                color: root.subtext
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.label
                                color: root.subtext
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.action === "off") sddm.powerOff()
                                else sddm.reboot()
                            }
                        }
                    }
                }
            }
        }
    }

    // Keyboard caps lock indicator (bottom right)
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 30
        visible: keyboard && keyboard.capsLock
        text: " CAPS LOCK"
        color: root.red
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.weight: Font.Bold
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
