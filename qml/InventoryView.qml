import QtQuick
import QtQuick.Controls

ScrollView {
    id: invRoot
    clip: true

    property var products: []
    property var selectedProduct: null

    Component.onCompleted: loadData("")

    function loadData(searchTxt) {
        products = []
        var raw = backend.getInventoryData(searchTxt)
        products = JSON.parse(raw)
    }

    Column {
        width: invRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // Header Catálogo y Botón Agregar Producto Nuevo
        Item {
            width: parent.width
            height: 40

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "📦 Catálogo de Productos y Control de Stock Ejemplar"
                font.pixelSize: 15
                font.bold: true
                color: theme.textPrimary
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                width: 190
                radius: 8
                color: theme.colorBronze

                Text {
                    anchors.centerIn: parent
                    text: "➕ Agregar Nuevo Producto"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newProductDialog.open()
                }
            }
        }

        // Barra de Búsqueda Estilo Google en QML
        Row {
            spacing: 10
            width: parent.width

            TextField {
                id: txtSearch
                width: parent.width - 180
                height: 40
                placeholderText: "🔍 Escriba una frase de búsqueda y presione ENTER (Estilo Google)..."
                color: theme.textPrimary
                onAccepted: invRoot.loadData(txtSearch.text)
                background: Rectangle {
                    color: theme.bgCard
                    radius: 8
                    border.color: theme.borderColor
                }
            }

            Button {
                width: 80
                height: 40
                contentItem: Text { text: "Buscar"; color: "#FFFFFF"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: theme.colorBronze; radius: 8 }
                onClicked: invRoot.loadData(txtSearch.text)
            }

            Button {
                width: 80
                height: 40
                contentItem: Text { text: "Limpiar"; color: "#FFFFFF"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: theme.colorSlate; radius: 8 }
                onClicked: { txtSearch.text = ""; invRoot.loadData("") }
            }
        }

        // LISTADO DE TARJETAS DE PRODUCTOS QML CON RE-RENDER EN TIEMPO REAL
        Repeater {
            model: invRoot.products

            Rectangle {
                width: parent.width
                height: (modelData.stock_actual < 5) ? 96 : 74
                color: theme.bgCard
                radius: 10
                border.color: (modelData.stock_actual < 5) ? theme.colorDanger : theme.borderColor
                border.width: (modelData.stock_actual < 5) ? 2 : 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 14

                    Column {
                        spacing: 4
                        Text {
                            text: modelData.nombre + " [Proveedor: " + modelData.proveedor + "] (" + modelData.codigo + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Categoría: " + modelData.categoria + " | Costo Cotizado: $" + modelData.costo.toFixed(2) + " USD | Stock Actual: " + modelData.stock_actual + " unidades"
                            font.pixelSize: 11
                            color: theme.textMuted
                        }

                        // ALERTA VISUAL CUANDO STOCK < 5 UNIDADES
                        Rectangle {
                            visible: modelData.stock_actual < 5
                            color: theme.badgeBgDanger
                            radius: 6
                            height: 22
                            width: alertTxt.width + 16

                            Text {
                                id: alertTxt
                                anchors.centerIn: parent
                                text: "⚠️ ALERTA: Stock Bajo (" + modelData.stock_actual + " unidades) - Requiere Renovación urgente"
                                font.pixelSize: 10
                                font.bold: true
                                color: theme.colorDanger
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // BADGE BAJO PEDIDO / PERMANENTE EN TONO TWINKLE BRONZE (#B88865)
                        Rectangle {
                            color: modelData.tipo_stock === "Permanente" ? theme.badgeBgSuccess : theme.colorBronze
                            radius: 6
                            width: badgeTxt.width + 16
                            height: 28

                            Text {
                                id: badgeTxt
                                anchors.centerIn: parent
                                text: modelData.tipo_stock
                                font.pixelSize: 11
                                font.bold: true
                                color: modelData.tipo_stock === "Permanente" ? theme.colorSuccess : "#FFFFFF"
                            }
                        }

                        // MENÚ DE TRES PUNTOS (⋮)
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

                            onClicked: actionMenu.open()

                            Menu {
                                id: actionMenu
                                y: btnDots.height

                                MenuItem {
                                    text: "🗑️ Eliminar"
                                    onTriggered: {
                                        invRoot.selectedProduct = modelData
                                        confirmDeleteDialog.open()
                                    }
                                }
                                MenuItem {
                                    text: "🔗 Enlazar Proveedor"
                                    onTriggered: {
                                        invRoot.selectedProduct = modelData
                                        linkProviderDialog.open()
                                    }
                                }
                                MenuItem {
                                    text: "📦 Despachar Stock"
                                    onTriggered: {
                                        invRoot.selectedProduct = modelData
                                        dispatchDialog.open()
                                    }
                                }
                                MenuItem {
                                    text: "🔄 Renovar Stock"
                                    onTriggered: {
                                        invRoot.selectedProduct = modelData
                                        renewDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // DIÁLOGO AGREGAR NUEVO PRODUCTO
    Dialog {
        id: newProductDialog
        title: "➕ Agregar Nuevo Producto al Catálogo"
        anchors.centerIn: parent
        modal: true
        width: 400

        Column {
            spacing: 10
            width: parent.width

            TextField { id: npCode; placeholderText: "Código (ej. FER-009)"; width: parent.width }
            TextField { id: npName; placeholderText: "Nombre de producto"; width: parent.width }
            TextField { id: npCat; placeholderText: "Categoría (ej. Ferretería General)"; width: parent.width }
            ComboBox { id: npType; width: parent.width; model: ["Permanente", "Bajo Pedido"] }
            TextField { id: npStock; placeholderText: "Stock Inicial (ej. 50)"; inputMethodHints: Qt.ImhDigitsOnly; width: parent.width }
            TextField { id: npPrice; placeholderText: "Costo Referencial USD (ej. 25.50)"; width: parent.width }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            var st = parseInt(npStock.text) || 0
            var pr = parseFloat(npPrice.text) || 0.0
            backend.addProduct(npCode.text, npName.text, npCat.text, npType.currentText, st, pr)
            invRoot.loadData(txtSearch.text)
        }
    }

    // DIÁLOGO CONFIRMACIÓN ELIMINAR (ACEPTAR / RECHAZAR)
    Dialog {
        id: confirmDeleteDialog
        title: "⚠️ Confirmar Eliminación"
        anchors.centerIn: parent
        modal: true
        width: 380

        Text {
            text: invRoot.selectedProduct ? "¿Está seguro que desea eliminar el producto '" + invRoot.selectedProduct.nombre + "' del sistema?\nEsta acción no se puede deshacer." : ""
            color: theme.textPrimary
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            width: parent.width
        }

        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            if (invRoot.selectedProduct) {
                backend.deleteProduct(invRoot.selectedProduct.id)
                invRoot.loadData(txtSearch.text)
            }
        }
    }

    // DIÁLOGO ENLAZAR PROVEEDOR
    Dialog {
        id: linkProviderDialog
        title: "🔗 Enlazar Producto a Proveedor"
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
                model: ["Sweet & Coffee S.A.", "Importadora Central GYE", "Amazon Business Corp USA", "Grainger Supplies Inc.", "Tiendamia Logistics Ecuador"]
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (invRoot.selectedProduct) {
                backend.linkProductWithProvider(invRoot.selectedProduct.id, providerCombo.currentText)
                invRoot.loadData(txtSearch.text)
            }
        }
    }

    // DIÁLOGO DESPACHAR STOCK
    Dialog {
        id: dispatchDialog
        title: "📦 Despachar Unidades de Stock"
        anchors.centerIn: parent
        modal: true
        width: 360

        Column {
            spacing: 10
            width: parent.width

            Text {
                text: "Ingrese la cantidad de unidades que desea despachar:"
                color: theme.textPrimary
                font.pixelSize: 12
            }

            TextField {
                id: dispatchQty
                width: parent.width
                placeholderText: "Cantidad a despachar (ej. 5)"
                text: "5"
                inputMethodHints: Qt.ImhDigitsOnly
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (invRoot.selectedProduct) {
                var q = parseInt(dispatchQty.text) || 5
                backend.dispatchStock(invRoot.selectedProduct.id, q)
                invRoot.loadData(txtSearch.text)
            }
        }
    }

    // DIÁLOGO RENOVAR STOCK
    Dialog {
        id: renewDialog
        title: "🔄 Renovar y Reordenar Stock"
        anchors.centerIn: parent
        modal: true
        width: 360

        Column {
            spacing: 10
            width: parent.width

            Text {
                text: "Ingrese la cantidad de unidades para renovación / re-stock:"
                color: theme.textPrimary
                font.pixelSize: 12
            }

            TextField {
                id: renewQty
                width: parent.width
                placeholderText: "Cantidad a renovar (ej. 20)"
                text: "20"
                inputMethodHints: Qt.ImhDigitsOnly
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (invRoot.selectedProduct) {
                var q = parseInt(renewQty.text) || 20
                backend.renewStock(invRoot.selectedProduct.id, q)
                invRoot.loadData(txtSearch.text)
            }
        }
    }
}
