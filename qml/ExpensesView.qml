import QtQuick
import QtQuick.Controls

ScrollView {
    id: expRoot
    clip: true

    property var expenses: []

    Component.onCompleted: refresh()

    function refresh() {
        var raw = backend.getExpensesData()
        expenses = JSON.parse(raw)
    }

    Column {
        width: expRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        Text {
            text: "🧾 Control de Caja Chica, Agua, Servicios y Logística"
            font.pixelSize: 15
            font.bold: true
            color: theme.textPrimary
        }

        // LISTA DE GASTOS EN QML
        Repeater {
            model: expRoot.expenses

            Rectangle {
                width: parent.width
                height: 64
                color: theme.bgCard
                radius: 10
                border.color: theme.borderColor

                Row {
                    anchors.fill: parent
                    anchors.margins: 14

                    Column {
                        spacing: 4
                        Text {
                            text: "🧾 [" + modelData.rubro + "] " + modelData.concepto
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Fecha: " + modelData.fecha + " | Egreso de Caja Chica"
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.badgeBgDanger
                        radius: 6
                        width: expAmtTxt.width + 16
                        height: 26

                        Text {
                            id: expAmtTxt
                            anchors.centerIn: parent
                            text: "-$" + modelData.monto.toFixed(2) + " USD"
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.colorDanger
                        }
                    }
                }
            }
        }
    }
}
