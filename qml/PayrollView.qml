import QtQuick
import QtQuick.Controls

ScrollView {
    id: payRoot
    clip: true

    property var payroll: []
    property var selectedPartner: null
    property real sueldoBaseFijo: 50.00
    property real bonoContable5: 1058.50
    property real totalNetoPorSocio: 1108.50

    property real salesBase: 12450.00
    property real purchasesBase: 8720.00
    property real totalConsolidated: 21170.00
    property real calculatedBonus: 1058.50

    property bool isRefreshing: false

    Timer {
        id: bonusDebounceTimer
        interval: 150
        repeat: false
        onTriggered: payRoot.recalcBonus()
    }

    Component.onCompleted: refresh()

    function recalcBonus() {
        var bVal = parseFloat(txtBonusManual.text)
        if (isNaN(bVal) || bVal < 0) bVal = 0.0
        bonoContable5 = bVal
        totalNetoPorSocio = sueldoBaseFijo + bVal

        var tempList = []
        for (var i = 0; i < payroll.length; i++) {
            var p = payroll[i]
            var basePay = p.sueldo_base || sueldoBaseFijo
            var ded = p.deducciones || 0.0
            var netTotal = (basePay + bVal) - ded
            
            var updatedP = {
                "id": p.id,
                "nombre": p.nombre,
                "cargo": p.cargo,
                "sueldo_base": basePay,
                "pago_fijo": basePay,
                "bono_5": bVal,
                "deducciones": ded,
                "total": netTotal,
                "estado": p.estado
            }
            tempList.push(updatedP)
        }
        payroll = tempList
    }

    function refresh() {
        isRefreshing = true
        var val = parseFloat(txtSueldoBase.text) || 50.00
        var raw = backend.getPayrollData(val)
        if (raw) {
            var data = JSON.parse(raw)
            if (data.partners) {
                payroll = data.partners
                sueldoBaseFijo = data.sueldo_base_fijo || val
                bonoContable5 = data.bono_contable_5 || 1058.50
                totalNetoPorSocio = data.total_neto_por_socio || (val + bonoContable5)
                salesBase = data.sales_base || 12450.00
                purchasesBase = data.purchases_base || 8720.00
                totalConsolidated = data.total_consolidated || 21170.00
                calculatedBonus = data.calculated_bonus || 1058.50
                txtBonusManual.text = bonoContable5.toFixed(2)
            } else {
                payroll = data
            }
        }
        isRefreshing = false
    }

    Column {
        width: payRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // HEADER PRINCIPAL NÓMINA DE SOCIOS CON BOTÓN DE AGREGAR ROL
        Item {
            width: parent.width
            height: 40

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "👔 Nómina y Roles de Pago de Socios"
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
                    text: "➕ Agregar Rol de Pago"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newPayrollPopup.open()
                }
            }
        }

        // MÓDULO DE INGRESO MANUAL DE BONO CONTABLE (NÓMINA DE SOCIOS)
        Rectangle {
            width: parent.width
            height: 145
            color: theme.bgCard
            radius: 10
            border.color: theme.borderColor
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "🧮 Cálculo de Bono Mensual - Ingreso Manual"
                    font.pixelSize: 13
                    font.bold: true
                    color: theme.colorBronze
                }

                Row {
                    width: parent.width
                    spacing: 30

                    Column {
                        spacing: 2
                        Text { text: "Base Cál. Ventas (Mes Anterior):"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                        Text { text: "$ " + payRoot.salesBase.toLocaleString(Qt.locale(), "f", 2); font.pixelSize: 12; font.bold: true; color: theme.textPrimary }
                    }

                    Column {
                        spacing: 2
                        Text { text: "Base Cál. Compras (Mes Anterior):"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                        Text { text: "$ " + payRoot.purchasesBase.toLocaleString(Qt.locale(), "f", 2); font.pixelSize: 12; font.bold: true; color: theme.textPrimary }
                    }

                    Column {
                        spacing: 2
                        Text { text: "Total Base Consolidada:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                        Text { text: "$ " + payRoot.totalConsolidated.toLocaleString(Qt.locale(), "f", 2); font.pixelSize: 13; font.bold: true; color: theme.colorSuccess }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 12

                    Text {
                        text: "🧮 Bono Contable Ingreso Manual:"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        id: txtBonusManual
                        width: 120
                        height: 34
                        text: payRoot.calculatedBonus.toFixed(2)
                        color: theme.isDark ? "#000000" : "#0F172A"
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]+(\.[0-9]{1,2})?$/ }
                        background: Rectangle {
                            color: "#FFFFFF"
                            radius: 6
                            border.color: theme.borderColor
                            border.width: 1
                        }
                        onTextChanged: {
                            if (payRoot.isRefreshing) return
                            var val = parseFloat(txtBonusManual.text)
                            if (!isNaN(val) && val >= 0) {
                                payRoot.bonoContable5 = val
                                payRoot.totalNetoPorSocio = payRoot.sueldoBaseFijo + val
                            }
                            bonusDebounceTimer.restart()
                        }
                    }

                    Button {
                        height: 34
                        width: 155
                        contentItem: Text { text: "⚙️ Calcular (Simulación)"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: {
                            var calc = payRoot.totalConsolidated * 0.05
                            txtBonusManual.text = calc.toFixed(2)
                            payRoot.bonoContable5 = calc
                            payRoot.totalNetoPorSocio = payRoot.sueldoBaseFijo + calc
                            payRoot.recalcBonus()
                        }
                    }

                    Button {
                        height: 34
                        width: 165
                        contentItem: Text { text: "✓ Confirmar y Registrar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSuccess; radius: 6 }
                        onClicked: {
                            var val = parseFloat(txtBonusManual.text) || 0.0
                            var resStr = backend.registerManualBonus(val, "Ingreso manual desde Nómina de Socios")
                            var res = JSON.parse(resStr)
                            payMsgTxt.text = res.message
                            payMsgDialog.open()
                            payRoot.refresh()
                        }
                    }
                }
            }
        }

        // PANEL RESUMEN DE LIQUIDACIÓN (TARJETA CORPORATIVA REDONDEADA)
        Rectangle {
            width: parent.width
            height: 145
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "🧾 Panel Resumen de Liquidación Mensual de Socios"
                    font.pixelSize: 13
                    font.bold: true
                    color: theme.colorBronze
                }

                // FILA DE CAMPOS DESGLOSADOS CON SUELDO BASE MODIFICABLE
                Row {
                    width: parent.width
                    spacing: 30

                    Column {
                        spacing: 2
                        Text { text: "Sueldo Base Fijo Mensual:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                        TextField {
                            id: txtSueldoBase
                            height: 32
                            width: 110
                            text: payRoot.sueldoBaseFijo.toFixed(2)
                            color: theme.isDark ? "#000000" : "#0F172A"
                            font.bold: true
                            font.pixelSize: 12
                            selectionColor: theme.colorBronze
                            selectedTextColor: "#FFFFFF"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: RegularExpressionValidator { regularExpression: /^[0-9]+(\.[0-9]{1,2})?$/ }
                            background: Rectangle {
                                color: "#FFFFFF"
                                radius: 6
                                border.color: theme.borderColor
                                border.width: 1
                            }
                            onTextChanged: {
                                if (payRoot.isRefreshing) return
                                var val = parseFloat(txtSueldoBase.text)
                                if (!isNaN(val) && val >= 0) {
                                    payRoot.sueldoBaseFijo = val
                                    payRoot.totalNetoPorSocio = val + payRoot.bonoContable5
                                }
                                bonusDebounceTimer.restart()
                            }
                        }
                    }

                    Column {
                        spacing: 2
                        Text { text: "Bono Contable:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                        Text {
                            text: "$ " + payRoot.bonoContable5.toLocaleString(Qt.locale(), "f", 2) + " USD"
                            font.pixelSize: 12
                            font.bold: true
                            color: theme.textPrimary
                        }
                    }

                    Column {
                        spacing: 2
                        Text { text: "Total Neto a Pagar por Socio:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                        Rectangle {
                            height: 28
                            width: payTotNetTxt.width + 16
                            color: theme.badgeBgSuccess
                            radius: 6
                            Text {
                                id: payTotNetTxt
                                anchors.centerIn: parent
                                text: "$ " + payRoot.totalNetoPorSocio.toLocaleString(Qt.locale(), "f", 2) + " USD"
                                font.pixelSize: 12
                                font.bold: true
                                color: theme.colorSuccess
                            }
                        }
                    }
                }

                // BOTONES DE ACCIÓN PRINCIPAL
                Row {
                    width: parent.width
                    spacing: 12

                    Button {
                        height: 34
                        width: 160
                        contentItem: Text { text: "🔄 Recalcular Totales"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: payRoot.refresh()
                    }

                    Button {
                        height: 34
                        width: 220
                        contentItem: Text { text: "✓ Aprobar y Generar Roles del Mes"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            var val = parseFloat(txtSueldoBase.text) || 50.00
                            var resStr = backend.aprobarRolesMes(val)
                            var res = JSON.parse(resStr)
                            payMsgTxt.text = res.message
                            payMsgDialog.open()
                            payRoot.refresh()
                        }
                    }
                }
            }
        }

        // TÍTULO SECCIÓN TABLA / LISTVIEW DE ROLES GENERADOS POR SOCIO
        Text {
            text: "📋 Detalle y Roles Liquidados por Socio"
            font.pixelSize: 13
            font.bold: true
            color: theme.colorBronze
        }

        // LISTA DE TARJETAS HORIZONTALES POR SOCIO
        Repeater {
            model: payRoot.payroll

            Rectangle {
                width: parent.width
                height: 82
                color: theme.bgCard
                radius: 10
                border.color: theme.borderColor

                Item {
                    anchors.fill: parent
                    anchors.margins: 12

                    Row {
                        anchors.fill: parent
                        spacing: 14

                        Column {
                            width: parent.width - 240
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Row {
                                spacing: 10
                                Text {
                                    text: "👔 " + modelData.nombre
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: theme.textPrimary
                                }
                                Rectangle {
                                    color: (modelData.estado === "Aprobado" || modelData.estado === "Pagado") ? theme.badgeBgSuccess : theme.badgeBgBronze
                                    radius: 6
                                    height: 20
                                    width: badgeStateTxt.width + 12
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: badgeStateTxt
                                        anchors.centerIn: parent
                                        text: modelData.estado || "Calculado"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: (modelData.estado === "Aprobado" || modelData.estado === "Pagado") ? theme.colorSuccess : theme.colorBronze
                                    }
                                }
                            }

                            Text {
                                text: "Cargo: " + modelData.cargo + " | Sueldo Base: $" + (modelData.sueldo_base || payRoot.sueldoBaseFijo).toFixed(2) + " + Bono: $" + modelData.bono_5.toFixed(2) + " - Deducciones: $" + (modelData.deducciones || 0.0).toFixed(2)
                                font.pixelSize: 11
                                color: theme.textMuted
                            }
                        }

                        // TOTAL Y ACCIONES RÁPIDAS DE FILA
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Text {
                                text: "$ " + modelData.total.toLocaleString(Qt.locale(), "f", 2) + " USD"
                                font.pixelSize: 14
                                font.bold: true
                                color: theme.colorSuccess
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Button {
                                height: 32
                                width: 170
                                contentItem: Text { text: "📄 Comprobante PDF"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: theme.colorBronze; radius: 6 }
                                onClicked: {
                                    var val = parseFloat(txtSueldoBase.text) || 50.00
                                    var resStr = backend.exportarRolPDF(modelData.id, val)
                                    var res = JSON.parse(resStr)
                                    payMsgTxt.text = res.message
                                    payMsgDialog.open()
                                }
                            }

                            // MENÚ DE TRES PUNTOS (⋮) - EXCLUSIVO ADMINISTRADOR
                            Button {
                                id: btnPayrollDots
                                height: 32
                                width: 32
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
                                    color: btnPayrollDots.hovered ? theme.bgCardHover : "transparent"
                                    radius: 16
                                    border.color: theme.borderColor
                                }

                                onClicked: payrollActionMenu.open()

                                Menu {
                                    id: payrollActionMenu
                                    y: btnPayrollDots.height

                                    MenuItem {
                                        text: "✏️ Modificar Rol"
                                        onTriggered: {
                                            payRoot.selectedPartner = modelData
                                            editPayrollName.text = modelData.nombre || ""
                                            editPayrollCargo.text = modelData.cargo || ""
                                            editPayrollSueldo.text = (modelData.sueldo_base || payRoot.sueldoBaseFijo).toFixed(2)
                                            editPayrollBono.text = (modelData.bono_5 || 0.0).toFixed(2)
                                            editPayrollDeducciones.text = (modelData.deducciones || 0.0).toFixed(2)
                                            editPayrollStatus.currentIndex = editPayrollStatus.model.indexOf(modelData.estado) >= 0 ? editPayrollStatus.model.indexOf(modelData.estado) : 0
                                            editPayrollDialog.open()
                                        }
                                    }
                                    MenuItem {
                                        text: "🗑️ Eliminar de Base de Datos"
                                        onTriggered: {
                                            payRoot.selectedPartner = modelData
                                            deletePayrollDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // POPUP MODAL REGISTRAR NUEVO ROL DE PAGO (ARRASTRABLE Y CORPORATIVO)
    Popup {
        id: newPayrollPopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 520
        height: 430
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

            // BARRA SUPERIOR ARRASTRABLE
            Rectangle {
                id: payrollTitleBar
                width: parent.width
                height: 42
                color: theme.colorBronze
                radius: 10

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "📌 Registrar Nuevo Rol de Pago y Usuario (Mover con el Mouse)"
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
                            newPayrollPopup.x = newPayrollPopup.x + (mouse.x - dragOffset.x)
                            newPayrollPopup.y = newPayrollPopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO
            ScrollView {
                id: payrollScroll
                anchors.top: payrollTitleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: payrollBottomBar.top
                anchors.margins: 14
                clip: true

                Column {
                    width: payrollScroll.width - 20
                    spacing: 10

                    Text { text: "Nombre del Socio / Colaborador:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: txtNewSocioNombre
                        placeholderText: "ej. Socio 4 - Desarrollo Tecnológico o María López"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Cargo / Función / Rol del Socio:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: cmbNewSocioCargo
                        width: parent.width
                        model: {
                            var r = backend.getCurrentUserRole()
                            var list = ["Administrador de Dinero", "Compras y Mercadería", "Proceso Contable"]
                            if (r === "Administrador" || r === "Administrador General") {
                                list.unshift("Administrador")
                            }
                            list.push("➕ Agregar Nuevo Rol...")
                            return list
                        }
                        onCurrentTextChanged: {
                            if (currentText === "➕ Agregar Nuevo Rol...") {
                                txtCustomCargo.visible = true
                            } else {
                                txtCustomCargo.visible = false
                            }
                        }
                    }

                    TextField {
                        id: txtCustomCargo
                        visible: false
                        placeholderText: "Escriba el nombre del nuevo rol personalizado"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.colorBronze }
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        Column {
                            width: (parent.width - 12) / 2
                            spacing: 4
                            Text { text: "Nombre de Usuario (Login):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                            TextField {
                                id: txtNewSocioUsername
                                placeholderText: "ej. socio4"
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

                        Column {
                            width: (parent.width - 12) / 2
                            spacing: 4
                            Text { text: "Contraseña de Acceso:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                            TextField {
                                id: txtNewSocioPassword
                                placeholderText: "ej. clave123"
                                placeholderTextColor: theme.textMuted
                                echoMode: TextInput.Password
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
                }
            }

            // BARRA INFERIOR DE ACCIONES DEL MODAL
            Item {
                id: payrollBottomBar
                width: parent.width
                height: 48
                anchors.bottom: parent.bottom

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Button {
                        width: 140
                        height: 34
                        contentItem: Text { text: "Guardar Rol"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            var name = txtNewSocioNombre.text.trim()
                            var cargo = cmbNewSocioCargo.currentText
                            if (cargo === "➕ Agregar Nuevo Rol...") {
                                cargo = txtCustomCargo.text.trim()
                            }
                            var username = txtNewSocioUsername.text.trim()
                            var password = txtNewSocioPassword.text.trim()

                            if (!name || !cargo || !username || !password) {
                                payMsgTxt.text = "🚫 Error al registrar rol y usuario:\n\nPor favor complete todos los campos (Nombre, Rol/Cargo, Usuario y Contraseña)."
                                payMsgDialog.open()
                                return
                            }

                            var sb = payRoot.sueldoBaseFijo
                            var b5 = payRoot.bonoContable5
                            var ded = 0.00

                            var resStr = backend.addPayrollRole(name, cargo, username, password, sb, b5, ded, "")
                            var res = JSON.parse(resStr)
                            
                            if (!res.success) {
                                payMsgTxt.text = res.message
                                payMsgDialog.open()
                            } else {
                                newPayrollPopup.close()
                                payMsgTxt.text = res.message
                                payMsgDialog.open()
                                txtNewSocioNombre.text = ""
                                cmbNewSocioCargo.currentIndex = 0
                                txtNewSocioUsername.text = ""
                                txtNewSocioPassword.text = ""
                                payRoot.refresh()
                            }
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: {
                            newPayrollPopup.close()
                        }
                    }
                }
            }
        }
    }

    // POPUP MODAL MENSAJES DE ROL DE PAGO (COLOR UNIFORME TOTAL)
    Popup {
        id: payMsgDialog
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
                text: "👔 Rol de Pago de Socios"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorBronze
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                id: payMsgTxt
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
                    onClicked: payMsgDialog.close()
                }
            }
        }
    }

    // POPUP EDITAR ROL DE PAGO DE SOCIO (ADMIN)
    // POPUP EDITAR ROL DE PAGO DE SOCIO (ADMIN)
    Popup {
        id: editPayrollDialog
        parent: Overlay.overlay
        x: Math.max(20, (parent.width - width) / 2)
        y: Math.max(20, (parent.height - height) / 2)
        width: 480
        height: 500
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
                id: editPayrollTitleBar
                width: parent.width
                height: 42
                color: theme.colorBronze
                radius: 10

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✏️ Modificar Rol de Pago del Socio (Mover con el Mouse)"
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
                            editPayrollDialog.x = editPayrollDialog.x + (mouse.x - dragOffset.x)
                            editPayrollDialog.y = editPayrollDialog.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO
            ScrollView {
                id: editPayrollScroll
                anchors.top: editPayrollTitleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: editPayrollBottomBar.top
                anchors.margins: 14
                clip: true

                Column {
                    width: editPayrollScroll.width - 20
                    spacing: 12

                    Text { text: "Nombre del Socio / Colaborador:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: editPayrollName
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Cargo / Función del Socio:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: editPayrollCargo
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        Column {
                            width: (parent.width - 20) / 3
                            spacing: 4
                            Text { text: "Sueldo Base USD:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                            TextField {
                                id: editPayrollSueldo
                                width: parent.width
                                color: theme.inputColor
                                font.bold: true
                                font.pixelSize: 12
                                selectionColor: theme.colorBronze
                                selectedTextColor: "#FFFFFF"
                                background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                            }
                        }

                        Column {
                            width: (parent.width - 20) / 3
                            spacing: 4
                            Text { text: "Bono 5% USD:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                            TextField {
                                id: editPayrollBono
                                width: parent.width
                                color: theme.inputColor
                                font.bold: true
                                font.pixelSize: 12
                                selectionColor: theme.colorBronze
                                selectedTextColor: "#FFFFFF"
                                background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                            }
                        }

                        Column {
                            width: (parent.width - 20) / 3
                            spacing: 4
                            Text { text: "Deducciones USD:"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                            TextField {
                                id: editPayrollDeducciones
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

                    Text { text: "Estado del Rol de Pago:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: editPayrollStatus
                        width: parent.width
                        model: ["Calculado", "Aprobado", "Pagado"]
                    }
                }
            }

            // BARRA INFERIOR DE ACCIONES
            Item {
                id: editPayrollBottomBar
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
                            if (!payRoot.selectedPartner) return
                            var sb = parseFloat(editPayrollSueldo.text) || 0
                            var b5 = parseFloat(editPayrollBono.text) || 0
                            var ded = parseFloat(editPayrollDeducciones.text) || 0
                            var name = editPayrollName.text.trim()
                            var cargo = editPayrollCargo.text.trim()
                            var st = editPayrollStatus.currentText

                            var resStr = backend.updatePayroll(payRoot.selectedPartner.id, name, cargo, sb, b5, ded, st)
                            var res = JSON.parse(resStr)
                            if (!res.success) {
                                payMsgTxt.text = res.message
                                payMsgDialog.open()
                            } else {
                                editPayrollDialog.close()
                                payRoot.refresh()
                            }
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: editPayrollDialog.close()
                    }
                }
            }
        }
    }

    // POPUP ELIMINAR ROL DE PAGO DE SOCIO (ADMIN)
    Popup {
        id: deletePayrollDialog
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
                text: "🗑️ Eliminar Rol de Pago"
                font.pixelSize: 15
                font.bold: true
                color: theme.colorDanger
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "¿Está seguro que desea eliminar el rol de pago de " + (payRoot.selectedPartner ? payRoot.selectedPartner.nombre : "") + " de la base de datos?\nEsta acción no se puede deshacer."
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
                        if (!payRoot.selectedPartner) return
                        var ok = backend.deletePayroll(payRoot.selectedPartner.id)
                        if (ok) {
                            deletePayrollDialog.close()
                            payRoot.refresh()
                        }
                    }
                }

                Button {
                    height: 34
                    width: 100
                    contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: theme.colorSlate; radius: 6 }
                    onClicked: deletePayrollDialog.close()
                }
            }
        }
    }
}
