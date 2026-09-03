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
            text: "📈 Control de Stock Permanente e Inventario"
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
                placeholderTextColor: theme.textMuted
                color: theme.inputColor
                font.bold: true
                font.pixelSize: 12
                selectionColor: theme.colorBronze
                selectedTextColor: "#FFFFFF"
                onAccepted: stockRoot.loadData(txtSearch.text)
                background: Rectangle {
                    color: theme.inputBg
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

    // POPUP DESPACHAR STOCK (COLOR UNIFORME TOTAL)
    Popup {
        id: dispatchDialog
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

        contentItem: Column {
            anchors.fill: parent
            spacing: 12

            Text {
                text: "📦 Despachar Unidades de Stock"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
            }

            Text {
                text: stockRoot.selectedProduct ? "Stock disponible actual: " + stockRoot.selectedProduct.stock_actual + " unidades" : ""
                font.bold: true
                color: theme.colorSuccess
                font.pixelSize: 12
            }

            Text {
                text: "Ingrese la cantidad de unidades que desea despachar:"
                color: theme.textPrimary
                font.bold: true
                font.pixelSize: 11
            }

            TextField {
                id: dispatchQty
                width: parent.width
                height: 38
                placeholderText: "Cantidad a despachar"
                placeholderTextColor: theme.textMuted
                text: "1"
                color: theme.inputColor
                font.bold: true
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                selectionColor: theme.colorBronze
                selectedTextColor: "#FFFFFF"
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegularExpressionValidator { regularExpression: /^[0-9]+$/ }
                background: Rectangle {
                    color: theme.inputBg
                    radius: 6
                    border.color: theme.colorBronze
                    border.width: 1.5
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 10

                Button {
                    height: 32
                    width: 100
                    contentItem: Text { text: "Despachar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorBronze; radius: 6 }
                    onClicked: {
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
                        dispatchDialog.close()
                    }
                }

                Button {
                    height: 32
                    width: 90
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: dispatchDialog.close()
                }
            }
        }
    }

    // POPUP RENOVAR STOCK (COLOR UNIFORME TOTAL)
    Popup {
        id: renewDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 440
        height: 200
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
            spacing: 12

            Text {
                text: "🔄 Renovar y Reordenar Stock"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
            }

            Text {
                text: "Ingrese la cantidad de unidades para renovación / re-stock:"
                color: theme.textPrimary
                font.bold: true
                font.pixelSize: 11
            }

            TextField {
                id: renewQty
                width: parent.width
                height: 38
                placeholderText: "Cantidad (ej. 20)"
                placeholderTextColor: theme.textMuted
                text: "10"
                color: theme.inputColor
                font.bold: true
                font.pixelSize: 13
                selectionColor: theme.colorBronze
                selectedTextColor: "#FFFFFF"
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegularExpressionValidator { regularExpression: /^[0-9]+$/ }
                background: Rectangle {
                    color: theme.inputBg
                    radius: 6
                    border.color: theme.borderColor
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 10

                Button {
                    height: 32
                    width: 90
                    contentItem: Text { text: "Renovar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorBronze; radius: 6 }
                    onClicked: {
                        if (stockRoot.selectedProduct) {
                            var q = parseInt(renewQty.text) || 10
                            backend.renewStock(stockRoot.selectedProduct.id, q)
                            stockRoot.loadData(txtSearch.text)
                        }
                        renewDialog.close()
                    }
                }

                Button {
                    height: 32
                    width: 90
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: renewDialog.close()
                }
            }
        }
    }

    // POPUP MODAL AVISO / ERROR CUANDO SE INTENTA DESPACHAR MÁS DE LO DISPONIBLE (COLOR UNIFORME TOTAL)
    Popup {
        id: stockErrDialog
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
                text: "Control de Despacho de Stock"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                id: stockErrTxt
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
                    onClicked: stockErrDialog.close()
                }
            }
        }
    }
}
