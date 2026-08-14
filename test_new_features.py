import sys
import os

print("[VERIFICACION] Probando nuevos requerimientos y validaciones...")

from utils.validators import validate_email, validate_phone, validate_cedula, validate_ruc, validate_required_fields

# 1. Prueba de validación de correo
ok_g, _ = validate_email("usuario@gmail.com")
ok_h, _ = validate_email("socio@hotmail.com")
ok_bad, msg_bad = validate_email("usuario@yahoo.com")
print(f"[VALIDADOR EMAIL] Gmail: {ok_g} | Hotmail: {ok_h} | Invalid Yahoo: {not ok_bad} (Mensaje: {msg_bad})")
assert ok_g and ok_h and not ok_bad

# 2. Prueba de validación de teléfono (10 dígitos)
ok_p10, _ = validate_phone("0991234567")
ok_p8, msg_p8 = validate_phone("09912345")
print(f"[VALIDADOR TELEFONO] 10 digitos: {ok_p10} | 8 digitos: {not ok_p8} (Mensaje: {msg_p8})")
assert ok_p10 and not ok_p8

# 3. Prueba de validación de cédula (10 dígitos) y RUC (13 dígitos)
ok_c10, _ = validate_cedula("0912345678")
ok_c9, _ = validate_cedula("091234567")
print(f"[VALIDADOR CEDULA] 10 digitos: {ok_c10} | 9 digitos: {not ok_c9}")
assert ok_c10 and not ok_c9

ok_r13, _ = validate_ruc("0991234567001")
ok_r10, _ = validate_ruc("0991234567")
print(f"[VALIDADOR RUC] 13 digitos: {ok_r13} | 10 digitos: {not ok_r10}")
assert ok_r13 and not ok_r10

# 4. Prueba de campos obligatorios
ok_req, _ = validate_required_fields({"Campo1": "Valor", "Campo2": "  "})
print(f"[VALIDADOR OBLIGATORIO] Bloquea espacio vacio: {not ok_req}")
assert not ok_req

print("\n[TODAS LAS PRUEBAS AUTOMATIZADAS PASARON 100% EXITOSAMENTE]")
