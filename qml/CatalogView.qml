import QtQuick
import QtQuick.Controls

ScrollView {
    id: catRoot
    clip: true

    property var products: []
    property var supplierList: []
    property var categoryList: []
    property var selectedProduct: null

    Component.onCompleted: loadData("")

    function loadData(searchTxt) {
        products = []
        var raw = backend.getInventoryData(searchTxt)
        products = JSON.parse(raw)

        var rawS = backend.getSupplierNames()
        supplierList = JSON.parse(rawS)

        var rawC = backend.getCategories()
        categoryList = JSON.parse(rawC)
    }

    Column {
        width: catRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // Header Catálogo de Productos
        Text {
            text: "Catálogo de Productos e Integración de Proveedores"
            font.pixelSize: 15
            font.bold: true
            color: theme.textPrimary
        }

        // Barra de Búsqueda y Botones Ejecutivos
        Row {
            spacing: 10
            width: parent.width

            TextField {
                id: txtSearch
                width: parent.width - 340
                height: 40
                placeholderText: "Buscar producto por código, nombre o categoría..."
                color: theme.textPrimary
                onAccepted: catRoot.loadData(txtSearch.text)
                background: Rectangle {
                    color: theme.bgCard
                    radius: 8
                    border.color: theme.borderColor
                }
            }

            Button {
                id: btnSearch
                width: 80
                height: 40
                contentItem: Text { text: "Buscar"; color: "#FFFFFF"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: theme.colorBronze; radius: 8 }
                onClicked: catRoot.loadData(txtSearch.text)
            }

            Button {
                id: btnClear
                width: 80
                height: 40
                contentItem: Text { text: "Limpiar"; color: "#FFFFFF"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: theme.colorSlate; radius: 8 }
                onClicked: { txtSearch.text = ""; catRoot.loadData("") }
            }

            // BOTÓN CREAR PRODUCTO
            Button {
                id: btnCreate
                width: 150
                height: 40
                contentItem: Text {
                    text: "Crear Producto"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnCreate.pressed ? theme.colorBronzeHover : theme.colorBronze
                    radius: 8
                    scale: btnCreate.pressed ? 0.98 : (btnCreate.hovered ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }
                onClicked: {
                    catRoot.loadData(txtSearch.text)
                    newProductPopup.x = Math.max(20, (Overlay.overlay.width - newProductPopup.width) / 2)
                    newProductPopup.y = Math.max(20, (Overlay.overlay.height - newProductPopup.height) / 2)
                    newProductPopup.open()
                }
            }
        }

        // TARJETAS DE PRODUCTOS EN EL CATÁLOGO CON DESCRIPCIÓN
        Repeater {
            model: catRoot.products

            Rectangle {
                width: parent.width
                height: 96
                color: theme.bgCard
                radius: 10
                border.color: theme.borderColor

                Row {
                    anchors.fill: parent
                    anchors.margins: 12

                    Column {
                        spacing: 3
                        Text {
                            text: modelData.nombre + " (" + modelData.codigo + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Categoría: " + modelData.categoria + " | Costo Referencial: $" + modelData.costo.toFixed(2) + " USD | Tipo: " + modelData.tipo_stock
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                        Text {
                            text: "Costo Última Cotización: $" + modelData.costo_ultima_cotizacion.toFixed(2) + " USD | Fecha Actualización: " + modelData.fecha_actualizacion
                            font.pixelSize: 10
                            color: theme.textMuted
                            font.bold: true
                        }
                        Text {
                            text: "Descripción: " + modelData.descripcion
                            font.pixelSize: 10
                            color: theme.textMuted
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // MENÚ TRES PUNTOS CON OPERACIONES DE CATÁLOGO (ENLAZAR, ELIMINAR)
                        Button {
                            id: btnDots
                            height: 32
                            width: 32

                            contentItem: Text {
                                text: "⋮"
                                color: theme.textPrimary
                                font.bold: true
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: btnDots.hovered ? theme.bgCardHover : "transparent"
                                radius: 16
                                border.color: theme.borderColor
                            }

                            onClicked: catMenu.open()

                            Menu {
                                id: catMenu
                                y: btnDots.height

                                MenuItem {
                                    text: "Enlazar con otro Proveedor"
                                    onTriggered: {
                                        catRoot.selectedProduct = modelData
                                        linkProviderDialog.open()
                                    }
                                }
                                MenuItem {
                                    text: "Eliminar Producto"
                                    onTriggered: {
                                        catRoot.selectedProduct = modelData
                                        confirmDeleteDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // POPUP FLOTANTE (SIN BOTÓN "X" Y CON SECCIÓN DE DESCRIPCIÓN)
    Popup {
        id: newProductPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose
        width: 480
        height: 640
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

            // BARRA SUPERIOR ARRASTRABLE LIMPIA (SIN DISEÑO DE LA "X")
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
                    text: "📌 Crear Nuevo Producto en Catálogo (Mover con el Mouse)"
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
                            newProductPopup.x = newProductPopup.x + (mouse.x - dragOffset.x)
                            newProductPopup.y = newProductPopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO DE PRODUCTOS CON SECCIÓN DE DESCRIPCIÓN
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

                    Text { text: "Código del Producto:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: npCode; placeholderText: "ej. FER-001"; width: parent.width }

                    Text { text: "Nombre del Producto:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: npName; placeholderText: "ej. Cuchillas Doble Filo Industrial"; width: parent.width }

                    Text { text: "Descripción del Producto:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: npDesc; placeholderText: "ej. Cuchillas industriales de alta resistencia de acero templado"; width: parent.width }

                    Text { text: "Categoría de Producto (Incluye Categorías Registradas):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: npCatCombo
                        width: parent.width
                        model: catRoot.categoryList
                        onActivated: function(index) {
                            if (currentText === "➕ Agregar Nueva Categoría...") {
                                newCategoryDialog.open()
                            }
                        }
                    }

                    Text { text: "Proveedor Asignado:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: npSupplier
                        width: parent.width
                        model: catRoot.supplierList
                    }

                    Text { text: "Tipo de Stock:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox { id: npType; width: parent.width; model: ["Permanente", "Bajo Pedido"] }

                    Text { text: "Stock Mínimo (Únicamente Números):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: npStockMin
                        placeholderText: "ej. 5"
                        width: parent.width
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]+$/ }
                    }

                    Text { text: "Stock Inicial (Únicamente Números):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: npStockInit
                        placeholderText: "ej. 50"
                        width: parent.width
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]+$/ }
                    }

                    Text { text: "Costo Referencial USD (Únicamente Números / Decimales):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: npPrice
                        placeholderText: "ej. 25.50"
                        width: parent.width
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]+(\.[0-9]{1,2})?$/ }
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
                        contentItem: Text { text: "Guardar Producto"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            var stInit = parseInt(npStockInit.text) || 0
                            var stMin = parseInt(npStockMin.text) || 5
                            var pr = parseFloat(npPrice.text) || 0.0
                            var resStr = backend.addProduct(npCode.text, npName.text, npCatCombo.currentText, npDesc.text, npSupplier.currentText, npType.currentText, stInit, stMin, pr)
                            var res = JSON.parse(resStr)
                            if (!res.success) {
                                catErrTxt.text = res.message
                                catErrDialog.open()
                            } else {
                                newProductPopup.close()
                                catRoot.loadData(txtSearch.text)
                            }
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: newProductPopup.close()
                    }
                }

                // MANIJA INFERIOR DERECHA PARA AJUSTAR / REDIMENSIONAR TAMAÑO DE LA VENTANA CON EL MOUSE
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
                                newProductPopup.width = Math.max(380, newProductPopup.width + deltaX)
                                newProductPopup.height = Math.max(480, newProductPopup.height + deltaY)
                            }
                        }
                    }
                }
            }
        }
    }

    // DIÁLOGO SECUNDARIO PARA AGREGAR NUEVA CATEGORÍA (SOBRE OVERLAY)
    Dialog {
        id: newCategoryDialog
        parent: Overlay.overlay
        title: "Agregar Nueva Categoría"
        anchors.centerIn: parent
        modal: true
        width: 360

        Column {
            spacing: 10
            width: parent.width

            Text { text: "Nombre de la Nueva Categoría:"; font.pixelSize: 12; color: theme.textPrimary }
            TextField { id: newCatName; placeholderText: "ej. Insumos Médicos / Químicos"; width: parent.width }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (newCatName.text.trim() !== "") {
                backend.addCategory(newCatName.text)
                catRoot.loadData(txtSearch.text)
            }
        }
    }

    // DIÁLOGO MENSAJE DE ERROR/ALERTA EN CATÁLOGO (SOBRE OVERLAY)
    Dialog {
        id: catErrDialog
        parent: Overlay.overlay
        title: "Creación de Producto"
        anchors.centerIn: parent
        modal: true
        width: 360

        Text {
            id: catErrTxt
            text: ""
            color: theme.textPrimary
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            width: parent.width
        }

        standardButtons: Dialog.Ok
    }

    // DIÁLOGO CONFIRMACIÓN ELIMINAR (SOBRE OVERLAY)
    Dialog {
        id: confirmDeleteDialog
        parent: Overlay.overlay
        title: "Confirmar Eliminación"
        anchors.centerIn: parent
        modal: true
        width: 380

        Text {
            text: catRoot.selectedProduct ? "¿Está seguro que desea eliminar el producto '" + catRoot.selectedProduct.nombre + "' del catálogo?\nEsta acción no se puede deshacer." : ""
            color: theme.textPrimary
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            width: parent.width
        }

        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            if (catRoot.selectedProduct) {
                backend.deleteProduct(catRoot.selectedProduct.id)
                catRoot.loadData(txtSearch.text)
            }
        }
    }

    // DIÁLOGO ENLAZAR PROVEEDOR (SOBRE OVERLAY)
    Dialog {
        id: linkProviderDialog
        parent: Overlay.overlay
        title: "Enlazar Producto con otro Proveedor"
        anchors.centerIn: parent
        modal: true
        width: 380

        Column {
            spacing: 10
            width: parent.width

            Text {
                text: "Seleccione el proveedor al que desea enlazar este producto:"
                color: theme.textPrimary
                font.pixelSize: 12
            }

            ComboBox {
                id: providerCombo
                width: parent.width
                model: catRoot.supplierList
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (catRoot.selectedProduct) {
                backend.linkProductWithProvider(catRoot.selectedProduct.id, providerCombo.currentText)
                catRoot.loadData(txtSearch.text)
            }
        }
    }
}
