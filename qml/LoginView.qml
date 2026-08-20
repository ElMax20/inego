import QtQuick
import QtQuick.Controls

Rectangle {
    id: loginRoot
    color: theme.bgMain

    signal loginSuccess(string username, string role)

    property int attempts: 0

    function doLogin() {
        if (txtUser.text.trim() === "" || txtPass.text.trim() === "") {
            txtErr.text = "Por favor ingrese usuario y contraseña"
            errBox.visible = true
            return
        }

        var resStr = backend.authenticate(txtUser.text, txtPass.text)
        var res = JSON.parse(resStr)
        if (res.success) {
            errBox.visible = false
            loginSuccess(res.user.nombre_completo, res.user.rol)
        } else {
            loginRoot.attempts++
            txtErr.text = res.message + " (Intentos: " + loginRoot.attempts + "/3)"
            errBox.visible = true
            if (loginRoot.attempts >= 3) {
                txtErr.text = "🚨 Sistema Bloqueado por 3 Intentos Fallidos. Cerrando aplicación..."
                btnLogin.enabled = false
                closeTimer.start()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 1500
        repeat: false
        onTriggered: Qt.quit()
    }

    Rectangle {
        id: card
        width: 400
        height: 480
        anchors.centerIn: parent
        color: theme.bgCard
        radius: 14
        border.color: theme.borderColor
        border.width: 1

        // Componentes de la Pantalla de Login QML
        Column {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 16

            // Header con Logo de Imagen Ultra Nítido
            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    source: "../logo.png"
                    width: 48
                    height: 48
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    sourceSize.width: 256
                    sourceSize.height: 256
                }

                Column {
                    Text {
                        text: "INEGO INDUSTRIAS"
                        font.pixelSize: 18
                        font.bold: true
                        color: theme.textPrimary
                    }
                    Text {
                        text: "ERP / CRM QML System v2.0"
                        font.pixelSize: 11
                        color: theme.colorBronze
                        font.bold: true
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: theme.borderColor }

            // Campo Usuario (Campos vacíos por defecto + Enter para ingresar)
            Text {
                text: "USUARIO CORPORATIVO"
                font.pixelSize: 11
                font.bold: true
                color: theme.textMuted
            }

            TextField {
                id: txtUser
                width: parent.width
                height: 42
                placeholderText: "Ingrese su usuario corporativo..."
                text: ""
                color: theme.textPrimary
                onAccepted: loginRoot.doLogin()
                background: Rectangle {
                    color: theme.bgMain
                    radius: 8
                    border.color: txtUser.activeFocus ? theme.colorBronze : theme.borderColor
                }
            }

            // Campo Contraseña (Campos vacíos por defecto + Enter para ingresar)
            Text {
                text: "CONTRASEÑA DE ACCESO"
                font.pixelSize: 11
                font.bold: true
                color: theme.textMuted
            }

            TextField {
                id: txtPass
                width: parent.width
                height: 42
                echoMode: TextInput.Password
                placeholderText: "••••••••"
                text: ""
                color: theme.textPrimary
                onAccepted: loginRoot.doLogin()
                background: Rectangle {
                    color: theme.bgMain
                    radius: 8
                    border.color: txtPass.activeFocus ? theme.colorBronze : theme.borderColor
                }
            }

            // Mensaje de Error
            Rectangle {
                id: errBox
                width: parent.width
                height: 36
                visible: false
                color: theme.badgeBgDanger
                radius: 6

                Text {
                    id: txtErr
                    anchors.centerIn: parent
                    text: ""
                    color: theme.colorDanger
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            // Botón de Iniciar Sesión QML
            Button {
                id: btnLogin
                width: parent.width
                height: 44

                contentItem: Text {
                    text: "🔐 Iniciar Sesión en el CRM"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: btnLogin.pressed ? theme.colorBronzeHover : theme.colorBronze
                    radius: 8
                    scale: btnLogin.pressed ? 0.98 : (btnLogin.hovered ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }

                onClicked: loginRoot.doLogin()
            }

            Text {
                text: "Guayaquil, Ecuador"
                font.pixelSize: 10
                color: theme.textMuted
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
