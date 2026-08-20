import QtQuick
import QtQuick.Controls

ScrollView {
    id: setRoot
    clip: true

    signal themeToggled(bool isDark)
    signal logoutRequested()

    Column {
        width: setRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 10; width: 1 }

        // Tarjeta Configuración de Apariencia QML
        Rectangle {
            width: parent.width
            height: 140
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: "🎨 Apariencia y Tema Visual (Twinkle Bronze & Steel Slate)"
                    font.pixelSize: 15
                    font.bold: true
                    color: theme.textPrimary
                }

                Text {
                    text: "Seleccione el tema preferido para la interfaz gráfica QML:"
                    font.pixelSize: 11
                    color: theme.textMuted
                }

                Row {
                    spacing: 12

                    // BOTÓN MODO CLARO
                    Rectangle {
                        width: 200
                        height: 40
                        radius: 8
                        color: !theme.isDark ? theme.colorBronze : theme.colorSlate

                        Text {
                            anchors.centerIn: parent
                            text: "☀️ Modo Claro (Por Defecto)"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { theme.isDark = false; setRoot.themeToggled(false) }
                        }
                    }

                    // BOTÓN MODO OSCURO
                    Rectangle {
                        width: 160
                        height: 40
                        radius: 8
                        color: theme.isDark ? theme.colorBronze : theme.colorSlate

                        Text {
                            anchors.centerIn: parent
                            text: "🌙 Modo Oscuro"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { theme.isDark = true; setRoot.themeToggled(true) }
                        }
                    }
                }
            }
        }

        // Tarjeta de Seguridad de Sesión QML (BOTÓN ROJO EXCLUSIVO DE CIERRE DE SESIÓN)
        Rectangle {
            width: parent.width
            height: 120
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: "🔒 Seguridad de Sesión"
                    font.pixelSize: 15
                    font.bold: true
                    color: theme.textPrimary
                }

                // BOTÓN ROJO DE CERRAR SESIÓN DE LA APLICACIÓN
                Rectangle {
                    id: btnRedLogout
                    width: 240
                    height: 42
                    radius: 8
                    color: btnRedLogoutMouse.pressed ? "#991B1B" : (btnRedLogoutMouse.hovered ? "#DC2626" : theme.colorDanger)

                    Text {
                        anchors.centerIn: parent
                        text: "🚪 Cerrar Sesión del CRM"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: btnRedLogoutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            backend.logout()
                            setRoot.logoutRequested()
                        }
                    }
                }
            }
        }
    }
}
