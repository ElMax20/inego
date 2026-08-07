import os
from datetime import datetime
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from database.connection import db
from utils.assets import get_logo_file_path
from config import DATA_DIR, COMPANY_NAME, COMPANY_SLOGAN, COMPANY_LOCATION

def generate_quote_pdf(quote_id, output_path=None):
    quote = db.fetch_one("""
        SELECT c.*, cl.razon_social_nombre, cl.ruc_cedula, cl.telefono, cl.email, cl.direccion, cl.tipo_cliente, cl.dias_credito
        FROM cotizaciones c
        JOIN clientes cl ON c.cliente_id = cl.id
        WHERE c.id = %s
    """, (quote_id,))

    if not quote:
        return None

    items = db.fetch_all("""
        SELECT cd.*, p.nombre as producto_nombre, p.codigo as producto_codigo
        FROM cotizacion_detalles cd
        JOIN productos p ON cd.producto_id = p.id
        WHERE cd.cotizacion_id = %s
    """, (quote_id,))

    if not output_path:
        filename = f"Cotizacion_{quote['numero_cotizacion']}.pdf"
        output_path = os.path.join(DATA_DIR, filename)

    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36
    )

    styles = getSampleStyleSheet()
    primary_color = colors.HexColor("#0A192F")
    royal_blue = colors.HexColor("#1E3E7A")
    cyan_accent = colors.HexColor("#0284C7")

    title_style = ParagraphStyle('TitleStyle', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=18, textColor=primary_color)
    subtitle_style = ParagraphStyle('SubTitleStyle', parent=styles['Normal'], fontName='Helvetica', fontSize=9, textColor=colors.HexColor("#64748B"))
    header_style = ParagraphStyle('HeaderStyle', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=12, textColor=royal_blue)
    normal_style = ParagraphStyle('NormalStyle', parent=styles['Normal'], fontName='Helvetica', fontSize=9, textColor=colors.HexColor("#1E293B"))

    story = []

    logo_file = get_logo_file_path()
    logo_img = Image(logo_file, width=60, height=60)
    
    header_text = Paragraph(f"<b>{COMPANY_NAME.upper()}</b><br/>{COMPANY_SLOGAN}<br/>{COMPANY_LOCATION} | Guayaquil, Ecuador", normal_style)
    doc_info = Paragraph(f"<b>COTIZACIÓN N°:</b> {quote['numero_cotizacion']}<br/><b>Fecha:</b> {quote['fecha_emision']}<br/><b>Validez:</b> {quote['fecha_vencimiento'] or '30 días'}", normal_style)

    header_table = Table([[logo_img, header_text, doc_info]], colWidths=[70, 310, 160])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ALIGN', (2,0), (2,0), 'RIGHT'),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=2, color=cyan_accent, spaceBefore=5, spaceAfter=15))

    credito_txt = "<b>CRÉDITO 72 DÍAS (B2B)</b>" if quote['tipo_cliente'] == 'B2B' else "<b>CONTADO / PAGO INMEDIATO (B2C)</b>"
    
    client_data = [
        [Paragraph(f"<b>CLIENTE:</b> {quote['razon_social_nombre']}", normal_style), Paragraph(f"<b>RUC/CÉDULA:</b> {quote['ruc_cedula'] or 'N/A'}", normal_style)],
        [Paragraph(f"<b>TELÉFONO:</b> {quote['telefono'] or 'N/A'}", normal_style), Paragraph(f"<b>EMAIL:</b> {quote['email'] or 'N/A'}", normal_style)],
        [Paragraph(f"<b>DIRECCIÓN:</b> {quote['direccion'] or 'Guayaquil'}", normal_style), Paragraph(f"<b>CONDICIÓN DE PAGO:</b> {credito_txt}", normal_style)],
    ]
    client_table = Table(client_data, colWidths=[270, 270])
    client_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#E2E8F0")),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(client_table)
    story.append(Spacer(1, 15))

    table_headers = [Paragraph("<b>Cód</b>", header_style), Paragraph("<b>Descripción del Producto</b>", header_style), Paragraph("<b>Cant.</b>", header_style), Paragraph("<b>P. Unit USD</b>", header_style), Paragraph("<b>Total USD</b>", header_style)]
    table_data = [table_headers]

    for item in items:
        table_data.append([
            Paragraph(item['producto_codigo'], normal_style),
            Paragraph(item['producto_nombre'], normal_style),
            Paragraph(str(item['cantidad']), normal_style),
            Paragraph(f"${float(item['precio_venta_unitario']):,.2f}", normal_style),
            Paragraph(f"${float(item['subtotal_linea']):,.2f}", normal_style),
        ])

    items_table = Table(table_data, colWidths=[60, 260, 50, 85, 85])
    items_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#E0F2FE")),
        ('ALIGN', (2,0), (-1,-1), 'RIGHT'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(items_table)
    story.append(Spacer(1, 15))

    subtotal = float(quote['subtotal'])
    iva = float(quote['iva'])
    total = float(quote['total'])

    totales_data = [
        ["", Paragraph("<b>SUBTOTAL:</b>", normal_style), Paragraph(f"${subtotal:,.2f}", normal_style)],
        ["", Paragraph("<b>IVA (15%):</b>", normal_style), Paragraph(f"${iva:,.2f}", normal_style)],
        ["", Paragraph("<b>TOTAL USD:</b>", title_style), Paragraph(f"<b>${total:,.2f}</b>", title_style)],
    ]
    totales_table = Table(totales_data, colWidths=[300, 120, 120])
    totales_table.setStyle(TableStyle([
        ('ALIGN', (1,0), (-1,-1), 'RIGHT'),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(totales_table)
    story.append(Spacer(1, 20))

    nota_p = Paragraph(f"<b>Nota de Términos:</b> Para clientes B2B se otorgan 72 días de plazo de crédito. Las cotizaciones para contratos con el Gobierno están exentas de re-cotización durante el periodo de validez. Gracias por confiar en Inego Industrias.", subtitle_style)
    story.append(nota_p)

    doc.build(story)
    return output_path


def generate_payslip_pdf(payroll_id, output_path=None):
    r = db.fetch_one("SELECT * FROM roles_pago WHERE id = %s", (payroll_id,))
    if not r:
        return None

    if not output_path:
        filename = f"Rol_Pago_{r['socio_nombre'].replace(' ', '_')}_{r['periodo_mes_anio']}.pdf"
        output_path = os.path.join(DATA_DIR, filename)

    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36
    )

    styles = getSampleStyleSheet()
    primary_color = colors.HexColor("#0A192F")
    royal_blue = colors.HexColor("#1E3E7A")
    normal_style = ParagraphStyle('NormalStyle', parent=styles['Normal'], fontName='Helvetica', fontSize=10, textColor=colors.HexColor("#1E293B"))
    title_style = ParagraphStyle('TitleStyle', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=16, textColor=primary_color)

    story = []

    logo_file = get_logo_file_path()
    logo_img = Image(logo_file, width=50, height=50)
    header_text = Paragraph(f"<b>{COMPANY_NAME.upper()}</b><br/><b>ROL DE PAGO DE SOCIO</b><br/>Período: {r['periodo_mes_anio']}", title_style)

    header_table = Table([[logo_img, header_text]], colWidths=[60, 480])
    header_table.setStyle(TableStyle([('VALIGN', (0,0), (-1,-1), 'MIDDLE')]))
    story.append(header_table)
    story.append(Spacer(1, 15))

    body_data = [
        [Paragraph("<b>Nombre del Socio:</b>", normal_style), Paragraph(r['socio_nombre'], normal_style)],
        [Paragraph("<b>Monto Base Fijo Mensual:</b>", normal_style), Paragraph(f"${float(r['monto_fijo']):,.2f}", normal_style)],
        [Paragraph("<b>Ventas Consolidadas Mes:</b>", normal_style), Paragraph(f"${float(r['total_ventas_mes']):,.2f}", normal_style)],
        [Paragraph("<b>Porcentaje de Bono (5%):</b>", normal_style), Paragraph(f"{r['porcentaje_bono']}%", normal_style)],
        [Paragraph("<b>Bono Calculado:</b>", normal_style), Paragraph(f"${float(r['monto_bono_calculado']):,.2f}", normal_style)],
        [Paragraph("<b>Bono Ajustado (Contador):</b>", normal_style), Paragraph(f"${float(r['monto_bono_ajustado']):,.2f}", normal_style)],
        [Paragraph("<b>TOTAL A RECIBIR (USD):</b>", ParagraphStyle('B', parent=normal_style, fontName='Helvetica-Bold', fontSize=12, textColor=royal_blue)),
         Paragraph(f"<b>${float(r['total_pagar']):,.2f}</b>", ParagraphStyle('B', parent=normal_style, fontName='Helvetica-Bold', fontSize=12, textColor=royal_blue))],
    ]

    t = Table(body_data, colWidths=[200, 340])
    t.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('BACKGROUND', (0,-1), (-1,-1), colors.HexColor("#E0F2FE")),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t)
    story.append(Spacer(1, 40))

    signatures_data = [
        [Paragraph("___________________________<br/><b>Firma del Contador</b>", normal_style), Paragraph("___________________________<br/><b>Firma del Socio Receptora</b>", normal_style)]
    ]
    sig_table = Table(signatures_data, colWidths=[270, 270])
    sig_table.setStyle(TableStyle([('ALIGN', (0,0), (-1,-1), 'CENTER')]))
    story.append(sig_table)

    doc.build(story)
    return output_path
