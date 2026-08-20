import QtQuick
import QtQuick.Controls

ScrollView {
    id: payRoot
    clip: true

    property var payroll: []

    Component.onCompleted: refresh()

    function refresh() {
        var raw = backend.getPayrollData()
        payroll = JSON.parse(raw)
    }

    Column {
        width: payRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        Text {
            text: "👔 Roles de Pago de Socios ($50.00 Fijo + 5% Bono de Ventas)"
            font.pixelSize: 15
            font.bold: true
            color: theme.textPrimary
        }

        // LISTA DE NÓMINA EN QML
        Repeater {
            model: payRoot.payroll

            Rectangle {
                width: parent.width
                height: 70
                color: theme.bgCard
                radius: 10
                border.color: theme.borderColor

                Row {
                    anchors.fill: parent
                    anchors.margins: 14

                    Column {
                        spacing: 4
                        Text {
                            text: "👔 " + modelData.nombre
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Cargo: " + modelData.cargo + " | Fijo: $" + modelData.pago_fijo.toFixed(2) + " + Bono 5%: $" + modelData.bono_5.toFixed(2)
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.badgeBgBronze
                        radius: 6
                        width: payTotTxt.width + 16
                        height: 28

                        Text {
                            id: payTotTxt
                            anchors.centerIn: parent
                            text: "Total: $" + modelData.total.toFixed(2) + " USD"
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.colorBronze
                        }
                    }
                }
            }
        }
    }
}
