import re

def validate_email(email):
    """ Valida que el correo sea de dominios populares conocidos (@gmail.com, @hotmail.com, @outlook.com, @yahoo.com, @live.com, @icloud.com, @inego.com) """
    if not email or not isinstance(email, str):
        return False, "El correo electrónico es obligatorio."
    
    email_clean = email.strip().lower()
    allowed_domains = ("@gmail.com", "@hotmail.com", "@outlook.com", "@yahoo.com", "@live.com", "@icloud.com", "@inego.com", "@gmail.es", "@hotmail.es")
    
    if not any(email_clean.endswith(domain) for domain in allowed_domains):
        return False, "🚫 Correo electrónico no permitido: Debe utilizar un dominio conocido (@gmail.com, @hotmail.com, @outlook.com, @yahoo.com, @live.com, @icloud.com, @inego.com)."
    
    if not re.match(r"^[^@]+@[^@]+\.[^@]+$", email_clean):
        return False, "Formato de correo electrónico inválido."
        
    return True, ""

def validate_phone(phone):
    """ Valida que el teléfono contenga exactamente 10 dígitos numéricos """
    if not phone:
        return False, "El número de teléfono es obligatorio."
    phone_clean = phone.strip()
    if not (len(phone_clean) == 10 and phone_clean.isdigit()):
        return False, "🚫 Teléfono no válido: El número de teléfono del contacto debe contener exactamente 10 dígitos numéricos (ej. 0991234567)."
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
