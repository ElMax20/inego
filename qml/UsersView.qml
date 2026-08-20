import QtQuick
import QtQuick.Controls

ScrollView {
    id: userRoot
    clip: true

    property var users: []
    property var auditLogs: []
    property string activeTab: "users"
    property string currentUserRole: ""
    property bool isAdmin: currentUserRole === "Administrador" || currentUserRole === "Administrador de Dinero"

    Component.onCompleted: refresh()

    function refresh() {
        currentUserRole = backend.getCurrentUserRole()
        users = []
        var rawU = backend.getUsersData()
        users = JSON.parse(rawU)

        auditLogs = []
        var rawA = backend.getAuditLogData()
        auditLogs = JSON.parse(rawA)
    }

    Column {
        width: userRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // Pestañas Segmentadas Superiores del Módulo "Usuario y Bitácora"
        Row {
            spacing: 12

            Rectangle {
                height: 40
                width: tab1Txt.width + 28
                radius: 8
                color: userRoot.activeTab === "users" ? theme.colorBronze : theme.colorSlate

                Text {
                    id: tab1Txt
                    anchors.centerIn: parent
                    text: "🛡️ Usuarios Registrados y Perfiles"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userRoot.activeTab = "users"
                }
            }

            Rectangle {
                height: 40
                width: tab2Txt.width + 28
                radius: 8
                color: userRoot.activeTab === "audit" ? theme.colorBronze : theme.colorSlate

                Text {
                    id: tab2Txt
                    anchors.centerIn: parent
                    text: "📋 Bitácora de Auditoría (Exclusivo Admin)"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userRoot.activeTab = "audit"
                }
            }
        }

        // ==========================================
        // SUB-SECCIÓN 1: GESTIÓN DE USUARIOS
        // ==========================================
        Column {
            width: parent.width
            spacing: 16
            visible: userRoot.activeTab === "users"

            Row {
                width: parent.width

                Text {
                    text: "🛡️ Control de Usuarios Registrados y Asignación de Roles"
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
                        text: "➕ Crear Nuevo Usuario"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            newUserPopup.x = Math.max(20, (Overlay.overlay.width - newUserPopup.width) / 2)
                            newUserPopup.y = Math.max(20, (Overlay.overlay.height - newUserPopup.height) / 2)
                            newUserPopup.open()
                        }
                    }
                }
            }

            // LISTA DE USUARIOS
            Repeater {
                model: userRoot.users

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
                                text: "🛡️ " + modelData.nombre_completo + " (@" + modelData.username + ")"
                                font.pixelSize: 13
                                font.bold: true
                                color: theme.textPrimary
                            }
                            Text {
                                text: "Perfil / Rol Asignado: " + modelData.rol + " | Estado Acceso: " + (modelData.activo ? "Activo" : "Inactivo")
                                font.pixelSize: 11
                                color: theme.textMuted
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            // BADGE ESTADO
                            Rectangle {
                                color: modelData.activo ? theme.badgeBgSuccess : theme.badgeBgDanger
                                radius: 6
                                width: usrStTxt.width + 16
                                height: 26

                                Text {
                                    id: usrStTxt
                                    anchors.centerIn: parent
                                    text: modelData.activo ? "ACTIVO" : "BLOQUEADO"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: modelData.activo ? theme.colorSuccess : theme.colorDanger
                                }
                            }

                            // BOTÓN ACTIVAR / DESACTIVAR (PROTEGIDO PARA CUENTAS ADMIN)
                            Rectangle {
                                visible: !(modelData.rol === "Administrador" || modelData.rol === "Administrador de Dinero" || modelData.username === "admin")
                                height: 28
                                width: 100
                                radius: 6
                                color: modelData.activo ? theme.colorDanger : theme.colorSuccess

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.activo ? "Desactivar" : "Activar"
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var resStr = backend.toggleUserStatus(modelData.id)
                                        var res = JSON.parse(resStr)
                                        if (!res.success) {
                                            errMsgTxt.text = res.message
                                            errDialog.open()
                                        }
                                        userRoot.refresh()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // SUB-SECCIÓN 2: BITÁCORA DE AUDITORÍA INDEPENDIENTE
        // ==========================================
        Column {
            width: parent.width
            spacing: 14
            visible: userRoot.activeTab === "audit"

            Text {
                text: "📋 Bitácora de Auditoría en Tareas Compartidas (Registro Automático de Operaciones)"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
            }

            Text {
                text: "Guarda automáticamente el nombre del socio/empleado, fecha, hora y detalles cada vez que se realiza un despacho, entrega física, compra o acceso:"
                font.pixelSize: 11
                color: theme.textMuted
            }

            // TARJETAS RESTRICCIÓN SI NO ES ADMIN
            Rectangle {
                visible: !userRoot.isAdmin
                width: parent.width
                height: 100
                color: theme.badgeBgDanger
                radius: 10
                border.color: theme.colorDanger

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "🔒 ACCESO RESTRINGIDO"
                        font.pixelSize: 14
                        font.bold: true
                        color: theme.colorDanger
                    }
                    Text {
                        text: "La Bitácora de Auditoría en tareas compartidas sólo está disponible para el Usuario Administrador."
                        font.pixelSize: 11
                        color: theme.textPrimary
                    }
                }
            }

            // LISTADO DE REGISTROS DE AUDITORÍA PARA ADMIN
            Repeater {
                model: userRoot.isAdmin ? userRoot.auditLogs : []

                Rectangle {
                    width: parent.width
                    height: 54
                    color: theme.bgCard
                    radius: 8
                    border.color: theme.borderColor

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12

                        Column {
                            spacing: 4
                            Text {
                                text: "👤 " + modelData.usuario_nombre + "  |  ⚡ " + modelData.tipo_accion + "  (" + modelData.fecha_hora + ")"
                                font.pixelSize: 12
                                font.bold: true
                                color: theme.textPrimary
                            }
                            Text {
                                text: "📝 Detalles: " + modelData.detalles
                                font.pixelSize: 11
                                color: theme.textMuted
                            }
                        }
                    }
                }
            }
        }
    }

    // VENTANA MODAL FLOTANTE ARRASTRABLE Y REDIMENSIONABLE (ESTILO SEGUNDA IMAGEN)
    Popup {
        id: newUserPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose
        width: 440
        height: 480
        padding: 0

        Overlay.modal: Rectangle {
            color: "#60000000"
        }

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorBronze
            border.width: 2
        }

        contentItem: Item {
            anchors.fill: parent

            // BARRA SUPERIOR ARRASTRABLE CON EL MOUSE
            Rectangle {
                id: titleBar
                width: parent.width
                height: 42
                color: theme.colorBronze
                radius: 10

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "📌 Registrar Nuevo Usuario Corporativo (Mover con el Mouse)"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                }

                // ARRASTRE FLUIDO CON EL MOUSE
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    property point dragOffset
                    onPressed: function(mouse) {
                        dragOffset = Qt.point(mouse.x, mouse.y)
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            newUserPopup.x = newUserPopup.x + (mouse.x - dragOffset.x)
                            newUserPopup.y = newUserPopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO DE USUARIOS
            ScrollView {
                anchors.top: titleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bottomBar.top
                anchors.margins: 14
                clip: true

                Column {
                    width: parent.width - 20
                    spacing: 10

                    Text { text: "Nombre de usuario (ej. compras2):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: newUname; placeholderText: "ej. compras2"; width: parent.width }

                    Text { text: "Nombre completo (ej. Ing. Carlos Mendoza):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: newFullName; placeholderText: "ej. Ing. Carlos Mendoza"; width: parent.width }

                    Text { text: "Contraseña de acceso:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: newPass; placeholderText: "Contraseña de acceso"; echoMode: TextInput.Password; width: parent.width }

                    Text { text: "Perfil / Rol Asignado:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: newRole
                        width: parent.width
                        model: ["Compras y Mercadería", "Contabilidad", "Administrador de Dinero"]
                    }
                }
            }

            // BARRA INFERIOR DE ACCIONES Y MANIJA DE REDIMENSIÓN
            Item {
                id: bottomBar
                width: parent.width
                height: 48
                anchors.bottom: parent.bottom

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Button {
                        width: 130
                        height: 34
                        contentItem: Text { text: "Guardar Usuario"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            var resStr = backend.createUser(newUname.text, newFullName.text, newPass.text, newRole.currentText)
                            var res = JSON.parse(resStr)
                            newUserPopup.close()
                            userRoot.refresh()
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: newUserPopup.close()
                    }
                }

                // MANIJA INFERIOR DERECHA PARA REDIMENSIONAR
                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    text: "◢"
                    font.pixelSize: 16
                    color: theme.colorBronze

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeFDiagCursor
                        property point lastMousePos
                        onPressed: function(mouse) { lastMousePos = Qt.point(mouse.x, mouse.y) }
                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                var deltaX = mouse.x - lastMousePos.x
                                var deltaY = mouse.y - lastMousePos.y
                                newUserPopup.width = Math.max(360, newUserPopup.width + deltaX)
                                newUserPopup.height = Math.max(400, newUserPopup.height + deltaY)
                            }
                        }
                    }
                }
            }
        }
    }

    // DIÁLOGO MENSAJE DE ERROR (SOBRE OVERLAY)
    Dialog {
        id: errDialog
        parent: Overlay.overlay
        title: "Seguridad de Usuarios"
        anchors.centerIn: parent
        modal: true

        Text {
            id: errMsgTxt
            text: ""
            color: theme.textPrimary
            font.pixelSize: 12
        }

        standardButtons: Dialog.Ok
    }
}
