"""
utils/retenciones_sri.py

Motor de Retenciones Tributarias del Servicio de Rentas Internas (SRI) del Ecuador
para INEGO Industrias.

Implementa la jerarquía de sujetos pasivos, reglas de exención y tarifas de retención 
del Impuesto a la Renta (IR) y del Impuesto al Valor Agregado (IVA).
"""

def calcular_retencion_sri(
    ruc_cedula: str,
    subtotal: float,
    iva: float,
    regimen_tributario: str = "Régimen General",
    tipo_transaccion: str = "Bienes",
    es_contribuyente_especial: bool = False
) -> dict:
    """
    Calcula las retenciones oficiales del SRI Ecuador.

    Parámetros:
        ruc_cedula: Número de RUC (13 dígitos) o Cédula (10 dígitos)
        subtotal: Monto imponible de la venta/servicio (antes de IVA)
        iva: Monto del IVA (15%)
        regimen_tributario: 'Régimen General', 'RIMPE Emprendedor', 'RIMPE Negocio Popular', 'Contribuyente Especial', 'Entidad Pública'
        tipo_transaccion: 'Bienes', 'Servicios Mano Obra', 'Servicios Profesionales', 'Docencia', 'Arrendamiento'
        es_contribuyente_especial: Boolean que indica si el cliente es Contribuyente Especial
    """
    doc = str(ruc_cedula or '').strip()
    subtotal = float(subtotal or 0.0)
    iva = float(iva or 0.0)
    total_facturado = round(subtotal + iva, 2)

    # 1. Cédula (10 dígitos) o Consumidor Final -> NO aplica retenciones (0% IR, 0% IVA)
    is_ruc = len(doc) == 13 and doc.isdigit()
    if not is_ruc:
        return {
            'is_ruc': False,
            'aplica': False,
            'aplica_txt': "No (Cédula 10 dígitos / Consumidor Final)",
            'regimen': "Persona Natural (Cédula)",
            'porcentaje_ir': 0.0,
            'retencion_ir': 0.0,
            'porcentaje_iva': 0.0,
            'retencion_iva': 0.0,
            'total_retenciones': 0.0,
            'total_facturado': total_facturado,
            'neto_cobrar': total_facturado
        }

    regimen_norm = (regimen_tributario or "Régimen General").strip()

    # 2. Instituciones del Estado / Entidades Públicas -> NO se les retiene (0%)
    if regimen_norm in ["Entidad Pública", "Institución del Estado"]:
        return {
            'is_ruc': True,
            'aplica': False,
            'aplica_txt': "No (Entidad Pública del Estado)",
            'regimen': "Entidad Pública",
            'porcentaje_ir': 0.0,
            'retencion_ir': 0.0,
            'porcentaje_iva': 0.0,
            'retencion_iva': 0.0,
            'total_retenciones': 0.0,
            'total_facturado': total_facturado,
            'neto_cobrar': total_facturado
        }

    # 3. RIMPE Negocio Popular -> 0% IR y 0% IVA (Notas de Venta)
    if regimen_norm == "RIMPE Negocio Popular":
        return {
            'is_ruc': True,
            'aplica': False,
            'aplica_txt': "No (RIMPE Negocio Popular - 0%)",
            'regimen': "RIMPE Negocio Popular",
            'porcentaje_ir': 0.0,
            'retencion_ir': 0.0,
            'porcentaje_iva': 0.0,
            'retencion_iva': 0.0,
            'total_retenciones': 0.0,
            'total_facturado': total_facturado,
            'neto_cobrar': total_facturado
        }

    # 4. RIMPE Emprendedor -> 1% IR (Bienes y Servicios) y 0% IVA
    if regimen_norm == "RIMPE Emprendedor":
        pct_ir = 0.01
        ret_ir = round(subtotal * pct_ir, 2)
        ret_iva = 0.0
        tot_ret = round(ret_ir + ret_iva, 2)
        return {
            'is_ruc': True,
            'aplica': True,
            'aplica_txt': "Sí (RIMPE Emprendedor: 1% IR | 0% IVA)",
            'regimen': "RIMPE Emprendedor",
            'porcentaje_ir': 1.0,
            'retencion_ir': ret_ir,
            'porcentaje_iva': 0.0,
            'retencion_iva': 0.0,
            'total_retenciones': tot_ret,
            'total_facturado': total_facturado,
            'neto_cobrar': round(total_facturado - tot_ret, 2)
        }

    # 5. Contribuyentes Especiales -> Retención IR según actividad, 0% IVA entre especiales/jerarquía
    if es_contribuyente_especial or regimen_norm == "Contribuyente Especial":
        tipo_t = (tipo_transaccion or "Bienes").strip()
        if tipo_t == "Bienes":
            pct_ir = 0.0175
        elif tipo_t in ["Servicios Mano Obra", "Servicios"]:
            pct_ir = 0.0275
        elif tipo_t == "Servicios Profesionales":
            pct_ir = 0.10
        else:
            pct_ir = 0.0175

        ret_ir = round(subtotal * pct_ir, 2)
        ret_iva = 0.0
        tot_ret = round(ret_ir + ret_iva, 2)
        return {
            'is_ruc': True,
            'aplica': True,
            'aplica_txt': f"Sí (Contribuyente Especial: {pct_ir*100:.2f}% IR | 0% IVA)",
            'regimen': "Contribuyente Especial",
            'porcentaje_ir': round(pct_ir * 100, 2),
            'retencion_ir': ret_ir,
            'porcentaje_iva': 0.0,
            'retencion_iva': 0.0,
            'total_retenciones': tot_ret,
            'total_facturado': total_facturado,
            'neto_cobrar': round(total_facturado - tot_ret, 2)
        }

    # 6. Régimen General (Sociedades y Personas Naturales con RUC)
    tipo_t = (tipo_transaccion or "Bienes").strip()
    if tipo_t == "Bienes":
        pct_ir = 0.0175   # 1.75% Bienes muebles corporales
        pct_iva = 0.30    # 30% IVA
        lbl_tipo = "RUC 1.75% IR | 30% IVA"
    elif tipo_t in ["Servicios Mano Obra", "Servicios"]:
        pct_ir = 0.0275   # 2.75% Mano de obra / transporte
        pct_iva = 0.70    # 70% IVA
        lbl_tipo = "RUC 2.75% IR | 70% IVA"
    elif tipo_t == "Servicios Profesionales":
        pct_ir = 0.10     # 10% Honorarios profesionales
        pct_iva = 1.00    # 100% IVA
        lbl_tipo = "RUC 10% IR | 100% IVA"
    elif tipo_t == "Docencia":
        pct_ir = 0.08     # 8% Docencia/Capacitación
        pct_iva = 0.70    # 70% IVA
        lbl_tipo = "RUC 8% IR | 70% IVA"
    elif tipo_t == "Arrendamiento":
        pct_ir = 0.08     # 8% Arrendamiento persona natural
        pct_iva = 1.00    # 100% IVA
        lbl_tipo = "RUC 8% IR | 100% IVA"
    else:
        pct_ir = 0.0175
        pct_iva = 0.30
        lbl_tipo = "RUC 1.75% IR | 30% IVA"

    ret_ir = round(subtotal * pct_ir, 2)
    ret_iva = round(iva * pct_iva, 2)
    tot_ret = round(ret_ir + ret_iva, 2)

    return {
        'is_ruc': True,
        'aplica': True,
        'aplica_txt': f"Sí ({lbl_tipo})",
        'regimen': "Régimen General",
        'porcentaje_ir': round(pct_ir * 100, 2),
        'retencion_ir': ret_ir,
        'porcentaje_iva': round(pct_iva * 100, 2),
        'retencion_iva': ret_iva,
        'total_retenciones': tot_ret,
        'total_facturado': total_facturado,
        'neto_cobrar': round(total_facturado - tot_ret, 2)
    }
