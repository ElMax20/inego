import QtQuick
import QtQuick.Controls

ScrollView {
    id: repRoot
    clip: true

    Column {
        width: repRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 10; width: 1 }

        Text {
            text: "📈 Reportería Corporativa y Exportación a Excel"
            font.pixelSize: 15
            font.bold: true
            color: theme.textPrimary
        }

        // Tarjeta Gantt Gobierno
        Rectangle {
            width: parent.width
            height: 120
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Text { text: "📊 Diagrama de Gantt Excel"; font.pixelSize: 14; font.bold: true; color: theme.textPrimary }
                Text { text: "Genera barras de avance cronológico para licitaciones y contratos de gobierno."; font.pixelSize: 11; color: theme.textMuted }

                Button {
                    height: 36
                    width: 240
                    contentItem: Text { text: "Descargar Gantt (.xlsx)"; color: "#FFFFFF"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorBronze; radius: 8 }
                    onClicked: {
                        var resStr = backend.downloadReport("gantt")
                        var res = JSON.parse(resStr)
                        infoDialog.text = "✅ Diagrama de Gantt generado exitosamente en data/" + res.file
                        infoDialog.open()
                    }
                }
            }
        }

        // Tarjeta Reporte de Ventas
        Rectangle {
            width: parent.width
            height: 120
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Text { text: "💵 Reporte de Ventas Facturadas"; font.pixelSize: 14; font.bold: true; color: theme.textPrimary }
                Text { text: "Exporta el acumulado de ventas facturadas por rango de fechas en Excel."; font.pixelSize: 11; color: theme.textMuted }

                Button {
                    height: 36
                    width: 240
                    contentItem: Text { text: "Descargar Ventas (.xlsx)"; color: "#FFFFFF"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 8 }
                    onClicked: {
                        var resStr = backend.downloadReport("sales")
                        var res = JSON.parse(resStr)
                        infoDialog.text = "✅ Reporte de Ventas generado exitosamente en data/" + res.file
                        infoDialog.open()
                    }
                }
            }
        }
    }

    // POPUP MODAL CONFIRMACIÓN DESCARGA REPORTE (COLOR UNIFORME TOTAL)
    Popup {
        id: infoDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 440
        height: 190
        padding: 16

        property alias text: infoTxt.text

        Overlay.modal: Rectangle { color: "#60000000" }

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorBronze
            border.width: 2
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 14

            Text {
                text: "Confirmación de Descarga"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                id: infoTxt
                text: ""
                color: theme.textPrimary
                font.pixelSize: 12
                font.bold: true
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            Item { height: 1; width: 1 }

            Rectangle {
                width: 120
                height: 34
                radius: 6
                color: theme.colorBronze
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: "Aceptar"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: infoDialog.close()
                }
            }
        }
    }
}
