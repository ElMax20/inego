import QtQuick
import QtQuick.Controls

ScrollView {
    id: supRoot
    clip: true

    property var suppliers: []
    property var categoryList: []
    property var filterCategoryList: []
    property string activeOrigen: "Todos los Orígenes"
    property string activeProdType: "Todos los Tipos de Producto"

    Component.onCompleted: loadCategoriesAndData()

    function loadCategoriesAndData() {
        var rawC = backend.getCategories()
        categoryList = JSON.parse(rawC)

        // Lista de categorías para el filtro (reemplaza la opción de agregar nueva categoría por "Todos los Tipos de Producto")
        var fList = ["Todos los Tipos de Producto"]
        for (var i = 0; i < categoryList.length; i++) {
            if (categoryList[i] !== "➕ Agregar Nueva Categoría...") {
                fList.push(categoryList[i])
            }
        }
        filterCategoryList = fList

        loadData(cbOrigenFilter.currentText, cbTypeFilter.currentText)
    }

    function loadData(origenName, prodType) {
        activeOrigen = origenName || "Todos los Orígenes"
        activeProdType = prodType || "Todos los Tipos de Producto"
        suppliers = []
        var raw = backend.getSuppliersData(activeOrigen, activeProdType)
        suppliers = JSON.parse(raw)
    }

    Column {
        width: supRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Item { height: 10; width: 1 }

        // Header Proveedores
        Text {
            text: "Proveedores Guayaquil, Provincias e Importaciones"
            font.pixelSize: 15
            font.bold: true
            color: theme.textPrimary
        }

        // BARRA DE FILTROS POR ORIGEN Y POR TIPO DE PRODUCTO + BOTÓN CREAR PROVEEDOR
        Item {
            width: parent.width
            height: 44

            Row {
                spacing: 12
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                // FILTRO 1: ORIGEN DE UBICACIÓN
                Text {
                    text: "Origen:"
                    font.pixelSize: 11
                    font.bold: true
                    color: theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: cbOrigenFilter
                    width: 170
                    height: 38
                    model: ["Todos los Orígenes", "Guayaquil", "Otras Provincias", "Importados (Amazon / Tiendamia)"]
                    onActivated: supRoot.loadData(cbOrigenFilter.currentText, cbTypeFilter.currentText)
                }

                // FILTRO 2: TIPO / CATEGORÍA DE PRODUCTO
                Text {
                    text: "Tipo de Producto:"
                    font.pixelSize: 11
                    font.bold: true
                    color: theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: cbTypeFilter
                    width: 220
                    height: 38
                    model: supRoot.filterCategoryList
                    onActivated: supRoot.loadData(cbOrigenFilter.currentText, cbTypeFilter.currentText)
                }
            }

            // BOTÓN CREAR NUEVO PROVEEDOR
            Button {
                id: btnCreateSup
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 38
                width: 175

                contentItem: Text {
                    text: "Crear Nuevo Proveedor"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: btnCreateSup.pressed ? theme.colorBronzeHover : theme.colorBronze
                    radius: 8
                    scale: btnCreateSup.pressed ? 0.98 : (btnCreateSup.hovered ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }

                onClicked: {
                    supRoot.loadCategoriesAndData()
                    newSupplierPopup.x = Math.max(20, (Overlay.overlay.width - newSupplierPopup.width) / 2)
                    newSupplierPopup.y = Math.max(20, (Overlay.overlay.height - newSupplierPopup.height) / 2)
                    newSupplierPopup.open()
                }
            }
        }

        // LISTADO DE TARJETAS DE PROVEEDORES EN QML
        Repeater {
            model: supRoot.suppliers

            Rectangle {
                width: parent.width
                height: 90
                color: theme.bgCard
                radius: 10
                border.color: theme.borderColor

                Row {
                    anchors.fill: parent
                    anchors.margins: 14

                    Column {
                        spacing: 4
                        Text {
                            text: modelData.nombre_empresa + " (RUC: " + modelData.ruc_cedula + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Contacto Principal: " + modelData.contacto_nombre + " | Tel: " + modelData.telefono + " | Correo: " + modelData.email
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                        Text {
                            text: "Categoría/Tipo Producto: " + modelData.tipo_producto + " | Dirección: " + (modelData.direccion && modelData.direccion !== "null" ? modelData.direccion : "Guayaquil - Ecuador") + " | Ubicación: " + modelData.ubicacion
                            font.pixelSize: 10
                            color: theme.colorBronze
                            font.bold: true
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.badgeBgBronze
                        radius: 6
                        width: 110
                        height: 26

                        Text {
                            anchors.centerIn: parent
                            text: modelData.ubicacion.indexOf("Importación") !== -1 ? "Importador" : "Guayaquil"
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.colorBronze
                        }
                    }
                }
            }
        }
    }

    // VENTANA MODAL FLOTANTE ARRASTRABLE Y REDIMENSIONABLE (CON SELECCIÓN DE CATEGORÍA IGUAL A PRODUCTOS)
    Popup {
        id: newSupplierPopup
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

            // BARRA SUPERIOR ARRASTRABLE CON EL MOUSE
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
                    text: "📌 Crear Nuevo Proveedor Corporativo (Mover con el Mouse)"
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
                            newSupplierPopup.x = newSupplierPopup.x + (mouse.x - dragOffset.x)
                            newSupplierPopup.y = newSupplierPopup.y + (mouse.y - dragOffset.y)
                        }
                    }
                }
            }

            // CONTENIDO DEL FORMULARIO DE PROVEEDORES
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

                    Text { text: "RUC del Proveedor (Máximo 13 dígitos numéricos - Provincia 01-24 o 30):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: supRuc
                        placeholderText: "ej. 0991234567001"
                        width: parent.width
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]{10,13}$/ }
                    }

                    Text { text: "Razón Social del Proveedor:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: supName; placeholderText: "ej. Ferretería Industrial Guayaquil S.A."; width: parent.width }

                    Text { text: "Categoría / Tipo de Producto del Proveedor (Incluye Opción de Nueva Categoría):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: supCategoryCombo
                        width: parent.width
                        model: supRoot.categoryList
                        onActivated: function(index) {
                            if (currentText === "➕ Agregar Nueva Categoría...") {
                                newCategoryDialog.open()
                            }
                        }
                    }

                    Text { text: "Nombre del Contacto Principal:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: supContactName; placeholderText: "ej. Ing. Carlos Mendoza"; width: parent.width }

                    Text { text: "Teléfono / WhatsApp del Contacto (Únicamente 10 dígitos numéricos):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField {
                        id: supContactPhone
                        placeholderText: "ej. 0991234567"
                        width: parent.width
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]{10}$/ }
                    }

                    Text { text: "Dirección del Proveedor:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: supAddress; placeholderText: "ej. Av. Francisco de Orellana y Vía Samborondón"; width: parent.width }

                    Text { text: "Correo Electrónico (Requerido: @gmail.com, @hotmail.com, @outlook.com, etc.):"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    TextField { id: supEmail; placeholderText: "ej. ventas@gmail.com"; width: parent.width }

                    Text { text: "Origen / Clasificación de Ubicación:"; font.pixelSize: 11; font.bold: true; color: theme.textMuted }
                    ComboBox {
                        id: supType
                        width: parent.width
                        model: ["Guayaquil", "Otras Provincias", "Importados (Amazon / Tiendamia)"]
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
                        width: 140
                        height: 34
                        contentItem: Text { text: "Guardar Proveedor"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorBronze; radius: 6 }
                        onClicked: {
                            var resStr = backend.addSupplier(
                                supRuc.text, supName.text, supContactName.text,
                                supContactPhone.text, supEmail.text, supAddress.text, supType.currentText,
                                supCategoryCombo.currentText
                            )
                            var res = JSON.parse(resStr)
                            if (!res.success) {
                                supErrTxt.text = res.message
                                supErrDialog.open()
                            } else {
                                newSupplierPopup.close()
                                supRoot.loadCategoriesAndData()
                            }
                        }
                    }

                    Button {
                        width: 100
                        height: 34
                        contentItem: Text { text: "Cancelar"; color: "#FFFFFF"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: theme.colorSlate; radius: 6 }
                        onClicked: newSupplierPopup.close()
                    }
                }

                // MANIJA INFERIOR DERECHA PARA REDIMENSIONAR CON EL MOUSE
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
                                newSupplierPopup.width = Math.max(380, newSupplierPopup.width + deltaX)
                                newSupplierPopup.height = Math.max(480, newSupplierPopup.height + deltaY)
                            }
                        }
                    }
                }
            }
        }
    }

    // DIÁLOGO SECUNDARIO PARA AGREGAR NUEVA CATEGORÍA EN PROVEEDORES (SOBRE OVERLAY CON ALTO CONTRASTE)
    Dialog {
        id: newCategoryDialog
        parent: Overlay.overlay
        title: "Agregar Nueva Categoría"
        anchors.centerIn: parent
        modal: true
        width: 400

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorBronze
            border.width: 2
        }

        contentItem: Column {
            spacing: 12
            width: parent.width - 24

            Text { text: "Nombre de la Nueva Categoría:"; font.pixelSize: 12; font.bold: true; color: theme.textPrimary }
            TextField { id: newCatName; placeholderText: "ej. Insumos Químicos / Embalaje"; width: parent.width; color: theme.textPrimary }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (newCatName.text.trim() !== "") {
                backend.addCategory(newCatName.text)
                supRoot.loadCategoriesAndData()
            }
        }
    }

    // DIÁLOGO MODAL AVISO DE ERROR/VALIDACIÓN (SOBRE OVERLAY CON ALTO CONTRASTE Y MÁXIMA LEGIBILIDAD)
    Dialog {
        id: supErrDialog
        parent: Overlay.overlay
        title: "Registro de Proveedor"
        anchors.centerIn: parent
        modal: true
        width: 420

        background: Rectangle {
            color: theme.bgCard
            radius: 12
            border.color: theme.colorBronze
            border.width: 2
        }

        contentItem: Column {
            spacing: 14
            width: parent.width - 24

            Text {
                id: supErrTxt
                text: ""
                color: theme.textPrimary
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }

        standardButtons: Dialog.Ok
    }
}
