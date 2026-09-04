import os
import sys
import importlib.util

# 1. Definir o importar dinámicamente desde config.py
if getattr(sys, 'frozen', False):
    root_dir = sys._MEIPASS
else:
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

config_py_path = os.path.join(root_dir, "config.py")
if os.path.exists(config_py_path):
    spec = importlib.util.spec_from_file_location("_config_py", config_py_path)
    _mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(_mod)
    for _k, _v in _mod.__dict__.items():
        if not _k.startswith("__"):
            globals()[_k] = _v

# 2. Definiciones explícitas de respaldo para garantizar exportación segura bajo PyInstaller
COMPANY_NAME = globals().get("COMPANY_NAME", "Inego Industrias")
COMPANY_SLOGAN = globals().get("COMPANY_SLOGAN", "Ferretería, Equipos, Suministros de Oficina y Producción")
COMPANY_LOCATION = globals().get("COMPANY_LOCATION", "Guayaquil, Ecuador")
COMPANY_LOGO_TITLE = globals().get("COMPANY_LOGO_TITLE", "Árbol de la Vida")

BASE_DIR = globals().get("BASE_DIR", root_dir)
DATA_DIR = globals().get("DATA_DIR", os.path.join(root_dir, "data"))
SQLITE_DB_PATH = globals().get("SQLITE_DB_PATH", os.path.join(DATA_DIR, "inego_industrias.db"))

MYSQL_CONFIG = globals().get("MYSQL_CONFIG", {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "",
    "database": "inego_industrias_db"
})

B2B_CREDIT_DAYS = globals().get("B2B_CREDIT_DAYS", 72)
PARTNER_FIXED_PAY = globals().get("PARTNER_FIXED_PAY", 50.00)
PARTNER_BONUS_PERCENT = globals().get("PARTNER_BONUS_PERCENT", 0.05)
PARTNERS = globals().get("PARTNERS", ["Socio 1 - Administrador de Dinero", "Socio 2 - Compras y Mercadería", "Socio 3 - Proceso Contable"])
