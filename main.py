import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)

from qml_bridge import BackendBridge
from config import COMPANY_NAME

def main():
    app = QGuiApplication(sys.argv)
    app.setOrganizationName("InegoIndustrias")
    app.setApplicationName(f"{COMPANY_NAME} QML System")

    engine = QQmlApplicationEngine()

    # Registrar el puente Backend Python-QML
    bridge = BackendBridge()
    engine.rootContext().setContextProperty("backend", bridge)

    qml_file = os.path.join(BASE_DIR, "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
