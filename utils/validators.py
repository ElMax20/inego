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

def normalize_tildes(text):
    """
    Convierte automáticamente cualquier tilde grave o chueca (à, è, ì, ò, ù, À, È, Ì, Ò, Ù)
    en su respectiva tilde normal aguda (á, é, í, ó, ú, Á, É, Í, Ó, Ú).
    """
    if not text or not isinstance(text, str):
        return text
    replacements = {
        'à': 'á', 'è': 'é', 'ì': 'í', 'ò': 'ó', 'ù': 'ú',
        'À': 'Á', 'È': 'É', 'Ì': 'Í', 'Ò': 'Ó', 'Ù': 'Ú'
    }
    for bad_char, good_char in replacements.items():
        text = text.replace(bad_char, good_char)
    return text

def validate_phone(phone):
    """ Valida que el teléfono contenga únicamente dígitos numéricos y tenga exactamente 10 dígitos (incluyendo el 0 inicial) """
    if not phone:
        return False, "⚠️ El número de teléfono es obligatorio."
    phone_clean = phone.strip()
    if not (len(phone_clean) == 10 and phone_clean.isdigit()):
        return False, "⚠️ Número de teléfono no válido: Debe contener exactamente 10 dígitos numéricos (incluyendo el 0 inicial, ej. 0991234567 o 0421234567)."
    return True, ""

def validate_cedula(cedula):
    """
    Algoritmo oficial de verificación interna de Cédula de Identidad en Ecuador (Módulo 10).
    1. Longitud de 10 dígitos numéricos.
    2. Provincia (dos primeros dígitos): 01-24 o 30.
    3. Tercer dígito < 6 (0 a 5 para personas naturales).
    4. Multiplicadores alternados: 2, 1, 2, 1, 2, 1, 2, 1, 2. Si producto > 9, restar 9.
    5. Suma total y residuo % 10. Dígito verificador = (10 - residuo) % 10.
    6. Comparación contra el décimo dígito.
    """
    if not cedula or not isinstance(cedula, str):
        return False, "🚫 La cédula es obligatoria."
    
    ced = cedula.strip()
    if not ced.isdigit():
        return False, "🚫 La cédula debe contener únicamente dígitos numéricos."
    
    if len(ced) != 10:
        return False, f"🚫 Cédula no válida: Debe tener exactamente 10 dígitos numéricos (obtenidos {len(ced)})."
    
    prov = int(ced[:2])
    if not (1 <= prov <= 24 or prov == 30):
        return False, f"🚫 Cédula no válida: El código de provincia '{ced[:2]}' debe estar entre 01 y 24 (o 30)."
    
    third_digit = int(ced[2])
    if third_digit >= 6:
        return False, f"🚫 Cédula no válida: El tercer dígito para personas naturales debe ser menor a 6 (obtenido '{third_digit}')."
    
    coefs = [2, 1, 2, 1, 2, 1, 2, 1, 2]
    total_sum = 0
    for i in range(9):
        val = int(ced[i]) * coefs[i]
        if val > 9:
            val -= 9
        total_sum += val
    
    residue = total_sum % 10
    expected_verifier = 0 if residue == 0 else (10 - residue)
    actual_verifier = int(ced[9])
    
    if expected_verifier != actual_verifier:
        return False, "🚫 Cédula no válida: El dígito verificador es incorrecto."
    
    return True, ""

