import os

# Información de la Empresa
COMPANY_NAME = "Inego Industrias"
COMPANY_SLOGAN = "Ferretería, Equipos, Suministros de Oficina y Producción"
COMPANY_LOCATION = "Guayaquil, Ecuador"
COMPANY_LOGO_TITLE = "Árbol de la Vida"

# Paleta de Colores "Twinkle Bronze & Slate" (Tuplas Duales Light/Dark)
# Formato CustomTkinter: (Modo_Claro_Por_Defecto, Modo_Oscuro)

COLOR_BG_MAIN = ("#F0F4F7", "#1E2430")          # Fondo Principal
COLOR_BG_SIDEBAR = ("#E2E8EC", "#171C26")       # Barra Lateral
COLOR_BG_CARD = ("#FFFFFF", "#2B3342")          # Tarjetas Elevadas
COLOR_BG_CARD_HOVER = ("#E8EEF2", "#384357")    # Hover en Tarjetas
COLOR_BORDER = ("#D5DEE5", "#3F4A5C")           # Bordes Sutiles
COLOR_BORDER_LIGHT = ("#E2E9F0", "#49566B")     # Borde Acentuado

# Acentos Bronce y Acero
COLOR_PRIMARY = ("#B88865", "#D4A373")          # Warm Sandy Bronze
COLOR_PRIMARY_HOVER = ("#A07352", "#C89B7B")    # Bronze Dark Hover
COLOR_ACCENT = ("#3F4A5C", "#C89B7B")           # Steel Blue / Bronze Glow
COLOR_ACCENT_HOVER = ("#2D3644", "#B08264")     # Accent Dark Hover
COLOR_LIGHT_BLUE = ("#4A5568", "#F0F4F7")       # Soft Pill Text
COLOR_PURPLE = ("#7C3AED", "#A78BFA")           # Royal Purple Accent

# Jerarquía de Textos
COLOR_TEXT_PRIMARY = ("#1A202C", "#F8FAFC")     # Texto Principal Alto Contraste
COLOR_TEXT_SECONDARY = ("#4A5568", "#CBD5E1")   # Texto Secundario Suave
COLOR_TEXT_MUTED = ("#718096", "#8F9CAE")       # Muted Label Text

# Indicadores de Estado y Alertas
COLOR_SUCCESS = ("#059669", "#10B981")          # Emerald Green Status
COLOR_SUCCESS_BG = ("#D1FAE5", "#064E3B")       # Emerald Pill Background
COLOR_WARNING = ("#D97706", "#F59E0B")          # Amber Alert
COLOR_WARNING_BG = ("#FEF3C7", "#451A03")       # Amber Pill Background
COLOR_DANGER = ("#DC2626", "#EF4444")           # Crimson Danger
COLOR_DANGER_BG = ("#FEE2E2", "#451212")        # Crimson Pill Background

# Rutas del Sistema
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

SQLITE_DB_PATH = os.path.join(DATA_DIR, "inego_industrias.db")

# Configuración MySQL (Default para MySQL Workbench)
MYSQL_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "",
    "database": "inego_industrias_db"
}

# Reglas de Negocio
B2B_CREDIT_DAYS = 72
PARTNER_FIXED_PAY = 50.00
PARTNER_BONUS_PERCENT = 0.05  # 5%
PARTNERS = ["Socio 1 - Administrador de Dinero", "Socio 2 - Compras y Mercadería", "Socio 3 - Proceso Contable"]
