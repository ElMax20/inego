import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ScrollView {
    id: repRoot
    clip: true

    // -------------------------------------------------------------------------
    // ESTADO Y UTILIDADES JAVASCRIPT
    // -------------------------------------------------------------------------
    property string currentReportType: "" // "daily", "monthly", "range", "caja"
    property string pendingFileName: ""

    // Función para obtener la fecha de hoy en formato YYYY-MM-DD
    function getTodayString() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd")
    }

    // Función para obtener el primer día del mes actual (YYYY-MM-01)
    function getFirstDayOfMonthString() {
        var now = new Date()
        var y = now.getFullYear()
        var m = now.getMonth() + 1
        var mm = m < 10 ? "0" + m : "" + m
        return y + "-" + mm + "-01"
    }

    // Limpieza robusta del prefijo file:/// y caracteres codificados (%20)
    function cleanFilePath(fileUrl) {
        if (!fileUrl) return ""
        var s = fileUrl.toString()
        if (s.indexOf("file:///") === 0) {
            s = s.substring(8)
        } else if (s.indexOf("file://") === 0) {
            s = s.substring(7)
        }
        return decodeURIComponent(s)
    }

    // Iniciar diálogo de guardado con nombre de archivo sugerido
    function triggerSaveDialog(reportType, defaultName) {
        currentReportType = reportType
        pendingFileName = defaultName
        saveExcelDialog.currentFile = defaultName
        saveExcelDialog.open()
    }

    // -------------------------------------------------------------------------
    // CONEXIÓN CON EL CONTROLADOR PYTHON (SEÑALES exportSuccess Y exportError)
    // -------------------------------------------------------------------------
    Connections {
        target: reportesController

        function onExportSuccess(message, filePath) {
            feedbackPopup.isError = false
            feedbackPopup.titleText = "Exportación Exitosa"
            feedbackPopup.messageText = message
            feedbackPopup.savedPath = filePath
            feedbackPopup.open()
        }

        function onExportError(message) {
            feedbackPopup.isError = true
            feedbackPopup.titleText = "Aviso de Validación / Error"
            feedbackPopup.messageText = message
            feedbackPopup.savedPath = ""
            feedbackPopup.open()
        }
    }

    // -------------------------------------------------------------------------
    // DIÁLOGO NATIVO DE GUARDADO DE ARCHIVO EXCEL (.XLSX)
    // -------------------------------------------------------------------------
    FileDialog {
        id: saveExcelDialog
        title: "Guardar Reporte en Excel (.xlsx)"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Archivos de Excel (*.xlsx)", "Todos los archivos (*.*)"]

        onAccepted: {
            var raw = selectedFile.toString()
            var rutaLimpia = cleanFilePath(raw)

            if (currentReportType === "daily") {
                reportesController.exportarReporteDiario(txtDailyDate.text, rutaLimpia)
            } else if (currentReportType === "monthly") {
                var mesNum = comboMonth.currentIndex + 1
                var anioNum = spinYear.value
                reportesController.exportarReporteMensual(mesNum, anioNum, rutaLimpia)
            } else if (currentReportType === "range") {
                reportesController.exportarReporteRango(txtRangeStart.text, txtRangeEnd.text, rutaLimpia)
            } else if (currentReportType === "caja") {
                reportesController.exportarReporteCajaChica(txtCajaStart.text, txtCajaEnd.text, rutaLimpia)
            } else if (currentReportType === "gantt") {
                var resStr = backend.downloadReport("gantt", rutaLimpia)
                var res = JSON.parse(resStr)
                feedbackPopup.isError = false
                feedbackPopup.titleText = "Diagrama de Gantt Exportado"
                feedbackPopup.messageText = "El Diagrama de Gantt de Contratos Gobierno se exportó con éxito."
                feedbackPopup.savedPath = res.full_path || rutaLimpia
                feedbackPopup.open()
            }
        }
    }

    // -------------------------------------------------------------------------
    // CONTENEDOR PRINCIPAL DE LA VISTA
    // -------------------------------------------------------------------------
    Column {
        width: repRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 18

        Item { height: 6; width: 1 }

        // Encabezado Superior del Módulo
        Item {
            width: parent.width
            height: 48

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Row {
                    spacing: 10
                    Text {
                        text: "📈 MÓDULO DE REPORTES Y GANTT"
                        font.pixelSize: 16
                        font.bold: true
                        color: theme.textPrimary
                    }
                    Rectangle {
                        color: theme.badgeBgBronze
                        radius: 6
                        width: 90
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "Excel .xlsx"
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.colorBronze
                        }
                    }
                }
                Text {
                    text: "Generación de hojas de cálculo analíticas con formato profesional, selección visual por calendario y cronograma Gantt."
                    font.pixelSize: 11
                    color: theme.textMuted
                }
            }
        }

        // =====================================================================
        // TARJETA 1: REPORTE DIARIO DE VENTAS
        // =====================================================================
        Rectangle {
            width: parent.width
            height: 140
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    spacing: 8
                    Text { text: "📅 Reporte Diario de Ventas"; font.pixelSize: 13; font.bold: true; color: theme.textPrimary }
                    Rectangle { color: "#1E293B"; radius: 4; width: 70; height: 18; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "Día a Día"; font.pixelSize: 9; font.bold: true; color: "#38BDF8" }
                    }
                }

                Text {
                    text: "Exporta el desglose completo de transacciones del día seleccionado: ID transacción, hora, cliente, método de pago, ítems y totales."
                    font.pixelSize: 11
                    color: theme.textMuted
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    spacing: 14

                    Text {
                        text: "Fecha Operativa:"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textSecondary
                        anchors.verticalCenter: rowDailyDate.verticalCenter
                    }

                    Row {
                        id: rowDailyDate
                        spacing: 4

                        TextField {
                            id: txtDailyDate
                            width: 120
                            height: 34
                            text: getTodayString()
                            color: theme.textPrimary
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            background: Rectangle {
                                color: theme.bgMain
                                radius: 6
                                border.color: theme.borderColor
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: calendarPopup.openFor(txtDailyDate)
                            }
                        }

                        Button {
                            width: 34
                            height: 34
                            contentItem: Text { text: "📅"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorBronze; radius: 6 }
                            onClicked: calendarPopup.openFor(txtDailyDate)
                        }
                    }

                    Button {
                        height: 34
                        width: 220
                        contentItem: Text {
                            text: "📥 Exportar Reporte Diario (.xlsx)"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: theme.colorBronze
                            radius: 8
                        }
                        onClicked: {
                            if (!txtDailyDate.text.trim()) {
                                feedbackPopup.isError = true
                                feedbackPopup.titleText = "Validación de Fecha"
                                feedbackPopup.messageText = "Por favor ingrese una fecha válida en formato YYYY-MM-DD."
                                feedbackPopup.open()
                                return
                            }
                            var fName = "Reporte_Ventas_Diario_" + txtDailyDate.text.replace(/-/g, "") + ".xlsx"
                            triggerSaveDialog("daily", fName)
                        }
                    }
                }
            }
        }

        // =====================================================================
        // TARJETA 2: REPORTE MENSUAL CONSOLIDADO
        // =====================================================================
        Rectangle {
            width: parent.width
            height: 140
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    spacing: 8
                    Text { text: "📊 Reporte Mensual Consolidado"; font.pixelSize: 13; font.bold: true; color: theme.textPrimary }
                    Rectangle { color: "#1E293B"; radius: 4; width: 85; height: 18; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "Consolidado"; font.pixelSize: 9; font.bold: true; color: "#34D399" }
                    }
                }

                Text {
                    text: "Calcula el total acumulado de ventas del mes, consolidando KPIs de ingresos, impuestos (IVA 15%), desglose cronológico por días y hoja detallada."
                    font.pixelSize: 11
                    color: theme.textMuted
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    spacing: 14

                    Text {
                        text: "Mes / Año:"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textSecondary
                        anchors.verticalCenter: comboMonth.verticalCenter
                    }

                    ComboBox {
                        id: comboMonth
                        width: 140
                        height: 34
                        model: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
                        currentIndex: new Date().getMonth()
                    }

                    // SELECTOR DE AÑO INTERACTIVO CON BOTONES ▲ (+1) Y ▼ (-1)
                    Item {
                        id: spinYear
                        width: 110
                        height: 34
                        property int value: new Date().getFullYear()

                        Row {
                            anchors.fill: parent
                            spacing: 4

                            TextField {
                                id: txtYearDisplay
                                width: 74
                                height: 34
                                text: spinYear.value.toString()
                                color: theme.textPrimary
                                font.bold: true
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                selectionColor: theme.colorBronze
                                selectedTextColor: "#FFFFFF"
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 2020; top: 2040 }

                                background: Rectangle {
                                    color: theme.bgMain
                                    radius: 6
                                    border.color: theme.borderColor
                                    border.width: 1
                                }

                                onTextEdited: {
                                    var clean = text.replace(/\./g, "").replace(/,/g, "").replace(/-/g, "").trim()
                                    if (clean !== text) {
                                        text = clean
                                    }
                                    var v = parseInt(clean)
                                    if (!isNaN(v) && v >= 2020 && v <= 2040) {
                                        spinYear.value = v
                                    }
                                }

                                onEditingFinished: {
                                    var v = parseInt(text.replace(/\./g, "").replace(/,/g, "").replace(/-/g, "").trim())
                                    if (isNaN(v) || v < 2020) v = 2020
                                    if (v > 2040) v = 2040
                                    spinYear.value = v
                                    text = v.toString()
                                }
                            }

                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 28
                                    height: 15
                                    color: btnUpMouse.containsMouse ? theme.colorBronze : theme.bgCard
                                    radius: 4
                                    border.color: theme.borderColor
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "▲"
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: btnUpMouse.containsMouse ? "#FFFFFF" : theme.textPrimary
                                    }

                                    MouseArea {
                                        id: btnUpMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (spinYear.value < 2040) {
                                                spinYear.value += 1
                                                txtYearDisplay.text = spinYear.value.toString()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 15
                                    color: btnDownMouse.containsMouse ? theme.colorBronze : theme.bgCard
                                    radius: 4
                                    border.color: theme.borderColor
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "▼"
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: btnDownMouse.containsMouse ? "#FFFFFF" : theme.textPrimary
                                    }

                                    MouseArea {
                                        id: btnDownMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (spinYear.value > 2020) {
                                                spinYear.value -= 1
                                                txtYearDisplay.text = spinYear.value.toString()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        height: 34
                        width: 230
                        contentItem: Text {
                            text: "📥 Exportar Mensual Consolidado"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: theme.colorSlate
                            radius: 8
                        }
                        onClicked: {
                            var mNum = comboMonth.currentIndex + 1
                            var mStr = mNum < 10 ? "0" + mNum : "" + mNum
                            var fName = "Reporte_Mensual_Consolidado_" + spinYear.value + "_" + mStr + ".xlsx"
                            triggerSaveDialog("monthly", fName)
                        }
                    }
                }
            }
        }

        // =====================================================================
        // TARJETA 3: REPORTE POR RANGO DE FECHAS PERSONALIZADO
        // =====================================================================
        Rectangle {
            width: parent.width
            height: 140
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    spacing: 8
                    Text { text: "🗓️ Reporte por Rango de Fechas Personalizado"; font.pixelSize: 13; font.bold: true; color: theme.textPrimary }
                    Rectangle { color: "#1E293B"; radius: 4; width: 75; height: 18; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "Intervalo"; font.pixelSize: 9; font.bold: true; color: "#FBBF24" }
                    }
                }

                Text {
                    text: "Permite auditar el movimiento comercial entre dos fechas arbitrarias. Valida automáticamente que la fecha inicial no supere a la final."
                    font.pixelSize: 11
                    color: theme.textMuted
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    spacing: 10

                    Text {
                        text: "Desde:"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textSecondary
                        anchors.verticalCenter: rowRangeStart.verticalCenter
                    }

                    Row {
                        id: rowRangeStart
                        spacing: 4

                        TextField {
                            id: txtRangeStart
                            width: 110
                            height: 34
                            text: getFirstDayOfMonthString()
                            color: theme.textPrimary
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: calendarPopup.openFor(txtRangeStart)
                            }
                        }

                        Button {
                            width: 34
                            height: 34
                            contentItem: Text { text: "📅"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorBronze; radius: 6 }
                            onClicked: calendarPopup.openFor(txtRangeStart)
                        }
                    }

                    Text {
                        text: "Hasta:"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textSecondary
                        anchors.verticalCenter: rowRangeEnd.verticalCenter
                    }

                    Row {
                        id: rowRangeEnd
                        spacing: 4

                        TextField {
                            id: txtRangeEnd
                            width: 110
                            height: 34
                            text: getTodayString()
                            color: theme.textPrimary
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: calendarPopup.openFor(txtRangeEnd)
                            }
                        }

                        Button {
                            width: 34
                            height: 34
                            contentItem: Text { text: "📅"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorBronze; radius: 6 }
                            onClicked: calendarPopup.openFor(txtRangeEnd)
                        }
                    }

                    Button {
                        height: 34
                        width: 210
                        contentItem: Text {
                            text: "📥 Exportar Reporte por Rango"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: theme.colorBronze
                            radius: 8
                        }
                        onClicked: {
                            var fIni = txtRangeStart.text.trim()
                            var fFin = txtRangeEnd.text.trim()
                            if (!fIni || !fFin) {
                                feedbackPopup.isError = true
                                feedbackPopup.titleText = "Fechas Incompletas"
                                feedbackPopup.messageText = "Por favor ingrese tanto la fecha inicial como la fecha final."
                                feedbackPopup.open()
                                return
                            }
                            if (fIni > fFin) {
                                feedbackPopup.isError = true
                                feedbackPopup.titleText = "Rango Inválido"
                                feedbackPopup.messageText = "La fecha inicial no puede ser posterior a la fecha final."
                                feedbackPopup.open()
                                return
                            }
                            var fName = "Reporte_Ventas_Rango_" + fIni.replace(/-/g, "") + "_a_" + fFin.replace(/-/g, "") + ".xlsx"
                            triggerSaveDialog("range", fName)
                        }
                    }
                }
            }
        }

        // =====================================================================
        // TARJETA 4: REPORTE DE SALIDAS DE CAJA CHICA (CATEGORÍAS)
        // =====================================================================
        Rectangle {
            width: parent.width
            height: 140
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    spacing: 8
                    Text { text: "🧾 Reporte de Salidas de Caja Chica"; font.pixelSize: 13; font.bold: true; color: theme.textPrimary }
                    Rectangle { color: "#1E293B"; radius: 4; width: 85; height: 18; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "Caja Chica"; font.pixelSize: 9; font.bold: true; color: "#F43F5E" }
                    }
                }

                Text {
                    text: "Exporta la bitácora financiera de caja chica, estructurando una tabla ejecutiva agrupada y subtotalizada por categoría de gasto junto al detalle de comprobantes."
                    font.pixelSize: 11
                    color: theme.textMuted
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    spacing: 10

                    Text {
                        text: "Desde:"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textSecondary
                        anchors.verticalCenter: rowCajaStart.verticalCenter
                    }

                    Row {
                        id: rowCajaStart
                        spacing: 4

                        TextField {
                            id: txtCajaStart
                            width: 110
                            height: 34
                            text: getFirstDayOfMonthString()
                            color: theme.textPrimary
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: calendarPopup.openFor(txtCajaStart)
                            }
                        }

                        Button {
                            width: 34
                            height: 34
                            contentItem: Text { text: "📅"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorBronze; radius: 6 }
                            onClicked: calendarPopup.openFor(txtCajaStart)
                        }
                    }

                    Text {
                        text: "Hasta:"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textSecondary
                        anchors.verticalCenter: rowCajaEnd.verticalCenter
                    }

                    Row {
                        id: rowCajaEnd
                        spacing: 4

                        TextField {
                            id: txtCajaEnd
                            width: 110
                            height: 34
                            text: getTodayString()
                            color: theme.textPrimary
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            background: Rectangle { color: theme.bgMain; radius: 6; border.color: theme.borderColor }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: calendarPopup.openFor(txtCajaEnd)
                            }
                        }

                        Button {
                            width: 34
                            height: 34
                            contentItem: Text { text: "📅"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: theme.colorBronze; radius: 6 }
                            onClicked: calendarPopup.openFor(txtCajaEnd)
                        }
                    }

                    Button {
                        height: 34
                        width: 210
                        contentItem: Text {
                            text: "📥 Exportar Salidas Caja Chica"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: theme.colorSlate
                            radius: 8
                        }
                        onClicked: {
                            var fIni = txtCajaStart.text.trim()
                            var fFin = txtCajaEnd.text.trim()
                            if (!fIni || !fFin) {
                                feedbackPopup.isError = true
                                feedbackPopup.titleText = "Fechas Incompletas"
                                feedbackPopup.messageText = "Por favor ingrese el rango de fechas para caja chica."
                                feedbackPopup.open()
                                return
                            }
                            if (fIni > fFin) {
                                feedbackPopup.isError = true
                                feedbackPopup.titleText = "Rango Inválido"
                                feedbackPopup.messageText = "La fecha inicial no puede ser posterior a la fecha final."
                                feedbackPopup.open()
                                return
                            }
                            var fName = "Reporte_Salidas_CajaChica_" + fIni.replace(/-/g, "") + "_a_" + fFin.replace(/-/g, "") + ".xlsx"
                            triggerSaveDialog("caja", fName)
                        }
                    }
                }
            }
        }

        // =====================================================================
        // TARJETA 5 ADICIONAL: DIAGRAMA DE GANTT GOBIERNO
        // =====================================================================
        Rectangle {
            width: parent.width
            height: 90
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    width: parent.width - 240

                    Text { text: "📊 Diagrama de Gantt Excel (Contratos Gobierno)"; font.pixelSize: 13; font.bold: true; color: theme.textPrimary }
                    Text { text: "Cronograma de avance de licitaciones públicas y compras gubernamentales."; font.pixelSize: 11; color: theme.textMuted }
                }

                Button {
                    height: 34
                    width: 210
                    anchors.verticalCenter: parent.verticalCenter
                    contentItem: Text {
                        text: "Descargar Gantt (.xlsx)"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: theme.colorBronze
                        radius: 8
                    }
                    onClicked: {
                        var defaultName = "Diagrama_Gantt_Contratos_Gobierno_" + getTodayString().replace(/-/g, "") + ".xlsx"
                        triggerSaveDialog("gantt", defaultName)
                    }
                }
            }
        }

        Item { height: 16; width: 1 }
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
        property int currentMonth: new Date().getMonth() // 0-indexed (0=Enero)
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

            // Encabezado de mes/año con navegación limpia centrada (sin bloques visuales bruscos)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 32
                spacing: 14

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: prevMouse.containsMouse ? theme.bgMain : "transparent"
                    opacity: prevMouse.enabled ? 1.0 : 0.3

                    Text {
                        anchors.centerIn: parent
                        text: "◀"
                        font.pixelSize: 11
                        color: theme.textPrimary
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: calendarPopup.currentYear > 2026 || (calendarPopup.currentYear === 2026 && calendarPopup.currentMonth > 7)
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: {
                            if (enabled) {
                                if (calendarPopup.currentMonth === 0) {
                                    calendarPopup.currentMonth = 11
                                    calendarPopup.currentYear--
                                } else {
                                    calendarPopup.currentMonth--
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: calendarPopup.monthNames[calendarPopup.currentMonth] + " " + calendarPopup.currentYear
                    font.pixelSize: 14
                    font.bold: true
                    color: theme.colorBronze
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: nextMouse.containsMouse ? theme.bgMain : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        font.pixelSize: 11
                        color: theme.textPrimary
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
            }

            // Nota informativa de fecha mínima permitida
            Text {
                text: "🔒 Fecha mín. permitida: 01 de Agosto de 2026"
                font.pixelSize: 9
                font.bold: true
                color: theme.textMuted
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Cabecera de días de la semana
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

            // Rejilla de días
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
                            color: parent.isSelected ? theme.colorBronze : (dayMouse.containsMouse && parent.parent.isAllowedDate ? (theme.isDark ? "#334155" : "#FEF3C7") : "transparent")
                            border.color: parent.isSelected ? theme.colorBronze : (dayMouse.containsMouse && parent.parent.isAllowedDate ? theme.colorBronze : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.isValidDay ? parent.parent.dayNum : ""
                                font.pixelSize: 12
                                font.bold: parent.parent.isSelected || parent.parent.isAllowedDate
                                color: parent.parent.isSelected ? "#FFFFFF" : (parent.parent.isAllowedDate ? (theme.isDark ? "#F8FAFC" : "#0F172A") : "#CBD5E1")
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

            // Botones de acción del calendario
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

    // =========================================================================
    // POPUP MODAL DE RETROALIMENTACIÓN (ÉXITO O ERROR)
    // =========================================================================
    Popup {
        id: feedbackPopup
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 480
        height: 220
        padding: 18

        property bool isError: false
        property string titleText: ""
        property string messageText: ""
        property string savedPath: ""

        Overlay.modal: Rectangle { color: "#60000000" }

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: feedbackPopup.isError ? "#EF4444" : theme.colorBronze
            border.width: 2
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 12

            Text {
                text: feedbackPopup.isError ? "⚠️ " + feedbackPopup.titleText : "✅ " + feedbackPopup.titleText
                font.pixelSize: 14
                font.bold: true
                color: feedbackPopup.isError ? "#EF4444" : theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: feedbackPopup.messageText
                color: theme.textPrimary
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            // Muestra de la ruta de archivo si existe
            Rectangle {
                visible: feedbackPopup.savedPath !== ""
                width: parent.width
                height: 28
                color: theme.bgMain
                radius: 6
                border.color: theme.borderColor

                Text {
                    anchors.centerIn: parent
                    text: feedbackPopup.savedPath
                    font.pixelSize: 10
                    color: theme.textMuted
                    elide: Text.ElideMiddle
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item { Layout.fillHeight: true; height: 4; width: 1 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    width: 110
                    height: 32
                    contentItem: Text {
                        text: "Aceptar"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: feedbackPopup.isError ? "#EF4444" : theme.colorBronze
                        radius: 6
                    }
                    onClicked: feedbackPopup.close()
                }

                Button {
                    visible: feedbackPopup.savedPath !== ""
                    width: 130
                    height: 32
                    contentItem: Text {
                        text: "📂 Abrir Archivo"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: theme.colorSlate
                        radius: 6
                    }
                    onClicked: {
                        var p = feedbackPopup.savedPath.toString().replace(/\\/g, "/")
                        if (p.indexOf("file:///") === 0) {
                            // Ruta URL completa
                        } else if (p.indexOf("file://") === 0) {
                            p = "file:///" + p.substring(7)
                        } else {
                            if (p.length > 1 && p.charAt(1) === ":") {
                                p = "file:///" + p
                            } else {
                                p = "file://" + p
                            }
                        }
                        Qt.openUrlExternally(p)
                    }
                }
            }
        }
    }
}
