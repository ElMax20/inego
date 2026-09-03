import sys
import os

# Ejecución silenciosa sin consola CMD
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from main import InegoApp

if __name__ == "__main__":
    app = InegoApp()
    app.mainloop()
