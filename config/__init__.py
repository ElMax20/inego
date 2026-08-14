import os
import importlib.util

# Re-exportar configuraciones desde config.py para compatibilidad entre archivo config.py y paquete config/
config_py_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config.py")
if os.path.exists(config_py_path):
    spec = importlib.util.spec_from_file_location("_config_py", config_py_path)
    _mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(_mod)
    for _k, _v in _mod.__dict__.items():
        if not _k.startswith("__"):
            globals()[_k] = _v
