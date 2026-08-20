import QtQuick
import QtQuick.Controls

ScrollView {
    id: cliRoot
    clip: true

    property var clients: []

    Component.onCompleted: refresh()

    function refresh() {
        var raw = backend.getClientsData()
        clients = JSON.parse(raw)
    }

    Column {
        width: cliRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // Header y Botón Registrar Cliente (RF3.1)
        Row {
            width: parent.width

            Text {
                text: "👥 Gestión de Clientes B2B / B2C y Políticas de Crédito"
                font.pixelSize: 15
                font.bold: true
                color: theme.textPrimary
            }

            Rectangle {
                anchors.right: parent.right
                height: 36
                width: 170
                radius: 8
                color: theme.colorBronze

                Text {
                    anchors.centerIn: parent
                    text: "➕ Registrar Cliente"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newClientDialog.open()
                }
            }
        }

        // LISTA DE CLIENTES EN QML (RF3.1: CLASIFICACIÓN DINO B2B 72 DÍAS Y B2C)
        Repeater {
            model: cliRoot.clients

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
                            text: modelData.razon_social_nombre + " (" + modelData.tipo_cliente + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "RUC/Cédula: " + modelData.ruc_cedula + " | Tel: " + modelData.telefono + " | Email: " + modelData.email
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    // BADGE CRÉDITO CONCEDIDO: 72 DÍAS EN TWINKLE SLATE Y BRONCE CÁLIDO
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Rectangle {
                            color: modelData.tipo_cliente === "B2B" ? theme.badgeBgBronze : theme.badgeBgSuccess
                            radius: 6
                            width: creditTxt.width + 16
                            height: 28
                            border.color: theme.borderColor

                            Text {
                                id: creditTxt
                                anchors.centerIn: parent
                                text: modelData.tipo_cliente === "B2B" ? "Crédito Concedido: 72 Días" : "Sin Crédito (Pago al Contado)"
                                font.pixelSize: 11
                                font.bold: true
                                color: modelData.tipo_cliente === "B2B" ? theme.colorBronze : theme.colorSuccess
                            }
                        }

                        Button {
                            height: 28
                            width: 80
                            contentItem: Text { text: "Historial"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorSlate; radius: 6 }
                        }
                    }
                }
            }
        }
    }

    // DIÁLOGO REGISTRO CLIENTE B2B / B2C (RF3.1)
    Dialog {
        id: newClientDialog
        title: "Registrar Nuevo Cliente Corporativo"
        anchors.centerIn: parent
        modal: true
        width: 380

        Column {
            spacing: 10
            width: parent.width

            ComboBox {
                id: cliType
                width: parent.width
                model: ["B2B", "B2C"]
            }

            TextField { id: cliName; placeholderText: "Razón Social / Nombre Completo"; width: parent.width }
            TextField { id: cliRuc; placeholderText: "RUC / Cédula"; width: parent.width }
            TextField { id: cliPhone; placeholderText: "Teléfono / WhatsApp"; width: parent.width }
            TextField { id: cliEmail; placeholderText: "Correo Electrónico"; width: parent.width }
            TextField { id: cliAddress; placeholderText: "Dirección"; width: parent.width }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            var resStr = backend.addClient(
                cliName.text, cliType.currentText, cliRuc.text,
                cliPhone.text, cliEmail.text, cliAddress.text, 72
            )
            cliRoot.refresh()
        }
    }
}
