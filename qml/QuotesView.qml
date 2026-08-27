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

        // Fila de Título y Botón Crear Cotización (RF3.3)
        Item {
            width: parent.width
            height: 40

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "📋 Cotizaciones Emitidas e Historial de Clientes"
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
                    text: "➕ Crear Cotización"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newQuotePopup.openQuoteDialog()
                }
            }
        }

        // LISTA DE COTIZACIONES EN QML CON ACCIONES Y BOTONES DE CONVERSIÓN
        Repeater {
            model: qRoot.quotes

            Rectangle {
                width: parent.width
                height: 110
                color: theme.bgCard
                radius: 10
                border.color: theme.borderColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Fila 1: Info e insignias de estado (Usando Item para evitar fallos de layout de Row)
                    Item {
                        width: parent.width
                        height: 38

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "📋 " + modelData.numero_cotizacion + " - " + modelData.cliente_nombre
                                font.pixelSize: 12
                                font.bold: true
                                color: theme.textPrimary
                            }
                            Text {
                                text: "📞 " + modelData.cliente_telefono + " | ✉️ " + modelData.cliente_correo + " | Total: $" + modelData.total.toFixed(2) + " USD"
                                font.pixelSize: 10
                                color: theme.textMuted
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Rectangle {
                                color: {
                                    if (modelData.estado === "Aprobada" || modelData.estado === "Facturada") return theme.badgeBgSuccess
                                    if (modelData.estado === "Rechazada") return "#330F10"
                                    return "#1E293B"
                                }
                                radius: 6
                                width: stTxt.width + 16
                                height: 24

                                Text {
                                    id: stTxt
                                    anchors.centerIn: parent
                                    text: modelData.estado === "Facturada" ? "Orden de Venta" : modelData.estado
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: {
                                        if (modelData.estado === "Aprobada" || modelData.estado === "Facturada") return theme.colorSuccess
                                        if (modelData.estado === "Rechazada") return "#EF4444"
                                        return "#E2E8F0"
                                    }
                                }
                            }

                            Rectangle {
                                color: modelData.es_credito_72dias ? theme.badgeBgBronze : theme.badgeBgSuccess
                                radius: 6
                                width: credTxt.width + 16
                                height: 24

                                Text {
                                    id: credTxt
                                    anchors.centerIn: parent
                                    text: modelData.es_credito_72dias ? "Crédito 72d" : "Contado"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: modelData.es_credito_72dias ? theme.colorBronze : theme.colorSuccess
                                }
                            }
                        }
                    }

                    // Fila 2: Botones de Acción (PDF, WhatsApp, Gmail, Convertir a Venta)
                    Row {
                        spacing: 8
                        width: parent.width

                        Button {
                            height: 28
                            width: 70
                            contentItem: Text { text: "📄 PDF"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorBronze; radius: 6 }
                            onClicked: backend.generateAndOpenQuotePDF(modelData.id)
                        }

                        Button {
                            height: 28
                            width: 80
                            contentItem: Text { text: "✉️ Gmail"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorSlate; radius: 6 }
                            onClicked: {
                                var shareInfoRaw = backend.prepareQuoteSharing(modelData.id)
                                var shareInfo = JSON.parse(shareInfoRaw)
                                if (!shareInfo.success) return

                                var clientEmail = (modelData.cliente_correo && modelData.cliente_correo !== "N/A") ? modelData.cliente_correo : ""
                                var subject = "Cotización " + modelData.numero_cotizacion + " - Inego Industrias"
                                var body = "Estimado cliente,\n\nAdjuntamos la Cotización " + modelData.numero_cotizacion + " de Inego Industrias por un valor total de $" + modelData.total.toFixed(2) + " USD.\n\n(Nota: El archivo PDF de la cotización ha sido copiado a tu portapapeles. Solo presiona Ctrl+V para adjuntarlo en este correo).\n\nQuedamos a su entera disposición.\n\nSaludos cordiales,\nInego Industrias"
                                
                                var gmailUrl = "https://mail.google.com/mail/?view=cm&fs=1" +
                                               "&to=" + encodeURIComponent(clientEmail) +
                                               "&su=" + encodeURIComponent(subject) +
                                               "&body=" + encodeURIComponent(body)
                                
                                Qt.openUrlExternally(gmailUrl)
                            }
                        }

                        Button {
                            height: 28
                            width: 100
                            contentItem: Text { text: "💬 WhatsApp"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: "#15803D"; radius: 6 }
                            onClicked: {
                                var shareInfoRaw = backend.prepareQuoteSharing(modelData.id)
                                var shareInfo = JSON.parse(shareInfoRaw)
                                if (!shareInfo.success) return

                                var textMsg = "Estimado cliente, adjuntamos la Cotización " + modelData.numero_cotizacion + 
                                              " de Inego Industrias por un valor de $" + modelData.total.toFixed(2) + " USD. " +
                                              "(El archivo PDF ha sido copiado a tu portapapeles. Presiona Ctrl+V en el chat para adjuntarlo y enviarlo)."
                                var wsUrl = "https://wa.me/?text=" + encodeURIComponent(textMsg)
                                Qt.openUrlExternally(wsUrl)
                            }
                        }

                        Button {
                            height: 28
                            width: 140
                            visible: modelData.estado !== "Facturada"
                            contentItem: Text { text: "🔄 Convertir a Venta"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: "#0F766E"; radius: 6 }
                            onClicked: {
                                var res = backend.convertQuoteToOrder(modelData.id)
                                var obj = JSON.parse(res)
                                if (obj.success) {
                                    qRoot.refresh()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // DIÁLOGO CREAR COTIZACIÓN EXPRESS ESTILO CORPORATIVO Y ARRASTRABLE (RF3.3)
    Popup {
        id: newQuotePopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 580
        height: 640
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose
        padding: 0

        property var clientsList: []
        property var productsList: []
        property var cart: []
        property double subtotalVal: 0.0
        property double ivaVal: 0.0
        property double totalVal: 0.0

        function openQuoteDialog() {
            var rawC = backend.getClientsData()
            clientsList = JSON.parse(rawC)
            
            var rawP = backend.getInventoryData("")
            productsList = JSON.parse(rawP)

            cart = []
            recalc()
            open()
        }

        function recalc() {
            var sub = 0.0
            for (var i = 0; i < cart.length; i++) {
                sub += cart[i].subtotal_linea
            }
            subtotalVal = sub
            ivaVal = sub * 0.15
            totalVal = sub + ivaVal
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
                id: titleBar
                width: parent.width
                height: 42
                color: theme.colorBronze
                radius: 10

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "📌 Crear Nueva Cotización Express (Mover con el Mouse)"
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
                            newQuotePopup.x = newQuotePopup.x + (mouse.x - dragOffset.x)
                            newQuotePopup.y = newQuotePopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL COTIZADOR
            ScrollView {
                id: popupScroll
                anchors.top: titleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bottomBar.top
                anchors.margins: 14
                clip: true

                Column {
                    width: popupScroll.width - 20
                    spacing: 12

                    // 1. Selector de Cliente
                    Text { text: "Seleccione el Cliente:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: cmbClient
                        width: parent.width
                        textRole: "razon_social_nombre"
                        model: newQuotePopup.clientsList
                    }

                    // 2. Sección para agregar producto
                    Rectangle {
                        width: parent.width
                        height: 140
                        color: theme.bgCard
                        radius: 8
                        border.color: theme.borderColor

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Text { text: "Agregar Ítem a la Cotización:"; font.bold: true; font.pixelSize: 11; color: theme.textPrimary }
                            
                            ComboBox {
                                id: cmbProduct
                                width: parent.width
                                textRole: "nombre"
                                model: newQuotePopup.productsList
                            }

                            Row {
                                spacing: 10
                                width: parent.width

                                Column {
                                    spacing: 4
                                    Text { text: "Cant."; font.pixelSize: 9; font.bold: true; color: theme.textMuted }
                                    TextField {
                                        id: txtQty
                                        width: 70
                                        height: 32
                                        text: "1"
                                        color: theme.textPrimary
                                        inputMethodHints: Qt.ImhDigitsOnly
                                    }
                                }

                                Column {
                                    spacing: 4
                                    Text { text: "Margen %"; font.pixelSize: 9; font.bold: true; color: theme.textMuted }
                                    TextField {
                                        id: txtMargin
                                        width: 80
                                        height: 32
                                        text: "30"
                                        color: theme.textPrimary
                                        inputMethodHints: Qt.ImhDigitsOnly
                                    }
                                }

                                Item {
                                    width: 10; height: 1
                                }

                                Button {
                                    text: "➕ Agregar"
                                    width: 110
                                    height: 32
                                    anchors.bottom: parent.bottom
                                    contentItem: Text { text: "➕ Agregar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: theme.colorBronze; radius: 6 }
                                    onClicked: {
                                        if (cmbProduct.currentIndex < 0) return
                                        var pSel = newQuotePopup.productsList[cmbProduct.currentIndex]
                                        var qty = parseInt(txtQty.text) || 1
                                        var margin = parseFloat(txtMargin.text) || 30.0
                                        var cost = pSel.costo || 10.0
                                        var pVenta = cost * (1 + margin / 100)
                                        var subLine = qty * pVenta

                                        // Verificar si el producto ya está en el carrito
                                        var foundIndex = -1
                                        for (var i = 0; i < newQuotePopup.cart.length; i++) {
                                            if (newQuotePopup.cart[i].producto_id === pSel.id) {
                                                foundIndex = i
                                                break
                                            }
                                        }

                                        if (foundIndex !== -1) {
                                            duplicateConfirmDialog.dupItem = newQuotePopup.cart[foundIndex]
                                            duplicateConfirmDialog.dupIndex = foundIndex
                                            txtNewQtyVal.text = newQuotePopup.cart[foundIndex].cantidad.toString()
                                            duplicateConfirmDialog.open()
                                        } else {
                                            var item = {
                                                "producto_id": pSel.id,
                                                "nombre": pSel.nombre,
                                                "codigo": pSel.codigo,
                                                "cantidad": qty,
                                                "precio_costo": cost,
                                                "precio_venta": pVenta,
                                                "subtotal_linea": subLine
                                            }
                                            
                                            var tempCart = []
                                            for (var j = 0; j < newQuotePopup.cart.length; j++) {
                                                tempCart.push(newQuotePopup.cart[j])
                                            }
                                            tempCart.push(item)
                                            newQuotePopup.cart = tempCart
                                            newQuotePopup.recalc()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. Lista de Ítems en Cotización
                    Text { text: "Detalle de los Ítems Agregados (Carrito):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    
                    Column {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: newQuotePopup.cart
                            delegate: Rectangle {
                                width: parent.width
                                height: 46
                                color: theme.bgMain
                                radius: 6
                                border.color: theme.borderColor

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 8

                                    Text {
                                        id: txtName
                                        text: "📦 " + modelData.nombre
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: theme.textPrimary
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 340
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        id: txtPUnit
                                        text: "P. Unit: $" + modelData.precio_venta.toFixed(2)
                                        font.pixelSize: 10
                                        color: theme.textSecondary
                                        anchors.left: txtName.right
                                        anchors.leftMargin: 12
                                        width: 85
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        id: txtCant
                                        text: "Cant: " + modelData.cantidad
                                        font.pixelSize: 10
                                        color: theme.textSecondary
                                        anchors.left: txtPUnit.right
                                        anchors.leftMargin: 12
                                        width: 50
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        id: txtTotalIva
                                        text: "Total + IVA: $" + (modelData.subtotal_linea * 1.15).toFixed(2)
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: theme.colorSuccess
                                        anchors.left: txtCant.right
                                        anchors.leftMargin: 12
                                        width: 105
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Button {
                                        width: 24
                                        height: 24
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        contentItem: Text { text: "❌"; font.pixelSize: 9; color: "#EF4444"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        background: Rectangle { color: "transparent" }
                                        onClicked: {
                                            var tempCart = []
                                            for (var i = 0; i < newQuotePopup.cart.length; i++) {
                                                if (i !== index) {
                                                    tempCart.push(newQuotePopup.cart[i])
                                                }
                                            }
                                            newQuotePopup.cart = tempCart
                                            newQuotePopup.recalc()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 4. Totales
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: theme.bgCard
                        radius: 8
                        border.color: theme.borderColor

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 20
                            
                            Column {
                                Text { text: "Subtotal"; font.pixelSize: 10; color: theme.textMuted }
                                Text { text: "$" + newQuotePopup.subtotalVal.toFixed(2); font.pixelSize: 11; font.bold: true; color: theme.textPrimary }
                            }
                            Column {
                                Text { text: "IVA (15%)"; font.pixelSize: 10; color: theme.textMuted }
                                Text { text: "$" + newQuotePopup.ivaVal.toFixed(2); font.pixelSize: 11; font.bold: true; color: "#EF4444" }
                            }
                            Column {
                                Text { text: "Total USD"; font.pixelSize: 10; color: theme.textMuted }
                                Text { text: "$" + newQuotePopup.totalVal.toFixed(2); font.pixelSize: 13; font.bold: true; color: theme.colorSuccess }
                            }
                        }
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
                        width: 180
                        height: 34
                        contentItem: Text { text: "Generar Cotización Oficial"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            if (newQuotePopup.cart.length === 0) return
                            var cSel = newQuotePopup.clientsList[cmbClient.currentIndex]
                            var res = backend.createQuote(
                                cSel.id,
                                cSel.tipo_cliente,
                                newQuotePopup.subtotalVal,
                                newQuotePopup.ivaVal,
                                newQuotePopup.totalVal,
                                JSON.stringify(newQuotePopup.cart)
                            )
                            newQuotePopup.close()
                            qRoot.refresh()
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: {
                            newQuotePopup.close()
                        }
                    }
                }
            }
        }
    }

    // POPUPS MODALES DE CONFIRMACIÓN Y CAMBIO DE CANTIDAD PARA PRODUCTOS DUPLICADOS (COLOR UNIFORME TOTAL)
    Popup {
        id: duplicateConfirmDialog
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

        property var dupItem: null
        property int dupIndex: -1

        contentItem: Column {
            anchors.fill: parent
            spacing: 14

            Text {
                text: "Producto Duplicado"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Este objeto ya está en la cotización, ¿Desea cambiar la cantidad?"
                color: theme.textPrimary
                font.bold: true
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    height: 34
                    width: 100
                    contentItem: Text { text: "Sí, Cambiar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorBronze; radius: 6 }
                    onClicked: {
                        duplicateConfirmDialog.close()
                        changeQtyDialog.openForItem(duplicateConfirmDialog.dupItem, duplicateConfirmDialog.dupIndex)
                    }
                }

                Button {
                    height: 34
                    width: 100
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: duplicateConfirmDialog.close()
                }
            }
        }
    }

    Popup {
        id: changeQtyDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 440
        height: 230
        padding: 16

        Overlay.modal: Rectangle { color: "#60000000" }

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorBronze
            border.width: 2
        }

        property var targetItem: null
        property int targetIndex: -1

        function openForItem(item, idx) {
            targetItem = item
            targetIndex = idx
            txtNewQtyVal.text = item.cantidad.toString()
            open()
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 12

            Text {
                text: "Modificar Cantidad"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
            }

            Text {
                                    }
                                }
                            }
                        }
                    }

                    // 4. Totales
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: theme.bgCard
                        radius: 8
                        border.color: theme.borderColor

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 20
                            
                            Column {
                                Text { text: "Subtotal"; font.pixelSize: 10; color: theme.textMuted }
                                Text { text: "$" + newQuotePopup.subtotalVal.toFixed(2); font.pixelSize: 11; font.bold: true; color: theme.textPrimary }
                            }
                            Column {
                                Text { text: "IVA (15%)"; font.pixelSize: 10; color: theme.textMuted }
                                Text { text: "$" + newQuotePopup.ivaVal.toFixed(2); font.pixelSize: 11; font.bold: true; color: "#EF4444" }
                            }
                            Column {
                                Text { text: "Total USD"; font.pixelSize: 10; color: theme.textMuted }
                                Text { text: "$" + newQuotePopup.totalVal.toFixed(2); font.pixelSize: 13; font.bold: true; color: theme.colorSuccess }
                            }
                        }
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
                        width: 180
                        height: 34
                        contentItem: Text { text: "Generar Cotización Oficial"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            if (newQuotePopup.cart.length === 0) return
                            var cSel = newQuotePopup.clientsList[cmbClient.currentIndex]
                            var res = backend.createQuote(
                                cSel.id,
                                cSel.tipo_cliente,
                                newQuotePopup.subtotalVal,
                                newQuotePopup.ivaVal,
                                newQuotePopup.totalVal,
                                JSON.stringify(newQuotePopup.cart)
                            )
                            newQuotePopup.close()
                            qRoot.refresh()
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: {
                            newQuotePopup.close()
                        }
                    }
                }
            }
        }
    }

    // POPUPS MODALES DE CONFIRMACIÓN Y CAMBIO DE CANTIDAD PARA PRODUCTOS DUPLICADOS (COLOR UNIFORME TOTAL)
    Popup {
        id: duplicateConfirmDialog
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

        property var dupItem: null
        property int dupIndex: -1

        contentItem: Column {
            anchors.fill: parent
            spacing: 14

            Text {
                text: "Producto Duplicado"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Este objeto ya está en la cotización, ¿Desea cambiar la cantidad?"
                color: theme.textPrimary
                font.bold: true
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    height: 34
                    width: 100
                    contentItem: Text { text: "Sí, Cambiar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorBronze; radius: 6 }
                    onClicked: {
                        duplicateConfirmDialog.close()
                        changeQtyDialog.openForItem(duplicateConfirmDialog.dupItem, duplicateConfirmDialog.dupIndex)
                    }
                }

                Button {
                    height: 34
                    width: 100
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: duplicateConfirmDialog.close()
                }
            }
        }
    }

    Popup {
        id: changeQtyDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 440
        height: 230
        padding: 16

        Overlay.modal: Rectangle { color: "#60000000" }

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorBronze
            border.width: 2
        }

        property var targetItem: null
        property int targetIndex: -1

        function openForItem(item, idx) {
            targetItem = item
            targetIndex = idx
            txtNewQtyVal.text = item.cantidad.toString()
            open()
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 12

            Text {
                text: "Modificar Cantidad"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
            }

            Text {
                text: "Objeto: " + (changeQtyDialog.targetItem ? changeQtyDialog.targetItem.nombre : "")
                font.bold: true
                font.pixelSize: 12
                color: theme.textPrimary
                wrapMode: Text.Wrap
                width: parent.width
            }

            Text {
                text: "Cantidad Actual: " + (changeQtyDialog.targetItem ? changeQtyDialog.targetItem.cantidad : "0")
                font.pixelSize: 11
                color: theme.textMuted
            }

            TextField {
                id: txtNewQtyVal
                width: parent.width
                color: "#FFFFFF"
                font.bold: true
                font.pixelSize: 12
                selectionColor: theme.colorBronze
                selectedTextColor: "#FFFFFF"
                text: "1"
                inputMethodHints: Qt.ImhDigitsOnly
                background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
            }

            Row {
                anchors.right: parent.right
                spacing: 10

                Button {
                    height: 32
                    width: 90
                    contentItem: Text { text: "Guardar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorBronze; radius: 6 }
                    onClicked: {
                        var newQty = parseInt(txtNewQtyVal.text) || 1
                        if (changeQtyDialog.targetIndex >= 0 && changeQtyDialog.targetIndex < newQuotePopup.cart.length) {
                            var item = newQuotePopup.cart[changeQtyDialog.targetIndex]
                            item.cantidad = newQty
                            item.subtotal_linea = newQty * item.precio_venta
                            
                            var temp = []
                            for (var i = 0; i < newQuotePopup.cart.length; i++) {
                                temp.push(newQuotePopup.cart[i])
                            }
                            newQuotePopup.cart = temp
                            newQuotePopup.recalc()
                        }
                        changeQtyDialog.close()
                    }
                }

                Button {
                    height: 32
                    width: 90
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: changeQtyDialog.close()
                }
            }
        }
    }
}
