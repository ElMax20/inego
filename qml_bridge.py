import sys
import os
import json
from PySide6.QtCore import QObject, Slot, Signal, Property

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)

from database.connection import db
from models.models import UserModel, SupplierModel, ClientModel, ProductModel, AuditLogModel
from utils.excel_generator import export_sales_to_excel, export_gantt_chart_to_excel, export_expenses_to_excel
from utils.validators import validate_email, validate_phone, validate_cedula, validate_ruc, validate_cedula_or_ruc, validate_required_fields
from config import COMPANY_NAME, PARTNER_FIXED_PAY, PARTNER_BONUS_PERCENT

class BackendBridge(QObject):
    """ Puente de comunicación entre la interfaz nativa QML (Qt Quick) y la lógica backend Python """
    
    themeChanged = Signal(str)
    userLoggedIn = Signal(str, str) # username, role
    
    def __init__(self):
        super().__init__()
        self._current_user = None
        self._current_theme = "light"

    @Slot(str, str, result=str)
    def authenticate(self, username, password):
        user = UserModel.authenticate(username.strip(), password.strip())
        if user:
            self._current_user = user
            AuditLogModel.log(
                user['nombre_completo'],
                "Inicio de Sesión QML Desktop",
                f"Acceso exitoso con perfil: {user['rol']}"
            )
            return json.dumps({
                "success": True,
                "user": {
                    "username": user["username"],
                    "nombre_completo": user["nombre_completo"],
                    "rol": user["rol"]
                }
            })
        else:
            return json.dumps({
                "success": False,
                "message": "Usuario o contraseña incorrectos"
            })

    @Slot(result=str)
    def logout(self):
        """ Cierra la sesión activa del usuario y registra el evento en auditoría """
        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Cierre de Sesión", "Cerró sesión en el sistema QML")
            self._current_user = None
        return json.dumps({"success": True, "message": "Sesión cerrada exitosamente."})

    @Slot(str, str, result=bool)
    def hasPermission(self, role, route):
        if not role or role == "Administrador" or role == "Administrador de Dinero":
            return True
        if role == "Compras y Mercadería" and route in ["dashboard", "catalog", "stock", "suppliers", "quotes"]:
            return True
        if role == "Contabilidad" and route in ["dashboard", "clients", "expenses", "payroll", "reports"]:
            return True
        return False

    @Slot(result=str)
    def getDashboardData(self):
        r_ventas = db.fetch_one("SELECT SUM(total) as total FROM cotizaciones WHERE estado IN ('Facturada', 'Aprobada')")
        r_gastos = db.fetch_one("SELECT SUM(monto) as total FROM gastos")
        r_cred = db.fetch_one("SELECT SUM(total) as total FROM cotizaciones WHERE es_credito_72dias = 1 AND estado = 'Facturada'")
        r_cot = db.fetch_one("SELECT COUNT(*) as cnt FROM cotizaciones")
        perm_prods = db.fetch_all("SELECT * FROM productos WHERE tipo_stock = 'Permanente'")

        stock_items = []
        for p in perm_prods:
            stock_items.append({
                "nombre": p["nombre"],
                "codigo": p["codigo"],
                "stock_actual": p["stock_actual"],
                "stock_minimo": p.get("stock_minimo", 5),
                "es_alerta": p["stock_actual"] < 5
            })

        resp = {
            "ventas": float(r_ventas['total'] or 0.0) if r_ventas else 0.0,
            "gastos": float(r_gastos['total'] or 0.0) if r_gastos else 0.0,
            "credito": float(r_cred['total'] or 0.0) if r_cred else 0.0,
            "cotizaciones": r_cot['cnt'] if r_cot else 0,
            "stock_items": stock_items
        }
        return json.dumps(resp)

    @Slot(str, result=str)
    def getInventoryData(self, search_text=""):
        search_val = search_text.strip().lower()
        prods = db.fetch_all("SELECT * FROM productos ORDER BY id ASC")

        result = []
        for p in prods:
            raw_cat = p["categoria"] if "categoria" in p.keys() and p["categoria"] else "General"
            raw_desc = p.get("descripcion") or "Sin descripción"
            raw_name = p["nombre"]

            # Limpiar y normalizar la categoría de productos enlazados sin corchetes
            cat = raw_cat.replace("[", "").replace("]", "").strip()
            if cat == "Enlazados" or "Enlazado" in raw_desc or "-LNK" in p["codigo"] or "LNK-" in p["codigo"]:
                prov_name = "Proveedor"
                if "Enlazado a " in raw_desc:
                    prov_name = raw_desc.split("Enlazado a ")[-1].strip()
                elif "proveedor: " in raw_desc.lower():
                    prov_name = raw_desc.split("proveedor: ")[-1].strip()
                elif "Proveedor: " in raw_name:
                    prov_name = raw_name.split("Proveedor: ")[-1].replace("]", "").strip()
                elif "(" in cat:
                    prov_name = cat.split("(")[0].strip()

                prov_name = prov_name.replace("[", "").replace("]", "").strip()
                cat = f"{prov_name} (Enlazado)"

            # Limpiar corchetes del nombre del producto si existen
            clean_name = raw_name.replace("[Proveedor: ", "- Proveedor: ").replace("[", "").replace("]", "").strip()

            # Realizar búsqueda sobre los campos del producto (RF2.7)
            if search_val:
                search_match = (
                    search_val in clean_name.lower() or 
                    search_val in p["codigo"].lower() or 
                    search_val in cat.lower() or 
                    search_val in raw_desc.lower()
                )
                if not search_match:
                    continue

            is_linked = "(Enlazado)" in cat or "-LNK" in p["codigo"] or "LNK-" in p["codigo"]
            fecha_act = str(p.get("fecha_registro") or "2026-08-20")[:10]
            costo_cotiz = float(p.get("precio_referencial") or 0.0)

            result.append({
                "id": p["id"],
                "codigo": p["codigo"],
                "nombre": clean_name,
                "categoria": cat,
                "descripcion": raw_desc.replace("[", "").replace("]", "").strip(),
                "tipo_stock": p["tipo_stock"],
                "stock_actual": p["stock_actual"],
                "stock_minimo": p.get("stock_minimo", 5),
                "es_alerta": p["stock_actual"] < 5,
                "costo": costo_cotiz,
                "costo_ultima_cotizacion": costo_cotiz,
                "fecha_actualizacion": fecha_act,
                "es_enlazado": is_linked,
                "proveedor": "Importadora Central / Sweet & Coffee" if p["tipo_stock"] == "Bajo Pedido" else "Stock Propio Guayaquil"
            })
        return json.dumps(result)

    @Slot(result=str)
    def getSupplierNames(self):
        """ Retorna lista de nombres de proveedores registrados para la selección en QML ComboBox """
        sups = db.fetch_all("SELECT nombre_empresa FROM proveedores ORDER BY nombre_empresa ASC")
        names = [s["nombre_empresa"] for s in sups]
        if not names:
            names = [
                "Sweet & Coffee S.A.",
                "Ferretería Industrial Guayaquil S.A.",
                "Software & Tech Ecuador",
                "Amazon Business Corp USA",
                "Tiendamia Logistics Ecuador",
                "Grainger Industrial Supplies Inc."
            ]
        return json.dumps(names)

    @Slot(result=str)
    def getCategories(self):
        """ Retorna todas las categorías existentes de productos en BD + categorías creadas + opción agregar """
        categories = set()

        # 1. Categorías de productos existentes en el catálogo
        try:
            prods = db.fetch_all("SELECT DISTINCT categoria FROM productos WHERE categoria IS NOT NULL AND categoria != ''")
            for p in prods:
                categories.add(p["categoria"].strip())
        except Exception:
            pass

        # 2. Categorías de la tabla categorias_producto
        try:
            cats = db.fetch_all("SELECT nombre FROM categorias_producto WHERE nombre IS NOT NULL AND nombre != ''")
            for c in cats:
                categories.add(c["nombre"].strip())
        except Exception:
            pass

        defaults = ["Ferretería General", "Tecnología y Software", "Suministros de Oficina", "Equipos Industriales", "General"]
        for d in defaults:
            categories.add(d)

        c_list = sorted(list(categories))
        c_list.append("➕ Agregar Nueva Categoría...")
        return json.dumps(c_list)

    @Slot(str, result=str)
    def addCategory(self, category_name):
        if not category_name or not category_name.strip():
            return json.dumps({"success": False, "message": "Ingrese el nombre de la categoría."})

        name_clean = category_name.strip()
        try:
            db.execute_query("INSERT INTO categorias_producto (nombre) VALUES (%s)", (name_clean,))
        except Exception:
            pass

        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Nueva Categoría", f"Creó categoría de producto: {name_clean}")

        return json.dumps({"success": True, "message": f"Categoría '{name_clean}' agregada."})

    @Slot(str, str, str, str, str, str, int, int, float, result=str)
    def addProduct(self, codigo, nombre, categoria, descripcion, proveedor, tipo_stock, stock_inicial, stock_minimo, precio_referencial):
        """ RF2.4 — Creación de Producto con Código, Nombre, Categoría, Descripción, Proveedor, Stock Inicial y Stock Mínimo """
        if not codigo or not codigo.strip() or not nombre or not nombre.strip():
            return json.dumps({"success": False, "message": "Debe ingresar código y nombre del producto."})

        cod_clean = codigo.strip()
        nom_clean = nombre.strip()
        desc_text = descripcion.strip() if descripcion else "Sin descripción"
        desc_final = f"{desc_text} | Proveedor: {proveedor}" if proveedor else desc_text

        try:
            db.execute_query(
                "INSERT INTO productos (codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, stock_minimo, precio_referencial) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                (cod_clean, nom_clean, categoria if categoria else "General", desc_final, tipo_stock if tipo_stock else "Permanente", stock_inicial, stock_minimo, precio_referencial)
            )
        except Exception:
            db.execute_query(
                "INSERT INTO productos (codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, precio_referencial) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                (cod_clean, nom_clean, categoria if categoria else "General", desc_final, tipo_stock if tipo_stock else "Permanente", stock_inicial, precio_referencial)
            )

        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Registro de Producto", f"Registró producto: {nom_clean} ({cod_clean})")
        return json.dumps({"success": True, "message": f"Producto '{nom_clean}' creado exitosamente."})

    @Slot(int, result=str)
    def deleteProduct(self, product_id):
        db.execute_query("DELETE FROM productos WHERE id = %s", (product_id,))
        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Eliminación de Producto", f"Eliminó el producto ID #{product_id} del catálogo")
        return json.dumps({"success": True, "message": "Producto eliminado exitosamente del catálogo."})

    @Slot(int, str, result=str)
    def linkProductWithProvider(self, product_id, provider_name):
        orig = db.fetch_one("SELECT * FROM productos WHERE id = %s", (product_id,))
        prov_clean = provider_name.replace("[", "").replace("]", "").strip()
        new_code = f"LNK-{product_id}"
        new_name = f"Producto #{product_id} - Proveedor: {prov_clean}"
        cost = 25.0
        if orig:
            orig_name = orig['nombre'].split('[')[0].strip()
            new_code = f"{orig['codigo']}-LNK"
            new_name = f"{orig_name} - Proveedor: {prov_clean}"
            cost = float(orig.get("precio_referencial") or 0.0)

        linked_category = f"{prov_clean} (Enlazado)"

        db.execute_query(
            "INSERT INTO productos (codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, precio_referencial) VALUES (%s, %s, %s, %s, 'Bajo Pedido', 0, %s)",
            (new_code, new_name, linked_category, f"Producto enlazado al proveedor {prov_clean}", cost)
        )

        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Enlace Multi-Proveedor", f"Enlazó producto ID #{product_id} con proveedor: {prov_clean}")

        return json.dumps({"success": True, "message": f"Producto enlazado exitosamente a '{prov_clean}'."})

    @Slot(int, int, result=str)
    def dispatchStock(self, product_id, cantidad):
        """ Validación estricta: No se permite despachar más cantidad de la disponible en stock """
        prod = db.fetch_one("SELECT * FROM productos WHERE id = %s", (product_id,))
        if not prod:
            return json.dumps({"success": False, "message": "Producto no encontrado en el sistema."})

        stock_actual = int(prod.get("stock_actual") or 0)
        if cantidad > stock_actual:
            return json.dumps({
                "success": False,
                "message": f"🚫 Operación Denegada: No es posible despachar {cantidad} unidades. El stock disponible actual es de tan solo {stock_actual} unidades."
            })

        db.execute_query("UPDATE productos SET stock_actual = stock_actual - %s WHERE id = %s", (cantidad, product_id))
        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Despacho Físico", f"Despachó {cantidad} unidades del producto ID #{product_id}")
        return json.dumps({"success": True, "message": f"Se despacharon {cantidad} unidades del inventario."})

    @Slot(int, int, result=str)
    def renewStock(self, product_id, cantidad):
        db.execute_query("UPDATE productos SET stock_actual = stock_actual + %s WHERE id = %s", (cantidad, product_id))
        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Renovación de Stock", f"Renovó {cantidad} unidades del producto ID #{product_id}")
        return json.dumps({"success": True, "message": f"Se agregaron {cantidad} unidades renovadas al inventario."})

    @Slot(str, str, result=str)
    def getSuppliersData(self, origen="Todos los Orígenes", product_type="Todos los Tipos de Producto"):
        """ Retorna lista de proveedores filtrados por Origen de Ubicación y Tipo de Producto """
        sql = "SELECT s.*, c.nombre as categoria_nombre FROM proveedores s LEFT JOIN categorias_proveedor c ON s.categoria_id = c.id WHERE 1=1"
        params = []

        if origen and origen != "Todos los Orígenes":
            if "Guayaquil" in origen:
                sql += " AND (s.tipo_proveedor LIKE '%Guayaquil%' OR s.ubicacion LIKE '%Guayaquil%')"
            elif "Provincias" in origen:
                sql += " AND (s.tipo_proveedor LIKE '%Provincia%' OR s.ubicacion LIKE '%Provincia%')"
            elif "Importados" in origen:
                sql += " AND (s.tipo_proveedor LIKE '%Importad%' OR s.ubicacion LIKE '%Importad%')"

        if product_type and product_type != "Todos los Tipos de Producto":
            sql += " AND (s.tipo_producto LIKE %s OR c.nombre LIKE %s)"
            params.append(f"%{product_type}%")
            params.append(f"%{product_type}%")

        sups = db.fetch_all(sql, tuple(params))

        result = []
        for s in sups:
            result.append({
                "id": s["id"],
                "nombre_empresa": s["nombre_empresa"],
                "ruc_cedula": s["ruc_cedula"],
                "contacto_nombre": s["contacto_nombre"],
                "telefono": s["telefono"],
                "email": s["email"],
                "direccion": s["direccion"],
                "ubicacion": s["ubicacion"],
                "tipo_producto": s.get("tipo_producto") or s.get("categoria_nombre") or "Insumos Industriales",
                "categoria": s.get("categoria_nombre") or "General"
            })
        return json.dumps(result)

    @Slot(str, str, str, str, str, str, str, str, result=str)
    def addSupplier(self, ruc_cedula, nombre_empresa, contacto_nombre, telefono, email, direccion, tipo_proveedor, tipo_producto):
        """ Registro de Proveedores con Validación Estricta de RUC, Teléfono de 10 dígitos, Email Famoso y Tipo de Producto """
        if not ruc_cedula or not nombre_empresa or not contacto_nombre or not telefono:
            return json.dumps({"success": False, "message": "Por favor llene todos los campos obligatorios del proveedor."})

        rc_clean = ruc_cedula.strip()
        ok_rc, msg_rc = validate_ruc(rc_clean)
        if not ok_rc:
            return json.dumps({"success": False, "message": msg_rc})

        tel_clean = telefono.strip()
        ok_p, msg_p = validate_phone(tel_clean)
        if not ok_p:
            return json.dumps({"success": False, "message": msg_p})

        if email and email.strip() != "N/A":
            ok_e, msg_e = validate_email(email)
            if not ok_e:
                return json.dumps({"success": False, "message": msg_e})

        type_clean = "Guayaquil" if (tipo_proveedor and "Guayaquil" in tipo_proveedor) else tipo_proveedor
        prod_type_clean = tipo_producto.strip() if (tipo_producto and tipo_producto.strip()) else "Insumos Industriales"

        try:
            db.execute_query("""
                INSERT INTO proveedores (nombre_empresa, ruc_cedula, contacto_nombre, telefono, email, direccion, ubicacion, tipo_proveedor, tipo_producto)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                nombre_empresa.strip(), rc_clean, contacto_nombre.strip(),
                tel_clean, email.strip() if email else "ventas@gmail.com",
                direccion.strip() if direccion else "Guayaquil",
                type_clean if type_clean else "Guayaquil",
                type_clean if type_clean else "Guayaquil",
                prod_type_clean
            ))
            if self._current_user:
                AuditLogModel.log(self._current_user['nombre_completo'], "Registro de Proveedor", f"Registró proveedor: {nombre_empresa} (Tipo Producto: {prod_type_clean})")
            return json.dumps({"success": True, "message": f"Proveedor '{nombre_empresa}' registrado exitosamente."})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al guardar proveedor: {str(e)}"})

    @Slot(result=str)
    def getClientsData(self):
        clients = ClientModel.get_all()
        result = []
        for c in clients:
            result.append({
                "id": c["id"],
                "razon_social_nombre": c["razon_social_nombre"],
                "tipo_cliente": c["tipo_cliente"],
                "ruc_cedula": c["ruc_cedula"],
                "telefono": c["telefono"],
                "email": c["email"],
                "direccion": c["direccion"],
                "dias_credito": c["dias_credito"]
            })
        return json.dumps(result)

    @Slot(str, str, str, str, str, str, int, str, result=str)
    def addClient(self, razon_social_nombre, tipo_cliente, ruc_cedula, telefono, email, direccion, dias_credito, provincia_pais):
        if not razon_social_nombre or not ruc_cedula or not telefono:
            return json.dumps({"success": False, "message": "⚠️ Complete los datos obligatorios del cliente."})

        rc_clean = ruc_cedula.strip()
        ok_rc, msg_rc = validate_cedula_or_ruc(rc_clean)
        if not ok_rc:
            return json.dumps({"success": False, "message": msg_rc})

        # Validar teléfono (Exactamente 9 dígitos numéricos)
        tel_clean = telefono.strip()
        if not (len(tel_clean) == 9 and tel_clean.isdigit()):
            return json.dumps({"success": False, "message": "⚠️ Número de teléfono no válido: Debe contener exactamente 9 dígitos numéricos."})

        # Validar correo
        if email and email.strip() != "N/A":
            ok_e, msg_e = validate_email(email)
            if not ok_e:
                return json.dumps({"success": False, "message": msg_e})

        try:
            ClientModel.create(
                tipo_cliente if tipo_cliente else "B2C",
                razon_social_nombre.strip(), rc_clean,
                tel_clean, email.strip() if email else "N/A",
                direccion.strip() if direccion else "Guayaquil",
                provincia_pais if provincia_pais else "Guayas"
            )
            if self._current_user:
                AuditLogModel.log(self._current_user['nombre_completo'], "Registro de Cliente", f"Registró cliente: {razon_social_nombre} ({tipo_cliente}) de {provincia_pais}")
            return json.dumps({"success": True, "message": f"Cliente '{razon_social_nombre}' registrado exitosamente."})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al registrar cliente: {str(e)}"})

    @Slot(result=str)
    def getQuotesData(self):
        quotes = db.fetch_all("SELECT q.*, c.razon_social_nombre as cliente_nombre, c.email as cliente_correo, c.telefono as cliente_telefono FROM cotizaciones q LEFT JOIN clientes c ON q.cliente_id = c.id ORDER BY q.id DESC")
        result = []
        for q in quotes:
            result.append({
                "id": q["id"],
                "numero_cotizacion": q["numero_cotizacion"],
                "cliente_nombre": q["cliente_nombre"] or "Cliente General",
                "cliente_correo": q["cliente_correo"] or "N/A",
                "cliente_telefono": q["cliente_telefono"] or "N/A",
                "fecha_emision": q["fecha_emision"],
                "subtotal": float(q["subtotal"] or 0.0),
                "total": float(q["total"] or 0.0),
                "estado": q["estado"],
                "es_credito_72dias": bool(q["es_credito_72dias"])
            })
        return json.dumps(result)

    @Slot(int, result=str)
    def getClientQuotes(self, client_id):
        """ RF3.4 — Historial Comercial por Cliente """
        quotes = db.fetch_all("""
            SELECT q.*, c.razon_social_nombre as cliente_nombre, c.email as cliente_correo, c.telefono as cliente_telefono 
            FROM cotizaciones q 
            LEFT JOIN clientes c ON q.cliente_id = c.id 
            WHERE q.cliente_id = %s 
            ORDER BY q.id DESC
        """, (client_id,))
        result = []
        for q in quotes:
            result.append({
                "id": q["id"],
                "numero_cotizacion": q["numero_cotizacion"],
                "cliente_nombre": q["cliente_nombre"] or "Cliente General",
                "cliente_correo": q["cliente_correo"] or "N/A",
                "cliente_telefono": q["cliente_telefono"] or "N/A",
                "fecha_emision": str(q["fecha_emision"]),
                "subtotal": float(q["subtotal"] or 0.0),
                "total": float(q["total"] or 0.0),
                "estado": q["estado"],
                "es_credito_72dias": bool(q["es_credito_72dias"])
            })
        return json.dumps(result)

    @Slot(int, str, float, float, float, str, result=str)
    def createQuote(self, cliente_id, es_b2b_str, subtotal, iva, total, items_json):
        """ RF3.3 — Creador de Cotizaciones Express """
        try:
            from datetime import datetime, timedelta
            es_b2b = es_b2b_str == "B2B"
            dias = 72 if es_b2b else 15
            fecha_emision = datetime.now().strftime("%Y-%m-%d")
            fecha_venc = (datetime.now() + timedelta(days=dias)).strftime("%Y-%m-%d")
            numero_cot = f"COT-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

            query_cot = """
                INSERT INTO cotizaciones (numero_cotizacion, cliente_id, fecha_emision, fecha_vencimiento, es_credito_72dias, estado, subtotal, iva, total)
                VALUES (%s, %s, %s, %s, %s, 'Pendiente', %s, %s, %s)
            """
            cot_id = db.execute_query(query_cot, (
                numero_cot, cliente_id, fecha_emision, fecha_venc, 
                1 if es_b2b else 0, subtotal, iva, total
            ))

            items = json.loads(items_json)
            for item in items:
                sub_linea = float(item['cantidad']) * float(item['precio_venta'])
                query_det = """
                    INSERT INTO cotizacion_detalles (cotizacion_id, producto_id, cantidad, precio_costo_unitario, precio_venta_unitario, subtotal_linea)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """
                db.execute_query(query_det, (
                    cot_id, item['producto_id'], item['cantidad'], 
                    item.get('precio_costo', 0.0), item['precio_venta'], sub_linea
                ))

            if self._current_user:
                AuditLogModel.log(
                    self._current_user['nombre_completo'], 
                    "Creación de Cotización", 
                    f"Creó cotización express N° {numero_cot} por un total de ${total:,.2f} USD"
                )

            return json.dumps({"success": True, "message": f"Cotización '{numero_cot}' creada con éxito.", "quote_id": cot_id})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al guardar cotización: {str(e)}"})

    @Slot(int, result=str)
    def convertQuoteToOrder(self, quote_id):
        """ RF3.6 — Conversión a Venta """
        try:
            from models.models import QuoteModel
            # Reutilizamos la lógica del modelo de negocio
            # En la versión QML forzamos primero a "Aprobada" si estaba en otro estado para asegurar la conversión
            db.execute_query("UPDATE cotizaciones SET estado = 'Aprobada' WHERE id = %s", (quote_id,))
            numero_orden = QuoteModel.convert_to_sales_order(quote_id)
            if not numero_orden:
                return json.dumps({"success": False, "message": "No se pudo convertir la cotización a orden de venta."})
            
            return json.dumps({"success": True, "message": f"Cotización convertida con éxito. Orden de Venta {numero_orden} generada."})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al convertir cotización: {str(e)}"})

    @Slot(int, result=str)
    def generateAndOpenQuotePDF(self, quote_id):
        """ RF3.5 — Exportación Ágil a PDF """
        try:
            from utils.pdf_generator import generate_quote_pdf
            fpath = generate_quote_pdf(quote_id)
            if fpath and os.path.exists(fpath):
                # Abrir archivo PDF en el visor predeterminado del sistema
                os.startfile(fpath)
                return json.dumps({"success": True, "file": os.path.basename(fpath)})
            return json.dumps({"success": False, "message": "No se pudo generar el archivo PDF."})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al generar PDF: {str(e)}"})

    @Slot(int, result=str)
    def prepareQuoteSharing(self, quote_id):
        """ Genera el PDF de la cotización y lo copia al portapapeles para pegar con Ctrl+V """
        try:
            from utils.pdf_generator import generate_quote_pdf
            from PySide6.QtGui import QGuiApplication
            from PySide6.QtCore import QMimeData, QUrl
            
            fpath = generate_quote_pdf(quote_id)
            if fpath and os.path.exists(fpath):
                clipboard = QGuiApplication.clipboard()
                mime_data = QMimeData()
                mime_data.setUrls([QUrl.fromLocalFile(fpath)])
                clipboard.setMimeData(mime_data)
                
                return json.dumps({
                    "success": True, 
                    "file_path": fpath, 
                    "file_name": os.path.basename(fpath)
                })
            return json.dumps({"success": False, "message": "No se pudo generar el archivo PDF."})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al preparar cotización: {str(e)}"})

    @Slot(result=str)
    def getExpensesData(self):
        expenses = db.fetch_all("SELECT * FROM gastos ORDER BY id DESC")
        result = []
        for e in expenses:
            result.append({
                "id": e["id"],
                "rubro": e.get("categoria") or e.get("tipo_gasto") or "Otros",
                "concepto": e["concepto"],
                "monto": float(e["monto"] or 0.0),
                "fecha": e["fecha"]
            })
        return json.dumps(result)

    @Slot(str, str, float, result=str)
    def addExpense(self, concepto, rubro, monto):
        if not concepto or not monto:
            return json.dumps({"success": False, "message": "Por favor llene los datos del gasto."})
        try:
            from datetime import datetime
            fecha_hoy = datetime.now().strftime("%Y-%m-%d")
            registrado_por = self._current_user['nombre_completo'] if self._current_user else "Socio 1 - Administrador"
            db.execute_query("""
                INSERT INTO gastos (fecha, categoria, concepto, monto, metodo_pago, registrado_por)
                VALUES (%s, %s, %s, %s, 'Caja Chica', %s)
            """, (fecha_hoy, rubro, concepto, monto, registrado_por))
            
            if self._current_user:
                AuditLogModel.log(self._current_user['nombre_completo'], "Registro de Gasto", f"Registró gasto de caja chica: {concepto} por ${monto:,.2f} USD")
            
            return json.dumps({"success": True, "message": "Gasto registrado exitosamente."})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al guardar gasto: {str(e)}"})

    @Slot(result=str)
    def getPayrollData(self):
        r_ventas = db.fetch_one("SELECT SUM(total) as total FROM cotizaciones WHERE estado IN ('Facturada', 'Aprobada')")
        tot_sales = float(r_ventas['total'] or 0.0) if r_ventas else 0.0
        bonus = tot_sales * PARTNER_BONUS_PERCENT
        total_pay = PARTNER_FIXED_PAY + bonus

        partners = [
            {"id": 1, "nombre": "Socio 1 - Administrador de Dinero", "cargo": "Dirección Financiera", "pago_fijo": PARTNER_FIXED_PAY, "bono_5": bonus, "total": total_pay},
            {"id": 2, "nombre": "Socio 2 - Compras y Mercadería", "cargo": "Gestión de Proveedores e Inventario", "pago_fijo": PARTNER_FIXED_PAY, "bono_5": bonus, "total": total_pay},
            {"id": 3, "nombre": "Socio 3 - Proceso Contable", "cargo": "Supervisión Contable e Impuestos", "pago_fijo": PARTNER_FIXED_PAY, "bono_5": bonus, "total": total_pay}
        ]
        return json.dumps(partners)

    @Slot(result=str)
    def getUsersData(self):
        users = UserModel.get_all()
        result = []
        for u in users:
            result.append({
                "id": u["id"],
                "username": u["username"],
                "nombre_completo": u["nombre_completo"],
                "rol": u["rol"],
                "activo": bool(u["activo"])
            })
        return json.dumps(result)

    @Slot(str, str, str, str, result=str)
    def createUser(self, username, nombre_completo, password, rol):
        if not username or not nombre_completo or not password:
            return json.dumps({"success": False, "message": "Por favor llene todos los datos del nuevo usuario."})

        try:
            email = f"{username.strip().lower()}@inego.com"
            UserModel.create_user(username.strip(), password.strip(), nombre_completo.strip(), email, rol if rol else "Compras y Mercadería")
            if self._current_user:
                AuditLogModel.log(self._current_user['nombre_completo'], "Creación de Usuario", f"Creó usuario: {username} con rol {rol}")
            return json.dumps({"success": True, "message": f"Usuario '{username}' creado exitosamente."})
        except Exception as e:
            return json.dumps({"success": False, "message": f"Error al crear usuario: {str(e)}"})

    @Slot(result=str)
    def getCurrentUserRole(self):
        if self._current_user:
            return self._current_user.get("rol", "Administrador de Dinero")
        return "Administrador de Dinero"

    @Slot(result=str)
    def getAuditLogData(self):
        """ RF1.3 / Bitácora de Auditoría visible únicamente para Administrador """
        logs = db.fetch_all("SELECT * FROM auditoria_log ORDER BY id DESC LIMIT 150")
        result = []
        for l in logs:
            result.append({
                "id": l["id"],
                "fecha_hora": str(l.get("fecha_hora") or ""),
                "usuario_nombre": l.get("usuario_nombre") or "Sistema",
                "tipo_accion": l.get("tipo_accion") or "Operación",
                "detalles": l.get("detalles") or ""
            })
        return json.dumps(result)

    @Slot(int, result=str)
    def toggleUserStatus(self, user_id):
        """ Desactivar usuarios: El administrador no puede desactivarse a sí mismo ni a otras cuentas Admin """
        target = db.fetch_one("SELECT * FROM usuarios WHERE id = %s", (user_id,))
        if target and (target.get("username") == "admin" or target.get("rol") in ["Administrador", "Administrador de Dinero"]):
            return json.dumps({"success": False, "message": "🚫 Acción denegada: La cuenta Administrador no puede ser desactivada."})

        db.execute_query("UPDATE usuarios SET activo = CASE WHEN activo = 1 THEN 0 ELSE 1 END WHERE id = %s", (user_id,))
        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Cambio Estado Usuario", f"Modificó estado de usuario ID #{user_id}")
        return json.dumps({"success": True, "message": "Estado de usuario actualizado correctamente."})

    @Slot(str, result=str)
    def downloadReport(self, report_type):
        if report_type == "gantt":
            fpath = export_gantt_chart_to_excel()
        elif report_type == "sales":
            fpath = export_sales_to_excel()
        else:
            fpath = export_expenses_to_excel()
        return json.dumps({"success": True, "file": os.path.basename(fpath)})

    @Slot()
    def logout(self):
        if self._current_user:
            AuditLogModel.log(self._current_user['nombre_completo'], "Cierre de Sesión QML", "El usuario cerró sesión en la UI QML")
        self._current_user = None
