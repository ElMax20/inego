import QtQuick
import QtQuick.Controls

ScrollView {
    id: dashRoot
    clip: true

    property var dashData: ({ "ventas": 0.0, "gastos": 0.0, "credito": 0.0, "cotizaciones": 0, "stock_items": [] })

    Component.onCompleted: refresh()

    function refresh() {
        var raw = backend.getDashboardData()
        dashData = JSON.parse(raw)
    }

    Column {
        width: dashRoot.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Item { height: 10; width: 1 }

        // REJILLA KPI QML CON ANIMACIÓN DE ELEVACIÓN HOVER
        Grid {
            columns: 4
            spacing: 16
            width: parent.width

            Repeater {
                model: [
                    { title: "VENTAS TOTALES MES", val: "$" + dashData.ventas.toFixed(2), icon: "💵", trend: "▲ +15.4%" },
                    { title: "GASTOS Y OPERATIVA", val: "$" + dashData.gastos.toFixed(2), icon: "🧾", trend: "▼ -3.2%" },
                    { title: "CRÉDITOS B2B VIVOS", val: "$" + dashData.credito.toFixed(2), icon: "⏳", trend: "⚡ 72 Días" },
                    { title: "COTIZACIONES ACTIVAS", val: dashData.cotizaciones.toString(), icon: "📋", trend: "▲ +8.0%" }
                ]

                Rectangle {
                    width: (parent.width - 48) / 4
                    height: 110
                    color: theme.bgCard
                    radius: 12
                    border.color: theme.borderColor

                    // Animación de Elevación QML en Hover (HoverHandler + Behavior on y)
                    y: kpiHover.hovered ? -4 : 0
                    Behavior on y { NumberAnimation { duration: 150 } }

                    HoverHandler { id: kpiHover }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        Row {
                            width: parent.width
                            Text { text: modelData.title; font.pixelSize: 10; font.bold: true; color: theme.textMuted }
                        }

                        Text {
                            text: modelData.val
                            font.pixelSize: 20
                            font.bold: true
                            color: theme.textPrimary
                        }

                        Rectangle {
                            color: theme.badgeBgSuccess
                            radius: 4
                            width: trendTxt.width + 12
                            height: 18

                            Text {
                                id: trendTxt
                                anchors.centerIn: parent
                                text: modelData.trend
                                font.pixelSize: 9
                                font.bold: true
                                color: theme.colorSuccess
                            }
                        }
                    }
                }
            }
        }

        // PANEL DE CONTROL DE STOCK PERMANENTE EN MODO CLARO
        Rectangle {
            width: parent.width
            height: stockCol.height + 40
            color: theme.bgCard
            radius: 12
            border.color: theme.borderColor

            Column {
                id: stockCol
                width: parent.width - 32
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 16
                spacing: 12

                Row {
                    spacing: 10
                    Text { text: "📦 Control de Stock Permanente (Items Fijos)"; font.pixelSize: 14; font.bold: true; color: theme.textPrimary }
                }

                Text { text: "Monitoreo de productos de rotación continua (Cuchillas doble filo, Licencias Office):"; font.pixelSize: 11; color: theme.textMuted }

                // FILAS DE STOCK
                Repeater {
                    model: dashData.stock_items

                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: 8
                        color: theme.bgMain
                        border.color: theme.borderColor

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12

                            Text {
                                text: (modelData.es_alerta ? "🚨 " : "• ") + modelData.nombre + " [" + modelData.codigo + "]"
                                font.pixelSize: 12
                                font.bold: true
                                color: theme.textPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                color: modelData.es_alerta ? theme.badgeBgDanger : theme.badgeBgSuccess
                                radius: 6
                                width: stockTxt.width + 16
                                height: 24

                                Text {
                                    id: stockTxt
                                    anchors.centerIn: parent
                                    text: modelData.es_alerta ? "RE-STOCK: " + modelData.stock_actual : "Stock: " + modelData.stock_actual + " unids"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: modelData.es_alerta ? theme.colorDanger : theme.colorSuccess
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
