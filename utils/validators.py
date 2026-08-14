import re

def validate_email(email):
    """ Valida que el correo termine en @gmail.com, @hotmail.com, @gmail.es, @hotmail.es o @inego.com """
    if not email or not isinstance(email, str):
        return False, "El correo electrónico es obligatorio."
    
    email_clean = email.strip().lower()
    allowed_domains = ("@gmail.com", "@hotmail.com", "@gmail.es", "@hotmail.es", "@inego.com")
    
    if not any(email_clean.endswith(domain) for domain in allowed_domains):
        return False, "El correo debe terminar en @gmail.com, @hotmail.com o pertenecer al dominio corporativo (@inego.com)."
    
    if not re.match(r"^[^@]+@[^@]+\.[^@]+$", email_clean):
        return False, "Formato de correo electrónico inválido."
        
    return True, ""

def validate_phone(phone):
    """ Valida que el teléfono contenga exactamente 10 dígitos numéricos """
    if not phone:
        return False, "El número de teléfono es obligatorio."
    phone_clean = phone.strip()
    if not (len(phone_clean) == 10 and phone_clean.isdigit()):
        return False, "El teléfono debe contener exactamente 10 dígitos numéricos (ej. 0991234567)."
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
    """ Valida que el RUC contenga exactamente 13 dígitos numéricos """
    if not ruc:
        return False, "El RUC es obligatorio."
    ruc_clean = ruc.strip()
    if not (len(ruc_clean) == 13 and ruc_clean.isdigit()):
        return False, "El RUC debe contener exactamente 13 dígitos numéricos."
    return True, ""

def validate_required_fields(fields_dict):
    """ Valida que ningún campo obligatorio esté vacío """
    for field_name, value in fields_dict.items():
        if value is None or (isinstance(value, str) and not value.strip()):
            return False, f"El campo '{field_name}' es obligatorio y no puede estar vacío."
    return True, ""
