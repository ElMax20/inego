import os

# Información de la Empresa
COMPANY_NAME = "Inego Industrias"
COMPANY_SLOGAN = "Ferretería, Equipos, Suministros de Oficina y Producción"
COMPANY_LOCATION = "Guayaquil, Ecuador"
COMPANY_LOGO_TITLE = "Árbol de la Vida"

# Paleta de Colores "Obsidian & Midnight Glass" (SaaS UI Moderno)
COLOR_BG_MAIN = "#0B0F19"          # Obsidian Dark Space (Fondo Principal)
COLOR_BG_SIDEBAR = "#0F172A"       # Midnight Slate (Barra Lateral)
COLOR_BG_CARD = "#1E293B"          # SaaS Glass Elevated Card
COLOR_BG_CARD_HOVER = "#334155"    # Card Hover Highlight
COLOR_BORDER = "#1E293B"           # Crisp Border Subtlety
COLOR_BORDER_LIGHT = "#334155"     # Borde sutil acentuado

# Acentos y Neón
COLOR_PRIMARY = "#0284C7"          # Electric Sky Blue
COLOR_PRIMARY_HOVER = "#0369A1"    # Electric Sky Dark
COLOR_ACCENT = "#38BDF8"           # Cyan Neon Glow
COLOR_ACCENT_HOVER = "#0EA5E9"     # Cyan Hover
COLOR_LIGHT_BLUE = "#E0F2FE"       # Ice Blue Pill Text
COLOR_PURPLE = "#8B5CF6"           # Indigo SaaS Accent

# Jerarquía de Textos High-Contrast
COLOR_TEXT_PRIMARY = "#F8FAFC"     # Blanco Puro / Alta Legibilidad
COLOR_TEXT_SECONDARY = "#CBD5E1"   # Gris Claro Suave
COLOR_TEXT_MUTED = "#64748B"       # Muted Label Text

# Indicadores de Estado y Alertas
COLOR_SUCCESS = "#10B981"          # Emerald Green Status (Activo/En Stock)
COLOR_SUCCESS_BG = "#064E3B"       # Emerald Pill Background
COLOR_WARNING = "#F59E0B"          # Amber Alert (Crédito 72 días / Re-stock)
COLOR_WARNING_BG = "#451A03"       # Amber Pill Background
COLOR_DANGER = "#EF4444"           # Crimson Danger (Agotado / Bloqueo)
COLOR_DANGER_BG = "#451212"        # Crimson Pill Background

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