def validate_ruc(ruc):
    """
    Algoritmo oficial de verificación interna de RUC en Ecuador (13 dígitos).
    - Caso 1: Persona Natural (Tercer dígito 0 a 5) -> Módulo 10 sobre los primeros 10 dígitos + establecimiento != '000'.
    - Caso 2: Sociedad Privada (Tercer dígito == 9) -> Módulo 11 (coeficientes 4,3,2,7,6,5,4,3,2) + establecimiento != '000'.
    - Caso 3: Entidad Pública (Tercer dígito == 6) -> Módulo 11 (coeficientes 3,2,7,6,5,4,3,2 sobre 8 dígitos) + verificador en 9no dígito + establecimiento != '0000'.
    """
    if not ruc or not isinstance(ruc, str):
        return False, "🚫 El RUC es obligatorio."
    
    clean_ruc = ruc.strip()
    if not clean_ruc.isdigit():
        return False, "🚫 El RUC debe contener únicamente dígitos numéricos."
    
    if len(clean_ruc) != 13:
        return False, f"🚫 RUC no válido: Debe contener exactamente 13 dígitos numéricos (obtenidos {len(clean_ruc)})."
    
    prov = int(clean_ruc[:2])
    if not (1 <= prov <= 24 or prov == 30):
        return False, f"🚫 RUC no válido: El código de provincia '{clean_ruc[:2]}' debe estar entre 01 y 24 (o 30)."
    
    third_digit = int(clean_ruc[2])
    
    # Caso 1: Persona Natural (Tercer dígito 0 a 5)
    if 0 <= third_digit <= 5:
        if clean_ruc.endswith("000"):
            return False, "🚫 RUC no válido: El establecimiento del RUC de Persona Natural no puede ser '000'."
        
        cedula_part = clean_ruc[:10]
        ok_ced, msg_ced = validate_cedula(cedula_part)
        if not ok_ced:
            return False, f"🚫 RUC no válido (Persona Natural): {msg_ced}"
        return True, ""

    # Caso 2: Sociedad Privada / Extranjera (Tercer dígito == 9)
    elif third_digit == 9:
        if clean_ruc.endswith("000"):
            return False, "🚫 RUC no válido: El establecimiento de Sociedad Privada no puede ser '000'."
        
        coefs = [4, 3, 2, 7, 6, 5, 4, 3, 2]
        total_sum = 0
        for i in range(9):
            total_sum += int(clean_ruc[i]) * coefs[i]
        
        residue = total_sum % 11
        if residue == 0:
            expected_verifier = 0
        elif residue == 1:
            return False, "🚫 RUC no válido: Estructura de código Módulo 11 no válida (residuo 1)."
        else:
            expected_verifier = 11 - residue
        
        actual_verifier = int(clean_ruc[9])
        if expected_verifier != actual_verifier:
            return False, "🚫 RUC no válido (Sociedad Privada): Dígito verificador incorrecto."
        return True, ""

    # Caso 3: Entidad Pública (Tercer dígito == 6)
    elif third_digit == 6:
        if clean_ruc.endswith("0000"):
            return False, "🚫 RUC no válido: El establecimiento de Entidad Pública no puede ser '0000'."
        
        coefs = [3, 2, 7, 6, 5, 4, 3, 2]
        total_sum = 0
        for i in range(8):
            total_sum += int(clean_ruc[i]) * coefs[i]
        
        residue = total_sum % 11
        if residue == 0:
            expected_verifier = 0
        elif residue == 1:
            return False, "🚫 RUC no válido: Estructura de código Módulo 11 no válida (residuo 1)."
        else:
            expected_verifier = 11 - residue
        
        actual_verifier = int(clean_ruc[8]) # En Entidades Públicas, el verificador es el 9no dígito
        if expected_verifier != actual_verifier:
            return False, "🚫 RUC no válido (Entidad Pública): Dígito verificador incorrecto."
        return True, ""

    else:
        return False, f"🚫 RUC no válido: El tercer dígito ('{third_digit}') debe ser Persona Natural (0-5), Pública (6) o Privada (9)."

def validate_cedula_or_ruc(identificacion):
    """
    Valida internamente cualquier identificación ecuatoriana (Cédula de 10 dígitos o RUC de 13 dígitos).
    """
    if not identificacion or not isinstance(identificacion, str):
        return False, "🚫 La identificación (Cédula o RUC) es obligatoria."
    
    clean_id = identificacion.strip()
    if len(clean_id) == 10:
        return validate_cedula(clean_id)
    elif len(clean_id) == 13:
        return validate_ruc(clean_id)
    else:
        return False, f"🚫 Identificación no válida: Debe tener exactamente 10 dígitos (Cédula) o 13 dígitos (RUC)."

def validate_required_fields(fields_dict):
    """ Valida que ningún campo obligatorio esté vacío """
    for field_name, value in fields_dict.items():
        if value is None or (isinstance(value, str) and not value.strip()):
            return False, f"El campo '{field_name}' es obligatorio y no puede estar vacío."
    return True, ""
