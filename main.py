import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)

from qml_bridge import BackendBridge
from reportes_controller import ReportesController
from config import COMPANY_NAME

def main():
    app = QGuiApplication(sys.argv)
    app.setOrganizationName("InegoIndustrias")
    app.setApplicationName(f"{COMPANY_NAME} QML System")

    engine = QQmlApplicationEngine()

    # 1. Registrar el puente Backend general Python-QML
    bridge = BackendBridge()
    engine.rootContext().setContextProperty("backend", bridge)

    # 2. Registrar el controlador de Reportes y Exportación a Excel (RF5.1 - RF5.4)
    reportes_controller = ReportesController()
    engine.rootContext().setContextProperty("reportesController", reportes_controller)

    qml_file = os.path.join(BASE_DIR, "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
