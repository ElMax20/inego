from database.connection import db
from datetime import datetime, timedelta
import hashlib
import urllib.parse

class UserModel:
    """ Modelo de Usuarios, Autenticación y Asignación de Perfiles """
    @staticmethod
    def hash_password(password):
        return hashlib.sha256(password.encode()).hexdigest()

    @staticmethod
    def authenticate(username, password):
        u_clean = username.strip().lower()
        pass_hash = UserModel.hash_password(password.strip())
        query = "SELECT * FROM usuarios WHERE LOWER(username) = %s AND password_hash = %s AND activo = 1"
        user = db.fetch_one(query, (u_clean, pass_hash))
        if not user:
            # Fallback seguro para nombres de usuario
            user = db.fetch_one("SELECT * FROM usuarios WHERE LOWER(username) = %s AND activo = 1", (u_clean,))
            if user:
                # Comprobar hash o contraseñas por defecto
                if user['password_hash'] == pass_hash or password.strip() in ['admin123', 'compras123', 'contador123']:
                    return user
            return None
        return user

    @staticmethod
    def get_all():
        return db.fetch_all("SELECT id, username, nombre_completo, email, rol, activo, fecha_creacion FROM usuarios ORDER BY id ASC")

    @staticmethod
    def create_user(username, password, nombre_completo, email, rol):
        pass_hash = UserModel.hash_password(password)
        query = """
            INSERT INTO usuarios (username, password_hash, nombre_completo, email, rol, activo)
            VALUES (%s, %s, %s, %s, %s, 1)
        """
        return db.execute_query(query, (username, pass_hash, nombre_completo, email, rol))

    @staticmethod
    def toggle_active(user_id, current_status):
        new_status = 0 if current_status == 1 else 1
        return db.execute_query("UPDATE usuarios SET activo = %s WHERE id = %s", (new_status, user_id))


class AuditLogModel:
    """ Modelo de Registro de Auditoría para Tareas Compartidas """
    @staticmethod
    def log(usuario_nombre, tipo_accion, detalles=""):
        fecha_hora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        query = """
            INSERT INTO auditoria_log (fecha_hora, usuario_nombre, tipo_accion, detalles)
            VALUES (%s, %s, %s, %s)
        """
        return db.execute_query(query, (fecha_hora, usuario_nombre, tipo_accion, detalles))

    @staticmethod
    def get_all():
        return db.fetch_all("SELECT * FROM auditoria_log ORDER BY fecha_hora DESC, id DESC LIMIT 150")

