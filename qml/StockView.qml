import QtQuick
import QtQuick.Controls

ScrollView {
    id: stockRoot
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
        width: stockRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // Header Control de Stock
        Text {
            text: "📈 Control de Inventario, Despachos Físicos y Renovaciones"
            font.pixelSize: 15
            font.bold: true
            color: theme.textPrimary
        }

        // Barra de Búsqueda Estilo Google
        Row {
            spacing: 10
            width: parent.width

            TextField {
                id: txtSearch
                width: parent.width - 180
                height: 40
                placeholderText: "🔍 Buscar en el stock por nombre, código o categoría..."
                color: theme.textPrimary
                onAccepted: stockRoot.loadData(txtSearch.text)
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
                onClicked: stockRoot.loadData(txtSearch.text)
            }

            Button {
                width: 80
                height: 40
                contentItem: Text { text: "Limpiar"; color: "#FFFFFF"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: theme.colorSlate; radius: 8 }
                onClicked: { txtSearch.text = ""; stockRoot.loadData("") }
            }
        }

        // TARJETAS EXCLUSIVAS DE CONTROL DE STOCK E INVENTARIO
        Repeater {
            model: stockRoot.products

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
                            text: modelData.nombre + " (" + modelData.codigo + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Proveedor: " + modelData.proveedor + " | Stock Disponible: " + modelData.stock_actual + " unidades | Mínimo Requerido: " + modelData.stock_minimo + " unidades"
                            font.pixelSize: 11
                            color: theme.textMuted
                        }

                        // ALERTA VISUAL DE RE-STOCK CUANDO STOCK < 5 UNIDADES
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

                        // TIPO DE PROVEEDOR / BADGE DE STOCK
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

                        // MENÚ TRES PUNTOS CON OPERACIONES DE STOCK (DESPACHAR, RENOVAR)
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

                            onClicked: stockMenu.open()

                            Menu {
                                id: stockMenu
                                y: btnDots.height

                                MenuItem {
                                    text: "📦 Despachar Stock"
                                    onTriggered: {
                                        stockRoot.selectedProduct = modelData
                                        dispatchQty.text = "1"
                                        dispatchDialog.open()
                                    }
                                }
                                MenuItem {
                                    text: "🔄 Renovar Stock"
                                    onTriggered: {
                                        stockRoot.selectedProduct = modelData
                                        renewQty.text = "10"
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

    // DIÁLOGO DESPACHAR STOCK (SOBRE OVERLAY)
    Dialog {
        id: dispatchDialog
        parent: Overlay.overlay
        title: "📦 Despachar Unidades de Stock"
        anchors.centerIn: parent
        modal: true
        width: 380

        Column {
            spacing: 10
            width: parent.width

            Text {
                text: stockRoot.selectedProduct ? "Stock disponible actual: " + stockRoot.selectedProduct.stock_actual + " unidades" : ""
                font.bold: true
                color: theme.colorBronze
                font.pixelSize: 12
            }

            Text {
                text: "Ingrese la cantidad de unidades que desea despachar:"
                color: theme.textPrimary
                font.pixelSize: 12
            }

            TextField {
                id: dispatchQty
                width: parent.width
                placeholderText: "Cantidad a despachar"
                text: "1"
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegularExpressionValidator { regularExpression: /^[0-9]+$/ }
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (stockRoot.selectedProduct) {
                var q = parseInt(dispatchQty.text) || 1
                var resStr = backend.dispatchStock(stockRoot.selectedProduct.id, q)
                var res = JSON.parse(resStr)
                if (!res.success) {
                    stockErrTxt.text = res.message
                    stockErrDialog.open()
                }
                stockRoot.loadData(txtSearch.text)
            }
        }
    }

    // DIÁLOGO RENOVAR STOCK (SOBRE OVERLAY)
    Dialog {
        id: renewDialog
        parent: Overlay.overlay
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
                placeholderText: "Cantidad (ej. 20)"
                text: "10"
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegularExpressionValidator { regularExpression: /^[0-9]+$/ }
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (stockRoot.selectedProduct) {
                var q = parseInt(renewQty.text) || 10
                backend.renewStock(stockRoot.selectedProduct.id, q)
                stockRoot.loadData(txtSearch.text)
            }
        }
    }

    // DIÁLOGO MODAL AVISO / ERROR CUANDO SE INTENTA DESPACHAR MÁS DE LO DISPONIBLE (SOBRE OVERLAY)
    Dialog {
        id: stockErrDialog
        parent: Overlay.overlay
        title: "Control de Despacho de Stock"
        anchors.centerIn: parent
        modal: true
        width: 360

        Text {
            id: stockErrTxt
            text: ""
            color: theme.textPrimary
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            width: parent.width
        }

        standardButtons: Dialog.Ok
    }
}
