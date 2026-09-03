import QtQuick
import QtQuick.Controls

Rectangle {
    id: sidebarRoot
    width: 240
    color: theme.bgSidebar
    border.color: theme.borderColor
    border.width: 1

    signal routeSelected(string routeName, string titleHeader)

    property string activeRoute: "dashboard"

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        // Brand Header QML con Imagen del Logo Árbol de la Vida Ultra Nítido
        Row {
            spacing: 10
            Image {
                source: "../logo.png"
                width: 32
                height: 32
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                sourceSize.width: 256
                sourceSize.height: 256
            }
            Column {
                Text { text: "INEGO INDUSTRIAS"; font.pixelSize: 13; font.bold: true; color: theme.textPrimary }
                Text { text: "QML Native Edition"; font.pixelSize: 10; font.bold: true; color: theme.colorBronze }
            }
        }

        Rectangle { width: parent.width; height: 1; color: theme.borderColor }

        Text {
            text: "MENÚ OPERATIVO"
            font.pixelSize: 10
            font.bold: true
            color: theme.textMuted
        }

        // ITEMS DE NAVEGACIÓN EN QML
        Repeater {
            model: [
                { route: "dashboard", label: "📊 Panel Principal", title: "PANEL DE CONTROL GENERAL" },
                { route: "catalog", label: "📦 Catálogo", title: "CATÁLOGO GENERAL Y ENLACE DE PROVEEDORES" },
                { route: "stock", label: "📈 Control de Stock", title: "CONTROL DE INVENTARIO, DESPACHOS Y RENOVACIONES" },
                { route: "suppliers", label: "🏭 Proveedores", title: "PROVEEDORES GUAYAQUIL E IMPORTACIONES" },
                { route: "clients", label: "👥 Clientes (B2B/B2C)", title: "HISTORIAL CLIENTES Y CRÉDITOS 72 DÍAS" },
                { route: "quotes", label: "📋 Cotizaciones", title: "COTIZADOR MULTI-PROVEEDOR Y WHATSAPP" },
                { route: "expenses", label: "🧾 Gastos y Servicios", title: "CONTROL DE CAJA CHICA, AGUA Y LOGÍSTICA" },
                { route: "payroll", label: "👔 Nómina de Socios", title: "ROLES DE PAGO FÍSICOS ($50 + BONO)" },
                { route: "reports", label: "📈 Reportes y Gantt", title: "DESCARGA DE EXCEL Y GANTT GOBIERNO" },
                { route: "users", label: "🛡️ Usuarios y Bitácora", title: "CONTROL DE ACCESO Y AUDITORÍA DE TAREAS" },
                { route: "settings", label: "⚙️ Configuración", title: "CONFIGURACIÓN DE TEMA Y APARIENCIA" }
            ]

            Rectangle {
                id: navItem
                width: sidebarRoot.width - 28
                height: 36
                radius: 8

                property bool isActive: sidebarRoot.activeRoute === modelData.route
                color: isActive ? theme.colorBronze : (navMouse.containsMouse ? theme.bgCardHover : "transparent")

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    spacing: 8

                    Text {
                        text: modelData.label
                        font.pixelSize: 11
                        font.bold: true
                        color: navItem.isActive ? "#FFFFFF" : theme.textPrimary
                    }
                }

                MouseArea {
                    id: navMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sidebarRoot.activeRoute = modelData.route
                        sidebarRoot.routeSelected(modelData.route, modelData.title)
                    }
                }
            }
        }
    }
}