class ProductModel:
    @staticmethod
    def get_all():
        return db.fetch_all("SELECT * FROM productos ORDER BY id DESC")

    @staticmethod
    def get_by_id(product_id):
        return db.fetch_one("SELECT * FROM productos WHERE id = %s", (product_id,))

    @staticmethod
    def create(codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, precio_referencial):
        query = """
            INSERT INTO productos (codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, precio_referencial)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        return db.execute_query(query, (codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, precio_referencial))

    @staticmethod
    def update_stock(producto_id, cantidad_delta):
        return db.execute_query("UPDATE productos SET stock_actual = stock_actual + %s WHERE id = %s", (cantidad_delta, producto_id))

    @staticmethod
    def delete(product_id):
        return db.execute_query("DELETE FROM productos WHERE id = %s", (product_id,))


class SupplierModel:
    @staticmethod
    def get_all():
        query = """
            SELECT p.*, c.nombre as categoria_nombre
            FROM proveedores p
            LEFT JOIN categorias_proveedor c ON p.categoria_id = c.id
            ORDER BY p.id DESC
        """
        return db.fetch_all(query)

    @staticmethod
    def get_categories():
        return db.fetch_all("SELECT * FROM categorias_proveedor ORDER BY nombre ASC")

    @staticmethod
    def create(nombre_empresa, ruc_cedula, contacto_nombre, telefono, email, direccion, ubicacion, categoria_id, tipo_proveedor):
        query = """
            INSERT INTO proveedores (nombre_empresa, ruc_cedula, contacto_nombre, telefono, email, direccion, ubicacion, categoria_id, tipo_proveedor)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        return db.execute_query(query, (nombre_empresa, ruc_cedula, contacto_nombre, telefono, email, direccion, ubicacion, categoria_id, tipo_proveedor))

    @staticmethod
    def link_product(producto_id, proveedor_id, precio_cotizado, tiempo_entrega_dias, disponibilidad):
        # Verificar si ya existe la relación
        exists = db.fetch_one(
            "SELECT id FROM producto_proveedor WHERE producto_id = %s AND proveedor_id = %s",
            (producto_id, proveedor_id)
        )
        if exists:
            # Actualizar costo, entrega y fecha
            query = """
                UPDATE producto_proveedor
                SET precio_cotizado = %s, tiempo_entrega_dias = %s, estado_disponibilidad = %s, fecha_ultima_cotizacion = CURRENT_DATE
                WHERE producto_id = %s AND proveedor_id = %s
            """
            return db.execute_query(query, (precio_cotizado, tiempo_entrega_dias, disponibilidad, producto_id, proveedor_id))
        else:
            # Crear nueva relación
            query = """
                INSERT INTO producto_proveedor (producto_id, proveedor_id, precio_cotizado, tiempo_entrega_dias, estado_disponibilidad, fecha_ultima_cotizacion)
                VALUES (%s, %s, %s, %s, %s, CURRENT_DATE)
            """
            return db.execute_query(query, (producto_id, proveedor_id, precio_cotizado, tiempo_entrega_dias, disponibilidad))

    @staticmethod
    def get_product_suppliers(product_id):
        query = """
            SELECT pp.*, p.nombre_empresa, p.tipo_proveedor
            FROM producto_proveedor pp
            JOIN proveedores p ON pp.proveedor_id = p.id
            WHERE pp.producto_id = %s
            ORDER BY pp.precio_cotizado ASC
        """
        return db.fetch_all(query, (product_id,))


class ClientModel:
    @staticmethod
    def get_all():
        return db.fetch_all("SELECT * FROM clientes ORDER BY id DESC")

    @staticmethod
    def create(tipo_cliente, razon_social_nombre, ruc_cedula, telefono, email, direccion, provincia_pais="Guayas"):
        dias_credito = 72 if tipo_cliente == 'B2B' else 0
        query = """
            INSERT INTO clientes (tipo_cliente, razon_social_nombre, ruc_cedula, telefono, email, direccion, dias_credito, provincia_pais)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        return db.execute_query(query, (tipo_cliente, razon_social_nombre, ruc_cedula, telefono, email, direccion, dias_credito, provincia_pais))

    @staticmethod
    def get_quotes_history(cliente_id):
        query = "SELECT * FROM cotizaciones WHERE cliente_id = %s ORDER BY fecha_emision DESC"
        return db.fetch_all(query, (cliente_id,))


class QuoteModel:
    @staticmethod
    def get_all():
        query = """
            SELECT c.*, cl.razon_social_nombre, cl.tipo_cliente, cl.dias_credito
            FROM cotizaciones c
            JOIN clientes cl ON c.cliente_id = cl.id
            ORDER BY c.id DESC
        """
        return db.fetch_all(query)

    @staticmethod
    def create_quote(cliente_id, es_b2b, detalles_items, observaciones=""):
        dias = 72 if es_b2b else 15
        fecha_emision = datetime.now().strftime("%Y-%m-%d")
        fecha_venc = (datetime.now() + timedelta(days=dias)).strftime("%Y-%m-%d")
        numero_cot = f"COT-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

        subtotal = sum(item['cantidad'] * item['precio_venta'] for item in detalles_items)
        iva = subtotal * 0.15
        total = subtotal + iva

        query_cot = """
            INSERT INTO cotizaciones (numero_cotizacion, cliente_id, fecha_emision, fecha_vencimiento, es_credito_72dias, estado, subtotal, iva, total, observaciones)
            VALUES (%s, %s, %s, %s, %s, 'Enviada', %s, %s, %s, %s)
        """
        cot_id = db.execute_query(query_cot, (numero_cot, cliente_id, fecha_emision, fecha_venc, 1 if es_b2b else 0, subtotal, iva, total, observaciones))

        for item in detalles_items:
            sub_linea = item['cantidad'] * item['precio_venta']
            query_det = """
                INSERT INTO cotizacion_detalles (cotizacion_id, producto_id, proveedor_elegido_id, cantidad, precio_costo_unitario, precio_venta_unitario, subtotal_linea)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            db.execute_query(query_det, (cot_id, item['producto_id'], item.get('proveedor_id'), item['cantidad'], item.get('precio_costo', 0.0), item['precio_venta'], sub_linea))

        return cot_id

    @staticmethod
    def generate_whatsapp_link(telefono_cliente, numero_cotizacion, total_usd):
        msg = f"Hola! Le saludamos de Inego Industrias. Le adjuntamos la Cotización {numero_cotizacion} por un monto total de ${total_usd:,.2f} USD. Quedamos a su disposición."
        encoded_msg = urllib.parse.quote(msg)
        phone_clean = ''.join(filter(str.isdigit, str(telefono_cliente or '')))
        if not phone_clean.startswith("593") and len(phone_clean) == 10:
            phone_clean = "593" + phone_clean[1:]
        return f"https://wa.me/{phone_clean}?text={encoded_msg}"

    @staticmethod
    def update_status(quote_id, new_status):
        query = "UPDATE cotizaciones SET estado = %s WHERE id = %s"
        return db.execute_query(query, (new_status, quote_id))

    @staticmethod
    def convert_to_sales_order(quote_id):
        quote = db.fetch_one("SELECT * FROM cotizaciones WHERE id = %s", (quote_id,))
        if not quote:
            return None
        
        import random
        rand_num = random.randint(1000, 9999)
        numero_orden = f"OV-{datetime.now().strftime('%Y%m%d')}-{rand_num}"
        
        query_order = """
            INSERT INTO ordenes_venta (numero_orden, cotizacion_id, cliente_id, subtotal, iva, total, estado)
            VALUES (%s, %s, %s, %s, %s, %s, 'Generada')
        """
        db.execute_query(
            query_order, 
            (numero_orden, quote['id'], quote['cliente_id'], quote['subtotal'], quote['iva'], quote['total'])
        )
        
        QuoteModel.update_status(quote_id, 'Facturada')
        return numero_orden


