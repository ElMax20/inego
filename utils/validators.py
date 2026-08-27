import re

def validate_email(email):
    """ Valida que el correo electrónico siga la estructura universal: usuario@dominio.extension """
    if not email or not isinstance(email, str):
        return False, "El correo electrónico es obligatorio."
    
    email_clean = email.strip().lower()
    pattern = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
    if not re.match(pattern, email_clean):
        return False, "🚫 Formato de correo electrónico inválido: Debe cumplir con la estructura universal (ej. usuario@dominio.com)."
        
    return True, ""

def validate_phone(phone):
    """ Valida que el teléfono contenga únicamente dígitos numéricos y tenga 9 o 10 dígitos """
    if not phone:
        return False, "El número de teléfono es obligatorio."
    phone_clean = phone.strip()
    if not (len(phone_clean) in (9, 10) and phone_clean.isdigit()):
        return False, "🚫 Teléfono no válido: El número de teléfono debe contener entre 9 y 10 dígitos numéricos (ej. 0991234567 o 042123456)."
    return True, ""

def validate_cedula(cedula):
    """ Valida que la cédula contenga exactamente 10 dígitos numéricos """
    if not cedula:
        return False, "La cédula es obligatoria."
    ced_clean = cedula.strip()
    if not (len(ced_clean) == 10 and ced_clean.isdigit()):
        return False, "La cédula debe contener exactamente 10 dígitos numéricos."
    return True, ""

def validate_ruc(ruc):
    """ Valida que el RUC contenga máximo 13 dígitos numéricos y que los dos primeros correspondan a un código de provincia (01-24) o especial 30 """
    if not ruc:
        return False, "El RUC es obligatorio."
    
    ruc_clean = ruc.strip()
    if not ruc_clean.isdigit():
        return False, "El RUC debe contener únicamente dígitos numéricos."
    
    if len(ruc_clean) > 13 or len(ruc_clean) < 10:
        return False, "El RUC debe contener entre 10 y 13 dígitos numéricos."
    
    prov_code = ruc_clean[:2]
    valid_codes = [f"{i:02d}" for i in range(1, 25)] + ["30"]
    
    if prov_code not in valid_codes:
        return False, f"🚫 RUC no válido: Los dos primeros dígitos ('{prov_code}') deben corresponder a un código de provincia válido en Ecuador (01 al 24) o al código especial (30)."
    
    return True, ""

def validate_required_fields(fields_dict):
    """ Valida que ningún campo obligatorio esté vacío """
    for field_name, value in fields_dict.items():
        if value is None or (isinstance(value, str) and not value.strip()):
            return False, f"El campo '{field_name}' es obligatorio y no puede estar vacío."
    return True, ""
