import sqlite3
import os
import sys
import pymysql

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from config import MYSQL_CONFIG, SQLITE_DB_PATH, PARTNER_FIXED_PAY, PARTNERS

class DatabaseManager:
    """
    Gestor de base de datos resiliente para Inego Industrias.
    Intenta conectar a MySQL (MySQL Workbench). Si no está disponible localmente,
    utiliza SQLite local de forma totalmente transparente.
    """
    def __init__(self):
        self.use_mysql = False
        self.mysql_checked = False
        self.connection = None
        self._check_mysql_availability()
        self._init_db()

    def _check_mysql_availability(self):
        try:
            import socket
            sock = socket.create_connection((MYSQL_CONFIG["host"], MYSQL_CONFIG["port"]), timeout=0.15)
            sock.close()
            self.use_mysql = True
        except Exception:
            self.use_mysql = False
        self.mysql_checked = True

    def get_connection(self):
        if not self.mysql_checked:
            self._check_mysql_availability()
            
        if self.use_mysql:
            try:
                conn = pymysql.connect(
                    host=MYSQL_CONFIG["host"],
                    port=MYSQL_CONFIG["port"],
                    user=MYSQL_CONFIG["user"],
                    password=MYSQL_CONFIG["password"],
                    database=MYSQL_CONFIG["database"],
                    cursorclass=pymysql.cursors.DictCursor,
                    connect_timeout=1,
                    autocommit=True
                )
                return conn
            except Exception:
                self.use_mysql = False
                
        conn = sqlite3.connect(SQLITE_DB_PATH, timeout=5)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        try:
            conn = self.get_connection()
            if self.use_mysql:
                print("[BD] Conectado exitosamente a MySQL Server.")
                conn.close()
                return
            
            print("[BD] Servidor MySQL no disponible. Inicializando motor SQLite local...")
            with conn:
                cursor = conn.cursor()
                cursor.execute("""
                CREATE TABLE IF NOT EXISTS usuarios (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    nombre_completo TEXT NOT NULL,
                    email TEXT,
                    rol TEXT NOT NULL DEFAULT 'Administrador de Dinero',
                    activo INTEGER DEFAULT 1,
                    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS auditoria_log (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
                    usuario_nombre TEXT NOT NULL,
                    tipo_accion TEXT NOT NULL,
                    detalles TEXT,
                    ip_host TEXT DEFAULT 'Local Desktop'
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS categorias_producto (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    nombre TEXT NOT NULL UNIQUE
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS categorias_proveedor (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    nombre TEXT NOT NULL UNIQUE,
                    descripcion TEXT
                );
                """)
                
                cursor.execute("""
                CREATE TABLE IF NOT EXISTS proveedores (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    nombre_empresa TEXT NOT NULL,
                    ruc_cedula TEXT,
                    contacto_nombre TEXT,
                    telefono TEXT,
                    email TEXT,
                    direccion TEXT,
                    ubicacion TEXT DEFAULT 'Guayaquil',
                    categoria_id INTEGER,
                    tipo_proveedor TEXT DEFAULT 'Guayaquil',
                    tipo_producto TEXT DEFAULT 'Insumos Industriales',
                    rating INTEGER DEFAULT 5,
                    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (categoria_id) REFERENCES categorias_proveedor(id)
                );
                """)

                try:
                    cursor.execute("ALTER TABLE proveedores ADD COLUMN tipo_producto TEXT DEFAULT 'Insumos Industriales'")
                except Exception:
                    pass

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS productos (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    codigo TEXT UNIQUE NOT NULL,
                    nombre TEXT NOT NULL,
                    categoria TEXT,
                    descripcion TEXT,
                    tipo_stock TEXT DEFAULT 'Bajo Pedido',
                    stock_actual INTEGER DEFAULT 0,
                    stock_minimo INTEGER DEFAULT 5,
                    precio_referencial REAL DEFAULT 0.00,
                    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS producto_proveedor (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    producto_id INTEGER NOT NULL,
                    proveedor_id INTEGER NOT NULL,
                    precio_cotizado REAL NOT NULL,
                    tiempo_entrega_dias INTEGER DEFAULT 1,
                    estado_disponibilidad TEXT DEFAULT 'En Stock Proveedor',
                    fecha_ultima_cotizacion DATE DEFAULT (DATE('now')),
                    FOREIGN KEY (producto_id) REFERENCES productos(id),
                    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS clientes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    tipo_cliente TEXT NOT NULL DEFAULT 'B2C',
                    razon_social_nombre TEXT NOT NULL,
                    ruc_cedula TEXT,
                    telefono TEXT,
                    email TEXT,
                    direccion TEXT DEFAULT 'Guayaquil',
                    dias_credito INTEGER DEFAULT 0,
                    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
                );
                """)

                try:
                    cursor.execute("ALTER TABLE clientes ADD COLUMN provincia_pais TEXT DEFAULT 'Guayas'")
                except Exception:
                    pass

                try:
                    cursor.execute("ALTER TABLE clientes ADD COLUMN regimen_tributario TEXT DEFAULT 'Régimen General'")
                except Exception:
                    pass

                try:
                    cursor.execute("ALTER TABLE clientes ADD COLUMN es_contribuyente_especial INTEGER DEFAULT 0")
                except Exception:
                    pass

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS cotizaciones (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    numero_cotizacion TEXT UNIQUE NOT NULL,
                    cliente_id INTEGER NOT NULL,
                    fecha_emision DATE DEFAULT (DATE('now')),
                    fecha_vencimiento DATE,
                    es_credito_72dias INTEGER DEFAULT 0,
                    estado TEXT DEFAULT 'Enviada',
                    subtotal REAL DEFAULT 0.00,
                    iva REAL DEFAULT 0.00,
                    total REAL DEFAULT 0.00,
                    observaciones TEXT,
                    FOREIGN KEY (cliente_id) REFERENCES clientes(id)
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS cotizacion_detalles (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    cotizacion_id INTEGER NOT NULL,
                    producto_id INTEGER NOT NULL,
                    proveedor_elegido_id INTEGER,
                    cantidad INTEGER NOT NULL,
                    precio_costo_unitario REAL NOT NULL,
                    precio_venta_unitario REAL NOT NULL,
                    subtotal_linea REAL NOT NULL,
                    FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id),
                    FOREIGN KEY (producto_id) REFERENCES productos(id)
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS gastos (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    fecha DATE DEFAULT (DATE('now')),
                    categoria TEXT DEFAULT 'Otros',
                    concepto TEXT NOT NULL,
                    monto REAL NOT NULL,
                    metodo_pago TEXT DEFAULT 'Caja Chica',
                    registrado_por TEXT DEFAULT 'Administrador',
                    comprobante_nro TEXT,
                    observaciones TEXT
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS roles_pago (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    periodo_mes_anio TEXT NOT NULL,
                    socio_nombre TEXT NOT NULL,
                    monto_fijo REAL DEFAULT 50.00,
                    total_ventas_mes REAL DEFAULT 0.00,
                    porcentaje_bono REAL DEFAULT 5.00,
                    monto_bono_calculado REAL DEFAULT 0.00,
                    monto_bono_ajustado REAL DEFAULT 0.00,
                    total_pagar REAL NOT NULL,
                    fecha_emision DATE DEFAULT (DATE('now')),
                    estado TEXT DEFAULT 'Pagado',
                    observaciones TEXT
                );
                """)

                cursor.execute("""
                CREATE TABLE IF NOT EXISTS ordenes_venta (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    numero_orden TEXT UNIQUE NOT NULL,
                    cotizacion_id INTEGER NOT NULL,
                    cliente_id INTEGER NOT NULL,
                    fecha_orden DATETIME DEFAULT CURRENT_TIMESTAMP,
                    subtotal REAL NOT NULL,
                    iva REAL NOT NULL,
                    total REAL NOT NULL,
                    estado TEXT DEFAULT 'Generada',
                    FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id),
                    FOREIGN KEY (cliente_id) REFERENCES clientes(id)
                );
                """)

                cursor.execute("SELECT COUNT(*) as cnt FROM usuarios")
                if cursor.fetchone()[0] == 0:
                    self._seed_initial_users(cursor)

                cursor.execute("SELECT COUNT(*) as cnt FROM categorias_proveedor")
                if cursor.fetchone()[0] == 0:
                    self._seed_initial_data(cursor)

                # Asegurar detalles para cotizaciones semilla si no existen
                cursor.execute("SELECT COUNT(*) as cnt FROM cotizacion_detalles")
                if cursor.fetchone()[0] == 0:
                    cursor.execute("""
                    INSERT INTO cotizacion_detalles (cotizacion_id, producto_id, proveedor_elegido_id, cantidad, precio_costo_unitario, precio_venta_unitario, subtotal_linea) VALUES
                    (1, 1, 1, 10, 10.00, 15.00, 150.00),
                    (2, 2, 2, 2, 50.00, 65.00, 130.00);
                    """)
                
                # Migración automática: Agregar columna direccion si no existe
                try:
                    cursor.execute("ALTER TABLE proveedores ADD COLUMN direccion TEXT")
                except Exception:
                    pass
                
            conn.close()
        except Exception as e:
            print(f"[BD ERROR] Error inicializando base de datos: {e}")

    def _seed_initial_users(self, cursor):
        import hashlib
        p1 = hashlib.sha256('admin123'.encode()).hexdigest()

        cursor.execute("""
        INSERT INTO usuarios (username, password_hash, nombre_completo, email, rol, activo) VALUES
        ('admin', ?, 'Administrador General del Sistema', 'admin@inego.com', 'Administrador', 1),
        ('admindinero', ?, 'Socio 1 - Administrador de Dinero', 'socio1@inego.com', 'Administrador de Dinero', 1),
        ('compras', ?, 'Socio 2 - Compras y Mercadería', 'socio2@inego.com', 'Compras y Mercadería', 1),
        ('contador', ?, 'Socio 3 - Proceso Contable', 'socio3@inego.com', 'Contabilidad', 1);
        """, (p1, p1, p1, p1))

    def _seed_initial_data(self, cursor):
        import hashlib
        p1 = hashlib.sha256('admin123'.encode()).hexdigest()

        cursor.execute("""
        INSERT INTO usuarios (username, password_hash, nombre_completo, email, rol, activo) VALUES
        ('admin', ?, 'Administrador General del Sistema', 'admin@inego.com', 'Administrador', 1),
        ('admindinero', ?, 'Socio 1 - Administrador de Dinero', 'socio1@inego.com', 'Administrador de Dinero', 1),
        ('compras', ?, 'Socio 2 - Compras y Mercadería', 'socio2@inego.com', 'Compras y Mercadería', 1),
        ('contador', ?, 'Socio 3 - Proceso Contable', 'socio3@inego.com', 'Contabilidad', 1);
        """, (p1, p1, p1, p1))

        cursor.execute("INSERT INTO categorias_proveedor (nombre, descripcion) VALUES ('Ferretería General', 'Herramientas y cuchillas'), ('Tecnología y Software', 'Licencias y equipos'), ('Suministros de Oficina', 'Papelería y consumibles');")
        
        cursor.execute("""
        INSERT INTO proveedores (nombre_empresa, ruc_cedula, contacto_nombre, telefono, email, ubicacion, categoria_id, tipo_proveedor) VALUES
        ('Ferretería Industrial Guayaquil S.A.', '0992837465001', 'Carlos Mendoza', '0991234567', 'ventas@ferreindustrialgye.com', 'Guayaquil', 1, 'Guayaquil (90%)'),
        ('Software & Tech Ecuador', '0991122334001', 'Ing. María Torres', '0987654321', 'contacto@softwaretech.ec', 'Guayaquil', 2, 'Guayaquil (90%)'),
        ('Importadora Central Quito', '1790011223001', 'Juan Pérez', '0998877665', 'ventas@importadoracentral.com', 'Quito', 1, 'Otras Provincias'),
        ('Amazon Business US', 'N/A', 'Soporte Amazon', 'N/A', 'business@amazon.com', 'EE.UU.', 2, 'Amazon');
        """)

        cursor.execute("""
        INSERT INTO productos (codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, precio_referencial) VALUES
        ('FER-001', 'Cuchillas Doble Filo Industrial (Pack x100)', 'Ferretería General', 'Cuchillas de alto rendimiento', 'Permanente', 50, 15.00),
        ('SOFT-001', 'Licencia Microsoft Office 365 Professional', 'Tecnología y Software', 'Licencia digital anual para empresas', 'Permanente', 20, 65.00),
        ('HERR-002', 'Taladro Industrial 850W Heavy Duty', 'Ferretería General', 'Herramienta bajo pedido para obra gubernamental', 'Bajo Pedido', 0, 140.00),
        ('OFI-003', 'Kit Suministros Ejecutivo Oficina', 'Suministros de Oficina', 'Mobiliario y consumibles', 'Bajo Pedido', 0, 45.00);
        """)

        cursor.execute("""
        INSERT INTO clientes (tipo_cliente, razon_social_nombre, ruc_cedula, telefono, email, direccion, dias_credito) VALUES
        ('B2B', 'Ministerio de Obras Públicas Zonal 8', '0960001110001', '042112233', 'compras@obraspublicas.gob.ec', 'Guayaquil - Av. Francisco de Orellana', 72),
        ('B2B', 'Constructora Eléctrica del Pacífico S.A.', '0920000114001', '0990011223', 'gerencia@conselpac.com', 'Guayaquil - Vía a Samborondón', 72),
        ('B2C', 'Juan Fernando Gómez', '0920000015', '0981122334', 'juan.gomez@gmail.com', 'Guayaquil - Urdesa Central', 0);
        """)

        cursor.execute("""
        INSERT INTO gastos (fecha, categoria, concepto, monto, metodo_pago, registrado_por) VALUES
        (DATE('now'), 'Agua y Servicios', 'Pago planilla de agua y luz local', 45.50, 'Caja Chica', 'Socio 1'),
        (DATE('now'), 'Logística y Envíos', 'Envío urgente de herramientas a obra gobierno', 30.00, 'Efectivo', 'Socio 2'),
        (DATE('now'), 'Gestión Operativa', 'Compra insumos de limpieza y cafetería', 18.25, 'Caja Chica', 'Socio 3');
        """)

        cursor.execute("""
        INSERT INTO cotizaciones (numero_cotizacion, cliente_id, fecha_emision, fecha_vencimiento, es_credito_72dias, estado, subtotal, iva, total, observaciones) VALUES
        ('COT-2026-001', 1, DATE('now'), DATE('now', '+72 days'), 1, 'Facturada', 1500.00, 225.00, 1725.00, 'Contrato Gobierno Nro 44 - Crédito 72 días'),
        ('COT-2026-002', 3, DATE('now'), DATE('now', '+15 days'), 0, 'Aprobada', 120.00, 18.00, 138.00, 'Venta al contado B2C');
        """)

        cursor.execute("""
        INSERT INTO cotizacion_detalles (cotizacion_id, producto_id, proveedor_elegido_id, cantidad, precio_costo_unitario, precio_venta_unitario, subtotal_linea) VALUES
        (1, 1, 1, 10, 10.00, 15.00, 150.00),
        (2, 2, 2, 2, 50.00, 65.00, 130.00);
        """)

    def execute_query(self, query, params=()):
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            if not self.use_mysql:
                query = query.replace("%s", "?")
            cursor.execute(query, params)
            conn.commit()
            last_id = cursor.lastrowid
            conn.close()
            return last_id
        except Exception as e:
            print(f"[BD QUERY ERROR] {e}")
            conn.close()
            return None

    def fetch_all(self, query, params=()):
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            if not self.use_mysql:
                query = query.replace("%s", "?")
            cursor.execute(query, params)
            rows = cursor.fetchall()
            conn.close()
            if not self.use_mysql:
                return [dict(row) for row in rows]
            return rows
        except Exception as e:
            print(f"[BD FETCH ERROR] {e}")
            conn.close()
            return []

    def fetch_one(self, query, params=()):
        results = self.fetch_all(query, params)
        return results[0] if results else None

db = DatabaseManager()
