import QtQuick
import QtQuick.Controls

ScrollView {
    id: qRoot
    clip: true

    property var quotes: []

    Component.onCompleted: refresh()

    function refresh() {
        var raw = backend.getQuotesData()
        quotes = JSON.parse(raw)
    }

    Column {
        width: qRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        Text {
            text: "📋 Cotizaciones Emitidas e Historial de Clientes"
            font.pixelSize: 15
            font.bold: true
            color: theme.textPrimary
        }

        // LISTA DE COTIZACIONES EN QML
        Repeater {
            model: qRoot.quotes

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
                            text: "📋 " + modelData.numero_cotizacion + " - " + modelData.cliente_nombre
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Fecha Emisión: " + modelData.fecha_emision + " | Total Cotizado: $" + modelData.total.toFixed(2) + " USD"
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Rectangle {
                            color: theme.badgeBgBronze
                            radius: 6
                            width: stTxt.width + 16
                            height: 26

                            Text {
                                id: stTxt
                                anchors.centerIn: parent
                                text: modelData.estado
                                font.pixelSize: 11
                                font.bold: true
                                color: theme.colorBronze
                            }
                        }

                        Rectangle {
                            color: modelData.es_credito_72dias ? theme.badgeBgBronze : theme.badgeBgSuccess
                            radius: 6
                            width: credTxt.width + 16
                            height: 26

                            Text {
                                id: credTxt
                                anchors.centerIn: parent
                                text: modelData.es_credito_72dias ? "Crédito 72d" : "Contado"
                                font.pixelSize: 11
                                font.bold: true
                                color: modelData.es_credito_72dias ? theme.colorBronze : theme.colorSuccess
                            }
                        }
                    }
                }
            }
        }
    }
}
