import QtQuick
import QtQuick.Controls

ScrollView {
    id: cliRoot
    clip: true

    property var clients: []
    property var selectedClient: null

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
        Item {
            width: parent.width
            height: 40

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "👥 Gestión de Clientes B2B / B2C y Políticas de Crédito"
                font.pixelSize: 15
                font.bold: true
                color: theme.textPrimary
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
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
                    onClicked: newClientPopup.open()
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
                            onClicked: historyPopup.openForClient(modelData.id, modelData.razon_social_nombre)
                        }

                        // MENÚ TRES PUNTOS (⋮) - EXCLUSIVO ADMINISTRADOR
                        Button {
                            id: btnClientDots
                            height: 28
                            width: 28
                            visible: backend.isAdmin()

                            contentItem: Text {
                                text: "⋮"
                                color: theme.textPrimary
                                font.bold: true
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: btnClientDots.hovered ? theme.bgCardHover : "transparent"
                                radius: 14
                                border.color: theme.borderColor
                            }

                            onClicked: clientActionMenu.open()

                            Menu {
                                id: clientActionMenu
                                y: btnClientDots.height

                                MenuItem {
                                    text: "✏️ Modificar Cliente"
                                    onTriggered: {
                                        cliRoot.selectedClient = modelData
                                        editClientName.text = modelData.razon_social_nombre
                                        editClientRuc.text = modelData.ruc_cedula
                                        editClientPhone.text = modelData.telefono || ""
                                        editClientEmail.text = modelData.email || ""
                                        editClientAddress.text = modelData.direccion || ""
                                        editClientProvincia.text = modelData.provincia || ""
                                        editClientType.currentIndex = editClientType.model.indexOf(modelData.tipo_cliente) >= 0 ? editClientType.model.indexOf(modelData.tipo_cliente) : 0
                                        editClientDialog.open()
                                    }
                                }
                                MenuItem {
                                    text: "🗑️ Eliminar de Base de Datos"
                                    onTriggered: {
                                        cliRoot.selectedClient = modelData
                                        deleteClientDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // DIÁLOGO REGISTRO CLIENTE B2B / B2C ESTILO CORPORATIVO Y ARRASTRABLE (RF3.1 y RF3.2)
    Popup {
        id: newClientPopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 440
        height: 600
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose
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
                    text: "📌 Registrar Nuevo Cliente (Mover con el Mouse)"
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
                            newClientPopup.x = newClientPopup.x + (mouse.x - dragOffset.x)
                            newClientPopup.y = newClientPopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO DE CLIENTES
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

                    Text { text: "Tipo de Empresa / Cliente (B2B o B2C):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: cliType
                        width: parent.width
                        model: ["B2B", "B2C"]
                    }

                    Rectangle {
                        width: parent.width
                        height: 30
                        color: theme.bgMain
                        radius: 6
                        border.color: theme.borderColor

                        Text {
                            anchors.centerIn: parent
                            text: cliType.currentText === "B2B" ? "📅 Crédito Automático: 72 Días Concedidos" : "💵 Restricción: Pago al Contado (0 Días)"
                            font.pixelSize: 11
                            font.bold: true
                            color: cliType.currentText === "B2B" ? theme.colorBronze : theme.colorSuccess
                        }
                    }

                    Text { text: "Cédula o RUC del Cliente (Mínimo 10, Máximo 13 dígitos):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: cliRuc
                        placeholderText: "ej. 0991234567001 o 0912345678"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                        onTextChanged: {
                            var r = text.trim();
                            if (r.length >= 2) {
                                var prefix = r.substring(0, 2);
                                var provinces = {
                                    "01": "Azuay", "02": "Bolívar", "03": "Cañar", "04": "Carchi",
                                    "05": "Cotopaxi", "06": "Chimborazo", "07": "El Oro", "08": "Esmeraldas",
                                    "09": "Guayas", "10": "Imbabura", "11": "Loja", "12": "Los Ríos",
                                    "13": "Manabí", "14": "Morona Santiago", "15": "Napo", "16": "Pastaza",
                                    "17": "Pichincha", "18": "Tungurahua", "19": "Zamora Chinchipe",
                                    "20": "Galápagos", "21": "Sucumbíos", "22": "Orellana",
                                    "23": "Santo Domingo de los Tsáchilas", "24": "Santa Elena", "30": "Extranjero"
                                };
                                cliProvincia.text = provinces[prefix] || "Provincia no detectada";
                            } else {
                                cliProvincia.text = "";
                            }
                        }
                    }

                    Text { text: "Provincia / País Detectado (Automático por Cédula/RUC):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: cliProvincia
                        placeholderText: "Se autodetecta según los dos primeros dígitos"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        readOnly: true
                        background: Rectangle {
                            color: theme.inputBg
                            radius: 6
                            border.color: theme.borderColor
                        }
                    }

                    Text { text: "Nombre Completo / Razón Social del Cliente:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: cliName
                        placeholderText: "ej. Inego Industrias S.A."
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Correo Electrónico (Requerido: @gmail.com, @hotmail.com, empresarial, etc.):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: cliEmail
                        placeholderText: "ej. contacto@gmail.com"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Número de Teléfono / WhatsApp (9 o 10 dígitos numéricos):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: cliPhone
                        placeholderText: "ej. 091234567"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]{9,10}$/ }
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Dirección del Cliente (Opcional):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: cliAddress
                        placeholderText: "ej. Av. Carlos Julio Arosemena Km 2.5"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }
                }
            }

            // BARRA INFERIOR DE ACCIONES
            Item {
                id: bottomBar
                width: parent.width
                height: 48
                anchors.bottom: parent.bottom

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Button {
                        width: 140
                        height: 34
                        contentItem: Text { text: "Guardar Cliente"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            var resStr = backend.addClient(
                                cliName.text, cliType.currentText, cliRuc.text,
                                cliPhone.text, cliEmail.text, cliAddress.text,
                                cliType.currentText === "B2B" ? 72 : 0, cliProvincia.text
                            )
                            var res = JSON.parse(resStr)
                            if (!res.success) {
                                cliErrTxt.text = res.message
                                cliErrDialog.open()
                            } else {
                                newClientPopup.close()
                                cliRoot.refresh()
                                // Reset fields
                                cliName.text = ""
                                cliRuc.text = ""
                                cliEmail.text = ""
                                cliPhone.text = ""
                                cliAddress.text = ""
                                cliProvincia.text = ""
                            }
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: {
                            newClientPopup.close()
                        }
                    }
                }
            }
        }
    }

    // POPUP MODAL AVISO DE ERROR DEL CLIENTE (COLOR UNIFORME TOTAL)
    Popup {
        id: cliErrDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 440
        height: 190
        padding: 16

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
                text: "Registro de Cliente"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                id: cliErrTxt
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
                    onClicked: cliErrDialog.close()
                }
            }
        }
    }

    // DIÁLOGO HISTORIAL COMERCIAL POR CLIENTE ESTILO CORPORATIVO Y ARRASTRABLE (RF3.4)
    Popup {
        id: historyPopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 520
        height: 450
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose
        padding: 0

        property var historyQuotes: []
        property string targetClientName: ""

        function openForClient(clientId, clientName) {
            targetClientName = clientName
            var raw = backend.getClientQuotes(clientId)
            historyQuotes = JSON.parse(raw)
            open()
        }

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

            // BARRA SUPERIOR ARRASTRABLE
            Rectangle {
                id: historyTitleBar
                width: parent.width
                height: 42
                color: theme.colorBronze
                radius: 10

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "📌 Historial Comercial: " + historyPopup.targetClientName + " (Mover)"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    property point dragOffset
                    onPressed: function(mouse) {
                        dragOffset = Qt.point(mouse.x, mouse.y)
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            historyPopup.x = historyPopup.x + (mouse.x - dragOffset.x)
                            historyPopup.y = historyPopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL HISTORIAL
            ScrollView {
                id: historyScroll
                anchors.top: historyTitleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: historyBottomBar.top
                anchors.margins: 14
                clip: true

                Column {
                    width: historyScroll.width - 20
                    spacing: 10

                    Repeater {
                        model: historyPopup.historyQuotes
                        delegate: Rectangle {
                            width: parent.width
                            height: 60
                            color: theme.bgMain
                            radius: 8
                            border.color: theme.borderColor

                            Item {
                                anchors.fill: parent
                                anchors.margins: 10

                                Column {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        text: "📄 " + modelData.numero_cotizacion
                                        font.bold: true
                                        font.pixelSize: 11
                                        color: theme.textPrimary
                                    }
                                    Text {
                                        text: "Fecha: " + modelData.fecha_emision + " | Plazo: " + (modelData.es_credito_72dias ? "Crédito B2B 72d" : "Contado")
                                        font.pixelSize: 10
                                        color: theme.textMuted
                                    }
                                }

                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12

                                    Text {
                                        text: "$" + modelData.total.toFixed(2) + " USD"
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: theme.colorSuccess
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        width: 80
                                        height: 22
                                        radius: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: {
                                            if (modelData.estado === "Aprobada" || modelData.estado === "Facturada") return theme.badgeBgSuccess
                                            if (modelData.estado === "Rechazada") return "#330F10"
                                            return "#1E293B"
                                        }
                                        border.color: theme.borderColor

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.estado
                                            color: {
                                                if (modelData.estado === "Aprobada" || modelData.estado === "Facturada") return theme.colorSuccess
                                                if (modelData.estado === "Rechazada") return "#EF4444"
                                                return "#E2E8F0"
                                            }
                                            font.bold: true
                                            font.pixelSize: 9
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "No se encontraron cotizaciones para este cliente."
                        visible: historyPopup.historyQuotes.length === 0
                        color: theme.textMuted
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                }
            }

            // BARRA INFERIOR DE ACCIONES
            Item {
                id: historyBottomBar
                width: parent.width
                height: 48
                anchors.bottom: parent.bottom

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cerrar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: {
                            historyPopup.close()
                        }
                    }
                }
            }
        }
    }

    // POPUP EDITAR CLIENTE (ADMIN)
    // POPUP EDITAR CLIENTE (ADMIN)
    Popup {
        id: editClientDialog
        parent: Overlay.overlay
        x: Math.max(20, (parent.width - width) / 2)
        y: Math.max(20, (parent.height - height) / 2)
        width: 480
        height: 580
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose
        padding: 0

        Overlay.modal: Rectangle { color: "#60000000" }

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
                id: editClientTitleBar
                width: parent.width
                height: 42
                color: theme.colorBronze
                radius: 10

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✏️ Modificar Datos del Cliente (Mover con el Mouse)"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    property point dragOffset
                    onPressed: function(mouse) { dragOffset = Qt.point(mouse.x, mouse.y) }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            editClientDialog.x = editClientDialog.x + (mouse.x - dragOffset.x)
                            editClientDialog.y = editClientDialog.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO
            ScrollView {
                id: editClientScroll
                anchors.top: editClientTitleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: editClientBottomBar.top
                anchors.margins: 14
                clip: true

                Column {
                    width: editClientScroll.width - 20
                    spacing: 10

                    Text { text: "Razón Social / Nombre Completo:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: editClientName
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Tipo de Cliente (B2B / B2C):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: editClientType
                        width: parent.width
                        model: ["B2B", "B2C"]
                    }

                    Text { text: "Cédula o RUC del Cliente (10 a 13 dígitos):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: editClientRuc
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                        onTextChanged: {
                            var r = text.trim();
                            if (r.length >= 2) {
                                var prefix = r.substring(0, 2);
                                var provinces = {
                                    "01": "Azuay", "02": "Bolívar", "03": "Cañar", "04": "Carchi",
                                    "05": "Cotopaxi", "06": "Chimborazo", "07": "El Oro", "08": "Esmeraldas",
                                    "09": "Guayas", "10": "Imbabura", "11": "Loja", "12": "Los Ríos",
                                    "13": "Manabí", "14": "Morona Santiago", "15": "Napo", "16": "Pastaza",
                                    "17": "Pichincha", "18": "Tungurahua", "19": "Zamora Chinchipe",
                                    "20": "Galápagos", "21": "Sucumbíos", "22": "Orellana",
                                    "23": "Santo Domingo de los Tsáchilas", "24": "Santa Elena", "30": "Extranjero"
                                };
                                editClientProvincia.text = provinces[prefix] || "Provincia no detectada";
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        Column {
                            width: (parent.width - 12) / 2
                            spacing: 4
                            Text { text: "Teléfono (10 dígitos con 0):"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                            TextField {
                                id: editClientPhone
                                width: parent.width
                                color: theme.inputColor
                                font.bold: true
                                font.pixelSize: 12
                                selectionColor: theme.colorBronze
                                selectedTextColor: "#FFFFFF"
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: RegularExpressionValidator { regularExpression: /^[0-9]{9,10}$/ }
                                background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                            }
                        }

                        Column {
                            width: (parent.width - 12) / 2
                            spacing: 4
                            Text { text: "Provincia:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                            TextField {
                                id: editClientProvincia
                                width: parent.width
                                color: theme.inputColor
                                font.bold: true
                                font.pixelSize: 12
                                background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                            }
                        }
                    }

                    Text { text: "Correo Electrónico:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: editClientEmail
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Dirección del Cliente:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: editClientAddress
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }
                }
            }

            // BARRA INFERIOR DE ACCIONES
            Item {
                id: editClientBottomBar
                width: parent.width
                height: 48
                anchors.bottom: parent.bottom

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Button {
                        width: 140
                        height: 34
                        contentItem: Text { text: "Guardar Cambios"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            if (!cliRoot.selectedClient) return
                            var ph = editClientPhone.text.trim()
                            if (ph.length > 0 && (ph.length !== 10 || !ph.startsWith("0"))) {
                                cliErrTxt.text = "⚠️ El número de teléfono debe tener exactamente 10 dígitos (incluyendo el 0 inicial)."
                                cliErrDialog.open()
                                return
                            }
                            var resStr = backend.updateClient(
                                cliRoot.selectedClient.id,
                                editClientName.text.trim(),
                                editClientType.currentText,
                                editClientRuc.text.trim(),
                                ph,
                                editClientEmail.text.trim(),
                                editClientAddress.text.trim(),
                                editClientProvincia.text.trim()
                            )
                            var res = JSON.parse(resStr)
                            if (!res.success) {
                                cliErrTxt.text = res.message
                                cliErrDialog.open()
                            } else {
                                editClientDialog.close()
                                cliRoot.refresh()
                            }
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: editClientDialog.close()
                    }
                }
            }
        }
    }

    // POPUP ELIMINAR CLIENTE (ADMIN)
    Popup {
        id: deleteClientDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 420
        height: 200
        padding: 16

        Overlay.modal: Rectangle { color: "#60000000" }

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorDanger
            border.width: 2
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 14

            Text {
                text: "🗑️ Eliminar Cliente"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorDanger
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "¿Está seguro que desea eliminar al cliente " + (cliRoot.selectedClient ? cliRoot.selectedClient.razon_social_nombre : "") + " de la base de datos?\nEsta acción no se puede deshacer."
                font.pixelSize: 11
                color: theme.textPrimary
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    height: 34
                    width: 130
                    contentItem: Text { text: "Sí, Eliminar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorDanger; radius: 6 }
                    onClicked: {
                        if (!cliRoot.selectedClient) return
                        var ok = backend.deleteClient(cliRoot.selectedClient.id)
                        if (ok) {
                            deleteClientDialog.close()
                            cliRoot.refresh()
                        }
                    }
                }

                Button {
                    height: 34
                    width: 100
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: deleteClientDialog.close()
                }
            }
        }
    }
}
