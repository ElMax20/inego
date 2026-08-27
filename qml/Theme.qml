import QtQuick

QtObject {
    id: theme

    property bool isDark: false

    // Colores de Fondo y Tarjetas
    property color bgMain: isDark ? "#1E2430" : "#F0F4F7"
    property color bgSidebar: isDark ? "#171C26" : "#E2E8EC"
    property color bgCard: isDark ? "#2B3342" : "#FFFFFF"
    property color bgCardHover: isDark ? "#384357" : "#F5F8FA"
    property color borderColor: isDark ? "#3F4A5C" : "#D5DEE5"

    // Paleta Oficial Twinkle Bronze & Steel Slate
    property color colorBronze: isDark ? "#D4A373" : "#B88865"
    property color colorBronzeHover: isDark ? "#C89B7B" : "#A07352"
    property color colorSlate: isDark ? "#3F4A5C" : "#3F4A5C"
    property color colorSlateHover: isDark ? "#4C596D" : "#2D3644"

    // Colores de Texto
    property color textPrimary: isDark ? "#F8FAFC" : "#1A202C"
    property color textSecondary: isDark ? "#CBD5E1" : "#4A5568"
    property color textMuted: isDark ? "#8F9CAE" : "#718096"

    // Campos de Entrada Adaptativos (Letras Blancas en Modo Oscuro / Letras Negras en Modo Claro)
    property color inputColor: isDark ? "#FFFFFF" : "#0F172A"
    property color inputBg: isDark ? "#1E2430" : "#FFFFFF"

    // Badges y Estados
    property color badgeBgBronze: isDark ? "#1C2230" : "#FDF8F3"
    property color badgeTextBronze: isDark ? "#D4A373" : "#B88865"
    property color badgeBgSuccess: isDark ? "#064E3B" : "#D1FAE5"
    property color colorSuccess: isDark ? "#10B981" : "#059669"
    property color badgeBgDanger: isDark ? "#451212" : "#FEE2E2"
    property color colorDanger: isDark ? "#EF4444" : "#DC2626"
}
