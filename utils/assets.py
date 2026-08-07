import os
import shutil
from PIL import Image
from config import DATA_DIR

SOURCE_LOGO_PATH = r"C:\Users\AlumnosMTP.MTP02-25\.gemini\antigravity\brain\3f9183c6-436a-40d4-9d67-411c782f67db\arbol_de_la_vida_1786117869880.png"
TARGET_LOGO_PATH = os.path.join(DATA_DIR, "logo_arbol_vida.png")

def sync_logo():
    if os.path.exists(SOURCE_LOGO_PATH):
        try:
            shutil.copy2(SOURCE_LOGO_PATH, TARGET_LOGO_PATH)
        except Exception:
            pass
    return TARGET_LOGO_PATH

def generate_tree_of_life_image(width=120, height=120):
    logo_path = sync_logo()
    if os.path.exists(logo_path):
        try:
            img = Image.open(logo_path).convert("RGBA")
            img = img.resize((width, height), Image.Resampling.LANCZOS)
            return img
        except Exception as e:
            print(f"[ASSETS ERROR] Error al cargar logo: {e}")

    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    return img

def get_logo_file_path():
    return sync_logo()
