import QtQuick
import QtQuick.Controls

ScrollView {
    id: payRoot
    clip: true

    property var payroll: []
    property real sueldoBaseFijo: 50.00
    property real bonoContable5: 1058.50
    property real totalNetoPorSocio: 1108.50

    Component.onCompleted: refresh()

    function refresh() {
        var val = parseFloat(txtSueldoBase.text) || 50.00
        var raw = backend.getPayrollData(val)
        if (raw) {
            var data = JSON.parse(raw)
            if (data.partners) {
                payroll = data.partners
                sueldoBaseFijo = data.sueldo_base_fijo || val
                bonoContable5 = data.bono_contable_5 || 1058.50
                totalNetoPorSocio = data.total_neto_por_socio || (val + bonoContable5)
            } else {
                payroll = data
            }
        }
    }

    Column {
        width: payRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // HEADER PRINCIPAL NÓMINA DE SOCIOS (RF4.4) CON BOTÓN DE AGREGAR ROL
        Item {
            width: parent.width
            height: 40

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "👔 Nómina y Roles de Pago de Socios (RF4.4)"
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
                                var val = parseFloat(txtSueldoBase.text) || 50.00
                                payRoot.sueldoBaseFijo = val
                                payRoot.totalNetoPorSocio = val + payRoot.bonoContable5
                            }
                        }
                    }

                    Column {
                        spacing: 2
                        Text { text: "Bono Contable 5% (RF4.3):"; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
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
                                text: "Cargo: " + modelData.cargo + " | Sueldo Base: $" + (modelData.sueldo_base || payRoot.sueldoBaseFijo).toFixed(2) + " + Bono RF4.3: $" + modelData.bono_5.toFixed(2) + " - Deducciones: $" + (modelData.deducciones || 0.0).toFixed(2)
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
        height: 350
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
                    text: "📌 Registrar Nuevo Rol de Pago (Mover con el Mouse)"
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

                    Text { text: "Cargo / Función:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: txtNewSocioCargo
                        placeholderText: "ej. Dirección de Desarrollo de Software"
                        placeholderTextColor: theme.textMuted
                        width: parent.width
                        color: theme.inputColor
                        font.bold: true
                        font.pixelSize: 12
                        selectionColor: theme.colorBronze
                        selectedTextColor: "#FFFFFF"
                        background: Rectangle { color: theme.inputBg; radius: 6; border.color: theme.borderColor }
                    }

                    Text { text: "Observaciones / Nota:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: txtNewSocioObs
                        placeholderText: "ej. Rol individual correspondiente al mes"
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
                            var cargo = txtNewSocioCargo.text.trim()
                            if (!name || !cargo) {
                                payMsgTxt.text = "🚫 Error al registrar rol:\n\nPor favor ingrese el nombre del socio/colaborador y su cargo."
                                payMsgDialog.open()
                                return
                            }

                            var sb = payRoot.sueldoBaseFijo
                            var b5 = payRoot.bonoContable5
                            var ded = 0.00
                            var obs = txtNewSocioObs.text.trim()

                            var resStr = backend.addPayrollRole(name, cargo, sb, b5, ded, obs)
                            var res = JSON.parse(resStr)
                            
                            if (!res.success) {
                                payMsgTxt.text = res.message
                                payMsgDialog.open()
                            } else {
                                newPayrollPopup.close()
                                payMsgTxt.text = res.message
                                payMsgDialog.open()
                                txtNewSocioNombre.text = ""
                                txtNewSocioCargo.text = ""
                                txtNewSocioObs.text = ""
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
}
