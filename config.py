import os

# Información de la Empresa
COMPANY_NAME = "Inego Industrias"
COMPANY_SLOGAN = "Ferretería, Equipos, Suministros de Oficina y Producción"
COMPANY_LOCATION = "Guayaquil, Ecuador"
COMPANY_LOGO_TITLE = "Árbol de la Vida"

# Paleta de Colores Corporativa (Gama de Azules)
COLOR_BG_MAIN = "#0A192F"       # Azul Marino Profundo (Fondo Principal)
COLOR_BG_CARD = "#112240"       # Azul Oscuro Tarjetas / Tarjetas elevadas
COLOR_PRIMARY = "#1E3E7A"       # Azul Real Corporativo
COLOR_PRIMARY_HOVER = "#2563EB" # Azul Brillante Hover
COLOR_ACCENT = "#0284C7"        # Azul Cían/Zafiro
COLOR_ACCENT_HOVER = "#0369A1"  # Azul Cían Oscuro Hover
COLOR_LIGHT_BLUE = "#E0F2FE"    # Azul Hielo Textos/Badges
COLOR_BORDER = "#1E293B"        # Borde Azul Grisáceo

COLOR_TEXT_PRIMARY = "#F8FAFC"  # Blanco puro / Suave
COLOR_TEXT_SECONDARY = "#94A3B8"# Gris azulado claro
COLOR_TEXT_MUTED = "#64748B"    # Gris azulado tenue

COLOR_SUCCESS = "#10B981"       # Verde Esmeralda (Cobrado/En Stock)
COLOR_WARNING = "#F59E0B"       # Ámbar Alerta (72 días crédito pronto / Re-cotizar)
COLOR_DANGER = "#EF4444"        # Rojo Error (Vencido / Agotado)

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
