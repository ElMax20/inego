import QtQuick
import QtQuick.Controls

Rectangle {
    id: headerRoot
    height: 64
    color: theme.bgCard
    border.color: theme.borderColor
    border.width: 1

    property string moduleTitle: "PANEL DE CONTROL GENERAL"
    property string userName: "Invitado"
    property string userRole: "Administrador"

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 24
        spacing: 6

        Column {
            Text {
                text: headerRoot.moduleTitle
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
            }
            Text {
                text: "Monitoreo Ejecutivo y Métricas en Tiempo Real"
                font.pixelSize: 10
                color: theme.textMuted
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 24
        height: 36
        width: userRow.width + 24
        radius: 18
        color: theme.bgMain
        border.color: theme.borderColor

        Row {
            id: userRow
            anchors.centerIn: parent
            spacing: 8

            Text { text: "👤"; font.pixelSize: 14 }
            Column {
                Text { text: headerRoot.userName; font.pixelSize: 11; font.bold: true; color: theme.textPrimary }
                Text { text: headerRoot.userRole; font.pixelSize: 9; color: theme.colorBronze; font.bold: true }
            }
        }
    }
}
