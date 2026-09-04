import sys
import os
from PySide6.QtWidgets import QApplication, QSplashScreen
from PySide6.QtGui import QPixmap, QIcon, QFont, QColor
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl, Qt

if getattr(sys, 'frozen', False):
    BASE_DIR = sys._MEIPASS
    try:
        import pyi_splash
    except ImportError:
        pyi_splash = None
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    pyi_splash = None

sys.path.append(BASE_DIR)

from qml_bridge import BackendBridge
from reportes_controller import ReportesController
from config import COMPANY_NAME

def main():
    app = QApplication(sys.argv)
    app.setOrganizationName("InegoIndustrias")
    app.setApplicationName(f"{COMPANY_NAME} QML System")

    logo_path = os.path.join(BASE_DIR, "logo.png")
    if os.path.exists(logo_path):
        app.setWindowIcon(QIcon(logo_path))

    # 1. Pestaña de Carga (QSplashScreen) con el Árbol de la Vida
    splash = None
    if os.path.exists(logo_path):
        pixmap = QPixmap(logo_path).scaled(340, 340, Qt.KeepAspectRatio, Qt.SmoothTransformation)
        splash = QSplashScreen(pixmap, Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint)
        splash.setFont(QFont("Calibri", 11, QFont.Bold))
        splash.showMessage(
            f"   Iniciando {COMPANY_NAME}...\n   Cargando módulos y base de datos...",
            Qt.AlignBottom | Qt.AlignLeft,
            QColor("#0F172A")
        )
        splash.show()
        app.processEvents()

    if pyi_splash and pyi_splash.is_alive():
        pyi_splash.update_text("Cargando módulos QML...")
        pyi_splash.close()

    engine = QQmlApplicationEngine()

    # 2. Registrar el puente Backend general Python-QML
    bridge = BackendBridge()
    engine.rootContext().setContextProperty("backend", bridge)

    # 3. Registrar el controlador de Reportes
    reportes_controller = ReportesController()
    engine.rootContext().setContextProperty("reportesController", reportes_controller)

    qml_file = os.path.join(BASE_DIR, "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        if splash:
            splash.close()
        sys.exit(-1)

    # 4. Cerrar la pestaña de carga cuando la aplicación principal esté lista
    if splash:
        splash.close()

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
