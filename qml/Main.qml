import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: appWindow
    width: 1280
    height: 760
    minimumWidth: 1100
    minimumHeight: 680
    visible: true
    title: "INEGO INDUSTRIAS - ERP / CRM QML System"

    Theme { id: theme }

    background: Rectangle { color: theme.bgMain }

    function logoutUser() {
        backend.logout()
        mainContent.visible = false
        loginView.visible = true
        sidebar.activeRoute = "dashboard"
        header.moduleTitle = "PANEL DE CONTROL GENERAL"
    }

    // Pantalla de Autenticación (Login) QML
    LoginView {
        id: loginView
        anchors.fill: parent
        visible: true

        onLoginSuccess: function(uname, role) {
            loginView.visible = false
            mainContent.visible = true
            header.userName = uname
            header.userRole = role
            loader.source = "DashboardView.qml"
        }
    }

    // Estructura Principal de la Aplicación QML (Sidebar + Header + Dynamic Loader)
    Item {
        id: mainContent
        anchors.fill: parent
        visible: false

        Sidebar {
            id: sidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            onRouteSelected: function(route, title) {
                header.moduleTitle = title
                if (route === "dashboard") loader.source = "DashboardView.qml"
                else if (route === "catalog") loader.source = "CatalogView.qml"
                else if (route === "stock") loader.source = "StockView.qml"
                else if (route === "suppliers") loader.source = "SuppliersView.qml"
                else if (route === "clients") loader.source = "ClientsView.qml"
                else if (route === "quotes") loader.source = "QuotesView.qml"
                else if (route === "expenses") loader.source = "ExpensesView.qml"
                else if (route === "payroll") loader.source = "PayrollView.qml"
                else if (route === "reports") loader.source = "ReportesView.qml"
                else if (route === "users") loader.source = "UsersView.qml"
                else if (route === "settings") loader.source = "SettingsView.qml"
                else loader.source = "DashboardView.qml"
            }
        }

        Header {
            id: header
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
        }

        // Cargador Dinámico de Módulos Vistas QML
        Loader {
            id: loader
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            source: "DashboardView.qml"

            onLoaded: {
                if (loader.item && loader.item.logoutRequested) {
                    loader.item.logoutRequested.connect(appWindow.logoutUser)
                }
            }
        }
    }
}
