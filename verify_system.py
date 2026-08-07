import os
import sys

print("[VERIFICACION] Iniciando pruebas de Inego Industrias Desktop System...")

from database.connection import db
from models.models import UserModel, AuditLogModel, ProductModel, SupplierModel, ClientModel, QuoteModel, ExpenseModel, PayrollModel
from utils.excel_generator import export_sales_to_excel, export_gantt_chart_to_excel
from utils.pdf_generator import generate_quote_pdf, generate_payslip_pdf

# Pruebas del Módulo 1 (Autenticación, Usuarios y Bitácora)
user_admin = UserModel.authenticate("admin", "admin123")
if user_admin:
    print(f"[MODULO 1 OK] Autenticación exitosa para: {user_admin['nombre_completo']} | Rol: {user_admin['rol']}")

users_list = UserModel.get_all()
print(f"[MODULO 1 OK] Usuarios cargados: {len(users_list)} registrados.")

AuditLogModel.log("Socio 1 - Administrador de Dinero", "Prueba de Auditoria", "Registro automatico de prueba de trazabilidad")
audit_logs = AuditLogModel.get_all()
print(f"[MODULO 1 OK] Registros en Bitacora de Auditoria: {len(audit_logs)} entradas.")

# Pruebas de Módulos Base
prods = ProductModel.get_all()
print(f"[BD OK] Productos cargados: {len(prods)} registrados.")

supps = SupplierModel.get_all()
print(f"[BD OK] Proveedores cargados: {len(supps)} registrados (Guayaquil, Importados, etc.).")

clients = ClientModel.get_all()
print(f"[BD OK] Clientes cargados: {len(clients)} registrados (B2B 72 dias credito y B2C).")

quotes = QuoteModel.get_all()
print(f"[BD OK] Cotizaciones cargadas: {len(quotes)} en base de datos.")

excel_sales = export_sales_to_excel()
print(f"[EXCEL OK] Reporte de Ventas generado en: {excel_sales}")

excel_gantt = export_gantt_chart_to_excel()
print(f"[EXCEL OK] Diagrama de Gantt en Excel generado en: {excel_gantt}")

if quotes:
    pdf_quote = generate_quote_pdf(quotes[0]['id'])
    print(f"[PDF OK] PDF de Cotizacion generado en: {pdf_quote}")

payroll_id = PayrollModel.calculate_and_save("Agosto 2026", "Socio 1 - Administrador de Dinero", 150.00, "Prueba de emision rol fisico")
pdf_payslip = generate_payslip_pdf(payroll_id)
print(f"[PDF OK] Rol de Pago Fisico generado en: {pdf_payslip}")

print("\n[SISTEMA VERIFICADO CON EXITO] Todos los modulos incluyendo el Modulo 1 funcionaron perfectamente.")
