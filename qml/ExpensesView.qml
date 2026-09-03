import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

                    Text { text: "Fecha de Registro:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    Row {
                        width: parent.width
                        spacing: 6

                        TextField {
                            id: expDate
                            width: parent.width - 40
                            color: theme.textPrimary
                            font.bold: true
                            text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                            background: Rectangle {
                                color: theme.bgMain
                                radius: 6
                                border.color: theme.borderColor
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: calendarPopup.openFor(expDate)
                            }
                        }

                        Button {
                            width: 34
                            height: 34
                            contentItem: Text { text: "📅"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorBronze; radius: 6 }
                            onClicked: calendarPopup.openFor(expDate)
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
                        placeholderText: "Monto USD ($) ej. 25.00"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]+(\.[0-9]{1,2})?$/ }
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
                            var conceptText = expConcept.text.trim()
                            if (!conceptText) {
                                expErrTxt.text = "🚫 Error al registrar gasto:\n\nPor favor ingrese la descripción o concepto del gasto."
                                expErrDialog.open()
                                return
                            }

                            var rawMonto = expMonto.text.trim().replace(",", ".")
                            var numRegex = /^[0-9]+(\.[0-9]{1,2})?$/
                            if (!rawMonto || !numRegex.test(rawMonto) || parseFloat(rawMonto) <= 0) {
                                expErrTxt.text = "🚫 Error al registrar gasto:\n\nEl monto ingresado ('" + expMonto.text + "') es inválido.\nDebe ser un valor numérico estrictamente positivo mayor a 0.00 USD (sin letras ni números negativos)."
                                expErrDialog.open()
                                return
                            }

                            var val = parseFloat(rawMonto)
                            var rubroText = categoryModel.get(expRubro.currentIndex).text
                            var resStr = backend.addExpense(conceptText, rubroText, val)
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

    // =========================================================================
    // CALENDARIO MODAL REUTILIZABLE (SELECCIÓN VISUAL INTERACTIVA DE FECHA)
    // =========================================================================
    Popup {
        id: calendarPopup
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 320
        height: 350
        padding: 14

        property var targetTextField: null
        property int currentYear: new Date().getFullYear()
        property int currentMonth: new Date().getMonth()
        property int selectedDay: new Date().getDate()

        Overlay.modal: Rectangle { color: "#60000000" }

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorBronze
            border.width: 2
        }

        function openFor(textField) {
            targetTextField = textField
            if (textField && textField.text) {
                var parts = textField.text.trim().split("-")
                if (parts.length === 3) {
                    var y = parseInt(parts[0])
                    var m = parseInt(parts[1]) - 1
                    var d = parseInt(parts[2])
                    if (!isNaN(y) && !isNaN(m) && !isNaN(d)) {
                        currentYear = y
                        currentMonth = m
                        selectedDay = d
                    }
                }
            }

            // Límite estricto de fecha mínima: 1 de Agosto de 2026 (2026-08-01)
            if (currentYear < 2026 || (currentYear === 2026 && currentMonth < 7)) {
                currentYear = 2026
                currentMonth = 7
                selectedDay = 1
            } else if (currentYear === 2026 && currentMonth === 7 && selectedDay < 1) {
                selectedDay = 1
            }
            calendarPopup.open()
        }

        readonly property var monthNames: [
            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
        ]

        function daysInMonth(m, y) {
            return new Date(y, m + 1, 0).getDate()
        }

        function startDayOfWeek(m, y) {
            return new Date(y, m, 1).getDay()
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 8

            Row {
                width: parent.width
                height: 32
                spacing: 6

                Button {
                    width: 32
                    height: 32
                    enabled: calendarPopup.currentYear > 2026 || (calendarPopup.currentYear === 2026 && calendarPopup.currentMonth > 7)
                    opacity: enabled ? 1.0 : 0.4
                    contentItem: Text { text: "◀"; color: theme.textPrimary; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
                    onClicked: {
                        if (calendarPopup.currentYear > 2026 || (calendarPopup.currentYear === 2026 && calendarPopup.currentMonth > 7)) {
                            if (calendarPopup.currentMonth === 0) {
                                calendarPopup.currentMonth = 11
                                calendarPopup.currentYear--
                            } else {
                                calendarPopup.currentMonth--
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true; width: 1; height: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: calendarPopup.monthNames[calendarPopup.currentMonth] + " " + calendarPopup.currentYear
                    font.pixelSize: 13
                    font.bold: true
                    color: theme.colorBronze
                }

                Item { Layout.fillWidth: true; width: 1; height: 1 }

                Button {
                    width: 32
                    height: 32
                    contentItem: Text { text: "▶"; color: theme.textPrimary; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
                    onClicked: {
                        if (calendarPopup.currentMonth === 11) {
                            calendarPopup.currentMonth = 0
                            calendarPopup.currentYear++
                        } else {
                            calendarPopup.currentMonth++
                        }
                    }
                }
            }

            // Nota informativa de fecha mínima permitida
            Text {
                text: "🔒 Fecha mín. permitida: 01 de Agosto de 2026"
                font.pixelSize: 9
                font.bold: true
                color: theme.textMuted
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                width: parent.width
                height: 22

                Repeater {
                    model: ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
                    delegate: Item {
                        width: (calendarPopup.width - 28) / 7
                        height: 22
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textMuted
                        }
                    }
                }
            }

            Grid {
                columns: 7
                spacing: 2
                width: parent.width

                Repeater {
                    model: 42
                    delegate: Item {
                        width: (calendarPopup.width - 28 - 12) / 7
                        height: 28

                        property int offset: calendarPopup.startDayOfWeek(calendarPopup.currentMonth, calendarPopup.currentYear)
                        property int dayNum: index - offset + 1
                        property bool isValidDay: dayNum >= 1 && dayNum <= calendarPopup.daysInMonth(calendarPopup.currentMonth, calendarPopup.currentYear)
                        property bool isAllowedDate: isValidDay && !(calendarPopup.currentYear < 2026 || (calendarPopup.currentYear === 2026 && calendarPopup.currentMonth < 7) || (calendarPopup.currentYear === 2026 && calendarPopup.currentMonth === 7 && dayNum < 1))
                        property bool isSelected: isValidDay && isAllowedDate && dayNum === calendarPopup.selectedDay

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            visible: parent.isValidDay
                            opacity: parent.parent.isAllowedDate ? 1.0 : 0.35
                            color: parent.isSelected ? theme.colorBronze : (dayMouse.containsMouse && parent.parent.isAllowedDate ? theme.bgMain : "transparent")
                            border.color: parent.isSelected ? theme.colorBronze : (dayMouse.containsMouse && parent.parent.isAllowedDate ? theme.borderColor : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.isValidDay ? parent.parent.dayNum : ""
                                font.pixelSize: 11
                                font.bold: parent.parent.isSelected
                                color: parent.parent.isSelected ? "#FFFFFF" : (parent.parent.isAllowedDate ? theme.textPrimary : theme.textMuted)
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                enabled: parent.parent.isAllowedDate
                                hoverEnabled: parent.parent.isAllowedDate
                                cursorShape: parent.parent.isAllowedDate ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                onClicked: {
                                    if (parent.parent.isAllowedDate) {
                                        calendarPopup.selectedDay = parent.parent.dayNum
                                        var m = calendarPopup.currentMonth + 1
                                        var mm = m < 10 ? "0" + m : "" + m
                                        var dd = parent.parent.dayNum < 10 ? "0" + parent.parent.dayNum : "" + parent.parent.dayNum
                                        var formattedDate = calendarPopup.currentYear + "-" + mm + "-" + dd

                                        if (calendarPopup.targetTextField) {
                                            calendarPopup.targetTextField.text = formattedDate
                                        }
                                        calendarPopup.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true; width: 1; height: 1 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    width: 100
                    height: 28
                    contentItem: Text { text: "📅 Ir a Hoy"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: {
                        var now = new Date()
                        var y = now.getFullYear()
                        var m = now.getMonth()
                        var d = now.getDate()

                        if (y < 2026 || (y === 2026 && m < 7)) {
                            y = 2026
                            m = 7
                            d = 1
                        }

                        calendarPopup.currentYear = y
                        calendarPopup.currentMonth = m
                        calendarPopup.selectedDay = d

                        var mPlus = m + 1
                        var mm = mPlus < 10 ? "0" + mPlus : "" + mPlus
                        var dd = d < 10 ? "0" + d : "" + d
                        var formattedDate = y + "-" + mm + "-" + dd

                        if (calendarPopup.targetTextField) {
                            calendarPopup.targetTextField.text = formattedDate
                        }
                        calendarPopup.close()
                    }
                }

                Button {
                    width: 80
                    height: 28
                    contentItem: Text { text: "Cancelar"; color: theme.textMuted; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
                    onClicked: calendarPopup.close()
                }
            }
        }
    }
}
