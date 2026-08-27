import sys
import os

print("[VERIFICACION] Probando nuevos requerimientos y validaciones...")

from utils.validators import validate_email, validate_phone, validate_cedula, validate_ruc, validate_required_fields

# 1. Prueba de validación de correo
ok_g, _ = validate_email("usuario@gmail.com")
ok_h, _ = validate_email("socio@hotmail.com")
ok_bad, msg_bad = validate_email("usuario_invalido_sin_arrobaydominio")
print(f"[VALIDADOR EMAIL] Gmail: {ok_g} | Hotmail: {ok_h} | Invalid: {not ok_bad}")
assert ok_g and ok_h and not ok_bad

# 2. Prueba de validación de teléfono (10 dígitos)
ok_p10, _ = validate_phone("0991234567")
ok_p8, msg_p8 = validate_phone("09912345")
print(f"[VALIDADOR TELEFONO] 10 digitos: {ok_p10} | 8 digitos: {not ok_p8}")
assert ok_p10 and not ok_p8

# 3. Prueba de validación de cédula (10 dígitos) y RUC (13 dígitos) con Algoritmo Oficial
ok_c10, _ = validate_cedula("1713175071")
ok_c_bad, _ = validate_cedula("1713175079")
print(f"[VALIDADOR CEDULA] 1713175071 Valida: {ok_c10} | 1713175079 Invalida: {not ok_c_bad}")
assert ok_c10 and not ok_c_bad

ok_r13, _ = validate_ruc("1713175071001")
ok_r_bad, _ = validate_ruc("1713175079001")
print(f"[VALIDADOR RUC] 1713175071001 Valido: {ok_r13} | 1713175079001 Invalido: {not ok_r_bad}")
assert ok_r13 and not ok_r_bad

# 4. Prueba de campos obligatorios
ok_req, _ = validate_required_fields({"Campo1": "Valor", "Campo2": "  "})
print(f"[VALIDADOR OBLIGATORIO] Bloquea espacio vacio: {not ok_req}")
assert not ok_req

print("\n[TODAS LAS PRUEBAS AUTOMATIZADAS PASARON 100% EXITOSAMENTE]")
