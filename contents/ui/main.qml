import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    toolTipMainText: "NVIDIA GPU"
    toolTipSubText: dataLoaded
    ? "🌡️ Температура: " + currentTemperature + "°C\n💨 Скорость: " + (currentFanSpeed === 0 ? "Авто" : currentFanSpeed + "%")
    : "Загрузка данных..."

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                root.expanded = !root.expanded
            }

            Image {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                source: getIconSource()
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    fullRepresentation: ColumnLayout {
        implicitWidth: 160
        implicitHeight: childrenRect.height + (Kirigami.Units.largeSpacing * 2)
        spacing: Kirigami.Units.smallSpacing

        Item { Layout.fillWidth: true; height: Kirigami.Units.smallSpacing }

        Repeater {
            model: [
                {text: "🔄 Авто", speed: "auto"},
                {text: "🌬️ 35%", speed: "35"},
                {text: "💨 50%", speed: "50"},
                {text: "🔥 80%", speed: "80"}
            ]

            delegate: PC3.ItemDelegate {
                Layout.fillWidth: true
                text: modelData.text
                highlighted: hovered

                onClicked: {
                    setFanSpeed(modelData.speed)
                    root.expanded = false
                }
            }
        }

        Item { Layout.fillWidth: true; height: Kirigami.Units.smallSpacing }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            if (sourceName.includes("nvidia-smi")) {
                var output = data.stdout.trim()
                console.log("nvidia-smi output:", output)

                if (output) {
                    var parts = output.split(",").map(function(s) { return s.trim() })
                    if (parts.length >= 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
                        var newFanSpeed = parseInt(parts[0])
                        var newTemp = parseInt(parts[1])

                        currentFanSpeed = newFanSpeed
                        currentTemperature = newTemp
                        dataLoaded = true

                        // Включаем/выключаем моргание в зависимости от условий
                        updateBlinking()
                    }
                }
            }
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }
    }

    property string fanSpeed: "auto"
    property int currentFanSpeed: -1
    property int currentTemperature: 0
    property bool dataLoaded: false
    property bool blinkState: false  // Текущее состояние моргания

    // Таймер для моргания (500мс)
    Timer {
        id: blinkTimer
        interval: 500
        running: false
        repeat: true
        onTriggered: {
            blinkState = !blinkState
        }
    }

    Timer {
        id: pollTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            queryGpuStatus()
        }
    }

    function queryGpuStatus() {
        executable.exec("nvidia-smi --query-gpu=fan.speed,temperature.gpu --format=csv,noheader,nounits")
    }

    function updateBlinking() {
        // Моргание только если вентилятор в "зелёном" диапазоне (35-45%)
        var isGreenRange = currentFanSpeed >= 35 && currentFanSpeed <= 45

        // Нужно моргать если температура высокая
        var needsBlink = isGreenRange && (currentTemperature > 60)

        blinkTimer.running = needsBlink
        if (!needsBlink) {
            blinkState = false
        }
    }

    function getIconSource() {
        if (!dataLoaded || currentFanSpeed === -1 || currentFanSpeed < 35) {
            return Qt.resolvedUrl("../assets/nvidia-suspended.svg")
        }

        var isGreenRange = currentFanSpeed >= 35 && currentFanSpeed <= 45

        // Если в зелёном диапазоне и температура высокая — моргаем
        if (isGreenRange && blinkTimer.running) {
            if (currentTemperature > 70) {
                // >70°C: моргание зелёный-красный
                return blinkState
                ? Qt.resolvedUrl("../assets/nvidia-active.svg")
                : Qt.resolvedUrl("../assets/nvidia-red.svg")
            } else if (currentTemperature > 60) {
                // >60°C: моргание зелёный-жёлтый
                return blinkState
                ? Qt.resolvedUrl("../assets/nvidia-active.svg")
                : Qt.resolvedUrl("../assets/nvidia-yellow.svg")
            }
        }

        // Обычная логика без моргания
        if (isGreenRange) {
            return Qt.resolvedUrl("../assets/nvidia-active.svg")
        } else if (currentFanSpeed >= 50 && currentFanSpeed <= 75) {
            return Qt.resolvedUrl("../assets/nvidia-yellow.svg")
        } else if (currentFanSpeed > 75) {
            return Qt.resolvedUrl("../assets/nvidia-red.svg")
        }

        return Qt.resolvedUrl("../assets/nvidia-suspended.svg")
    }

    function setFanSpeed(speed) {
        fanSpeed = speed
        let cmd = "sudo /home/rom/.local/bin/nvidia-fan.sh " + speed
        executable.exec(cmd)

        Qt.callLater(queryGpuStatus)
    }
}
