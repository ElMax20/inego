import QtQuick
import QtQuick.Controls

ScrollView {
    id: expRoot
    clip: true

    property var expenses: []
    property var filteredExpenses: []
    property var categoryList: ["Todas las Categorías", "Agua y Servicios", "Logística y Envíos", "Gestión Operativa", "Compras Varias", "Mantenimiento"]

    Component.onCompleted: refresh()

    function refresh() {
        var raw = backend.getExpensesData()
        expenses = JSON.parse(raw)
        
        // Extraer categorías únicas de la base de datos
        var cats = ["Todas las Categorías", "Agua y Servicios", "Logística y Envíos", "Gestión Operativa", "Compras Varias", "Mantenimiento"]
        for (var i = 0; i < expenses.length; i++) {
            var r = expenses[i].rubro
            if (r && cats.indexOf(r) === -1) {
                cats.push(r)
            }
        }
        categoryList = cats
        applyFilter()
    }

    function applyFilter() {
        var selectedCat = filterCategoryCombo.currentText
        if (!selectedCat || selectedCat === "Todas las Categorías") {
            filteredExpenses = expenses
        } else {
            var temp = []
            for (var i = 0; i < expenses.length; i++) {
                if (expenses[i].rubro === selectedCat) {
                    temp.push(expenses[i])
                }
            }
            filteredExpenses = temp
        }
    }

    Column {
        width: expRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // Top bar Header con Botón de Registrar Gasto (RF4.1)
        Item {
            width: parent.width
            height: 40

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "🧾 Control de Caja Chica, Agua, Servicios y Logística"
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
                    text: "➕ Registrar Gasto"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newExpensePopup.open()
                }
            }
        }

        // BARRA DE FILTRO POR CATEGORÍA DE GASTO (Estilo Referencia)
        Row {
            spacing: 10
            width: parent.width

            Text {
                text: "Categoría de Gasto:"
                font.pixelSize: 12
                font.bold: true
                color: theme.colorBronze
                anchors.verticalCenter: parent.verticalCenter
            }

            ComboBox {
                id: filterCategoryCombo
                width: 280
                height: 36
                model: expRoot.categoryList
                onActivated: expRoot.applyFilter()
            }
        }

        // LISTA DE GASTOS EN QML FILTRADA POR CATEGORÍA
        Repeater {
            model: expRoot.filteredExpenses

            Rectangle {
                width: parent.width
                height: 64
                color: theme.bgCard
                radius: 10
                border.color: theme.borderColor

                Item {
                    anchors.fill: parent
                    anchors.margins: 14

                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            text: "🧾 [" + modelData.rubro + "] " + modelData.concepto
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Fecha: " + modelData.fecha + " | Egreso de Caja Chica"
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.badgeBgDanger
                        radius: 6
                        width: expAmtTxt.width + 16
                        height: 26

                        Text {
                            id: expAmtTxt
                            anchors.centerIn: parent
                            text: "-$" + modelData.monto.toFixed(2) + " USD"
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.colorDanger
                        }
                    }
                }
            }
        }
    }

    // POPUP REGISTRAR GASTO CAJA CHICA ESTILO CORPORATIVO Y ARRASTRABLE (RF4.1)
    Popup {
        id: newExpensePopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 520
        height: 430
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

            // BARRA SUPERIOR ARRASTRABLE
            Rectangle {
                id: expenseTitleBar
                width: parent.width
                height: 42
                color: theme.colorBronze
                radius: 10

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "📌 Registrar Egreso de Caja Chica (Mover con el Mouse)"
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
                            newExpensePopup.x = newExpensePopup.x + (mouse.x - dragOffset.x)
                            newExpensePopup.y = newExpensePopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO
            ScrollView {
                id: expenseScroll
                anchors.top: expenseTitleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: expenseBottomBar.top
                anchors.margins: 14
                clip: true

                Column {
                    width: expenseScroll.width - 20
                    spacing: 12

                    Text { text: "Fecha de Registro (Automática):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: expDate
                        width: parent.width
                        color: theme.textSecondary
                        readOnly: true
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                        background: Rectangle {
                            color: theme.bgMain
                            radius: 6
                            border.color: theme.borderColor
                        }
                    }

                    Text { text: "Categoría/Rubro del Egreso:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: expRubro
                        width: parent.width
                        textRole: "text"
                        model: ListModel {
                            id: categoryModel
                            ListElement { text: "Agua y Servicios" }
                            ListElement { text: "Logística y Envíos" }
                            ListElement { text: "Gestión Operativa" }
                            ListElement { text: "Compras Varias" }
                            ListElement { text: "Mantenimiento" }
                            ListElement { text: "Otros..." }
                        }
                        onActivated: {
                            if (currentText === "Otros...") {
                                newCategoryDialog.open()
                            }
                        }
                    }

                    Text { text: "Concepto / Descripción del Egreso:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: expConcept
                        placeholderText: "Concepto (ej. Pago planilla de agua o Compra repuestos)"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Monto USD ($):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: expMonto
                        placeholderText: "Monto USD ($)"
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
                id: expenseBottomBar
                width: parent.width
                height: 48
                anchors.bottom: parent.bottom

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Button {
                        width: 140
                        height: 34
                        contentItem: Text { text: "Registrar Gasto"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            var cleanMonto = expMonto.text.replace(",", ".")
                            var val = parseFloat(cleanMonto) || 0.0
                            var rubroText = categoryModel.get(expRubro.currentIndex).text
                            var resStr = backend.addExpense(expConcept.text, rubroText, val)
                            var res = JSON.parse(resStr)
                            
                            if (!res.success) {
                                expErrTxt.text = res.message
                                expErrDialog.open()
                            } else {
                                newExpensePopup.close()
                                expRoot.refresh()
                                expConcept.text = ""
                                expMonto.text = ""
                                expRubro.currentIndex = 0
                            }
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: {
                            newExpensePopup.close()
                        }
                    }
                }
            }
        }
    }

    // POPUP MODAL AGREGAR NUEVA CATEGORÍA DINÁMICAMENTE (COLOR UNIFORME TOTAL)
    Popup {
        id: newCategoryDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 400
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
            spacing: 12

            Text { text: "Nueva Categoría"; font.pixelSize: 14; font.bold: true; color: theme.colorBronze }
            Text { text: "Ingrese el nombre del nuevo rubro/categoría:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
            TextField {
                id: txtNewCategoryName
                width: parent.width
                placeholderText: "ej. Alimentación, Publicidad..."
                placeholderTextColor: theme.textMuted
                color: theme.inputColor
                font.bold: true
                font.pixelSize: 12
                selectionColor: theme.colorBronze
                selectedTextColor: "#FFFFFF"
                background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    height: 32
                    width: 90
                    contentItem: Text { text: "Guardar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorBronze; radius: 6 }
                    onClicked: {
                        if (txtNewCategoryName.text.trim() !== "") {
                            categoryModel.insert(categoryModel.count - 1, {"text": txtNewCategoryName.text.trim()})
                            expRubro.currentIndex = categoryModel.count - 2
                        } else {
                            expRubro.currentIndex = 0
                        }
                        txtNewCategoryName.text = ""
                        newCategoryDialog.close()
                    }
                }

                Button {
                    height: 32
                    width: 90
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: {
                        expRubro.currentIndex = 0
                        txtNewCategoryName.text = ""
                        newCategoryDialog.close()
                    }
                }
            }
        }
    }

    // POPUP MODAL DE ERROR DE REGISTRO (COLOR UNIFORME TOTAL)
    Popup {
        id: expErrDialog
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
                text: "Registro de Gasto"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                id: expErrTxt
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
                    onClicked: expErrDialog.close()
                }
            }
        }
    }
}