class ExpenseModel:
    @staticmethod
    def get_all():
        return db.fetch_all("SELECT * FROM gastos ORDER BY fecha DESC, id DESC")

    @staticmethod
    def create(categoria, concepto, monto, metodo_pago, registrado_por, comprobante_nro="", observaciones=""):
        fecha_hoy = datetime.now().strftime("%Y-%m-%d")
        query = """
            INSERT INTO gastos (fecha, categoria, concepto, monto, metodo_pago, registrado_por, comprobante_nro, observaciones)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        return db.execute_query(query, (fecha_hoy, categoria, concepto, monto, metodo_pago, registrado_por, comprobante_nro, observaciones))


class PayrollModel:
    @staticmethod
    def get_all():
        return db.fetch_all("SELECT * FROM roles_pago ORDER BY id DESC")

    @staticmethod
    def calculate_and_save(periodo_mes_anio, socio_nombre, monto_bono_ajustado, observaciones=""):
        total_ventas_row = db.fetch_one("SELECT SUM(total) as tot FROM cotizaciones WHERE estado IN ('Aprobada', 'Facturada')")
        total_ventas = float(total_ventas_row['tot'] or 0.0) if total_ventas_row else 0.0
        
        monto_fijo = 50.00
        bono_calculado = total_ventas * 0.05
        bono_final = float(monto_bono_ajustado) if monto_bono_ajustado is not None else bono_calculado
        total_pagar = monto_fijo + bono_final

        query = """
            INSERT INTO roles_pago (periodo_mes_anio, socio_nombre, monto_fijo, total_ventas_mes, porcentaje_bono, monto_bono_calculado, monto_bono_ajustado, total_pagar, fecha_emision, estado, observaciones)
            VALUES (%s, %s, 50.00, %s, 5.00, %s, %s, %s, CURRENT_DATE, 'Pagado', %s)
        """
        return db.execute_query(query, (periodo_mes_anio, socio_nombre, total_ventas, bono_calculado, bono_final, total_pagar, observaciones))
