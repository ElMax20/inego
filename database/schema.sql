-- ============================================================
-- SCRIPT DE BASE DE DATOS PARA MYSQL WORKBENCH
-- Proyecto: Sistema ERP / CRM Inego Industrias
-- Ubicación: Guayaquil, Ecuador
-- ============================================================

CREATE DATABASE IF NOT EXISTS inego_industrias_db;
USE inego_industrias_db;

-- 0. Tabla de Usuarios y Roles Operativos
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    rol ENUM('Administrador de Dinero', 'Compras y Mercadería', 'Contabilidad') NOT NULL DEFAULT 'Administrador de Dinero',
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Registro de Auditoría para Tareas Compartidas
CREATE TABLE IF NOT EXISTS auditoria_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario_nombre VARCHAR(100) NOT NULL,
    tipo_accion VARCHAR(100) NOT NULL,
    detalles TEXT,
    ip_host VARCHAR(50) DEFAULT 'Local Desktop'
);

-- 1. Tabla de Categorías de Proveedores
CREATE TABLE IF NOT EXISTS categorias_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
);

-- 2. Tabla de Proveedores
CREATE TABLE IF NOT EXISTS proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empresa VARCHAR(150) NOT NULL,
    ruc_cedula VARCHAR(20),
    contacto_nombre VARCHAR(100),
    telefono VARCHAR(50),
    email VARCHAR(100),
    direccion VARCHAR(200),
    ubicacion VARCHAR(100) DEFAULT 'Guayaquil',
    categoria_id INT,
    tipo_proveedor ENUM('Guayaquil (90%)', 'Otras Provincias', 'Amazon', 'Tiendamia') DEFAULT 'Guayaquil (90%)',
    rating INT DEFAULT 5,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias_proveedor(id) ON DELETE SET NULL
);

-- 3. Tabla de Productos y Stock (Stock permanente vs Bajo pedido)
CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    categoria VARCHAR(100),
    descripcion TEXT,
    tipo_stock ENUM('Permanente', 'Bajo Pedido') DEFAULT 'Bajo Pedido',
    stock_actual INT DEFAULT 0,
    stock_minimo INT DEFAULT 5,
    precio_referencial DECIMAL(10, 2) DEFAULT 0.00,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla Intermedia: Productos por Proveedor (Relación N:M)
CREATE TABLE IF NOT EXISTS producto_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    proveedor_id INT NOT NULL,
    precio_cotizado DECIMAL(10, 2) NOT NULL,
    tiempo_entrega_dias INT DEFAULT 1,
    estado_disponibilidad ENUM('En Stock Proveedor', 'Bajo Pedido 24-48h', 'Agotado') DEFAULT 'En Stock Proveedor',
    fecha_ultima_cotizacion DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE CASCADE
);

-- 5. Tabla de Clientes (B2B con 72 días crédito vs B2C contado)
CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_cliente ENUM('B2B', 'B2C') NOT NULL DEFAULT 'B2C',
    razon_social_nombre VARCHAR(150) NOT NULL,
    ruc_cedula VARCHAR(20),
    telefono VARCHAR(50),
    email VARCHAR(100),
    direccion VARCHAR(200) DEFAULT 'Guayaquil',
    dias_credito INT DEFAULT 0, -- 72 días si B2B, 0 si B2C
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 6. Tabla de Cotizaciones y Ventas
CREATE TABLE IF NOT EXISTS cotizaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_cotizacion VARCHAR(50) UNIQUE NOT NULL,
    cliente_id INT NOT NULL,
    fecha_emision DATE DEFAULT (CURRENT_DATE),
    fecha_vencimiento DATE,
    es_credito_72dias BOOLEAN DEFAULT FALSE,
    estado ENUM('Borrador', 'Enviada', 'Aprobada', 'Facturada', 'Rechazada') DEFAULT 'Enviada',
    subtotal DECIMAL(10, 2) DEFAULT 0.00,
    iva DECIMAL(10, 2) DEFAULT 0.00,
    total DECIMAL(10, 2) DEFAULT 0.00,
    observaciones TEXT,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
);

-- 7. Tabla Detalle de Cotizaciones
CREATE TABLE IF NOT EXISTS cotizacion_detalles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cotizacion_id INT NOT NULL,
    producto_id INT NOT NULL,
    proveedor_elegido_id INT,
    cantidad INT NOT NULL,
    precio_costo_unitario DECIMAL(10, 2) NOT NULL,
    precio_venta_unitario DECIMAL(10, 2) NOT NULL,
    subtotal_linea DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (proveedor_elegido_id) REFERENCES proveedores(id) ON DELETE SET NULL
);

-- 8. Tabla de Control de Gastos Operativos y Caja Chica
CREATE TABLE IF NOT EXISTS gastos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE DEFAULT (CURRENT_DATE),
    categoria ENUM('Agua y Servicios', 'Logística y Envíos', 'Gestión Operativa', 'Compras Varias', 'Mantenimiento', 'Otros') DEFAULT 'Otros',
    concepto VARCHAR(200) NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    metodo_pago VARCHAR(50) DEFAULT 'Caja Chica',
    registrado_por VARCHAR(100) DEFAULT 'Administrador',
    comprobante_nro VARCHAR(50),
    observaciones TEXT
);

-- 9. Tabla de Roles de Pago a Socios
CREATE TABLE IF NOT EXISTS roles_pago (
    id INT AUTO_INCREMENT PRIMARY KEY,
    periodo_mes_anio VARCHAR(20) NOT NULL,
    socio_nombre VARCHAR(100) NOT NULL,
    monto_fijo DECIMAL(10, 2) DEFAULT 50.00,
    total_ventas_mes DECIMAL(10, 2) DEFAULT 0.00,
    porcentaje_bono DECIMAL(5, 2) DEFAULT 5.00,
    monto_bono_calculado DECIMAL(10, 2) DEFAULT 0.00,
    monto_bono_ajustado DECIMAL(10, 2) DEFAULT 0.00, -- Ajuste manual del contador
    total_pagar DECIMAL(10, 2) NOT NULL,
    fecha_emision DATE DEFAULT (CURRENT_DATE),
    estado ENUM('Pendiente', 'Pagado') DEFAULT 'Pagado',
    observaciones TEXT
);

-- 10. Tabla de Ordenes de Venta (RF3.6)
CREATE TABLE IF NOT EXISTS ordenes_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_orden VARCHAR(50) UNIQUE NOT NULL,
    cotizacion_id INT NOT NULL,
    cliente_id INT NOT NULL,
    fecha_orden DATETIME DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(10, 2) NOT NULL,
    iva DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    estado VARCHAR(50) DEFAULT 'Generada',
    FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id) ON DELETE CASCADE,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
);

-- SEED DATA INICIAL DE PRUEBA
INSERT INTO usuarios (username, password_hash, nombre_completo, email, rol) VALUES
('admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'Socio 1 - Administrador de Dinero', 'socio1@inego.com', 'Administrador de Dinero'),
('compras', 'b7f433aa632b7f7e9148d5b883017a02b1f855d4960309995166f2824982a7f5', 'Socio 2 - Compras y Mercadería', 'socio2@inego.com', 'Compras y Mercadería'),
('contador', '73d6118d7bcbc8f50aa966b4458f27aa5eefbf190e87eb0c16922b9c7b949ecb', 'Socio 3 - Proceso Contable', 'socio3@inego.com', 'Contabilidad');

INSERT INTO categorias_proveedor (nombre, descripcion) VALUES
('Ferretería General', 'Herramientas, cuchillas, tornillería y consumibles'),
('Tecnología y Software', 'Licencias de software, equipos y accesorios de computación'),
('Suministros de Oficina', 'Papelería, carpetas, tintas y accesorios');

INSERT INTO proveedores (nombre_empresa, ruc_cedula, contacto_nombre, telefono, email, ubicacion, categoria_id, tipo_proveedor) VALUES
('Ferretería Industrial Guayaquil S.A.', '0992837465001', 'Carlos Mendoza', '0991234567', 'ventas@ferreindustrialgye.com', 'Guayaquil', 1, 'Guayaquil (90%)'),
('Software & Tech Ecuador', '0991122334001', 'Ing. María Torres', '0987654321', 'contacto@softwaretech.ec', 'Guayaquil', 2, 'Guayaquil (90%)'),
('Importadora Central Quito', '1790011223001', 'Juan Pérez', '0998877665', 'ventas@importadoracentral.com', 'Quito', 1, 'Otras Provincias'),
('Amazon US Direct', 'N/A', 'Soporte Amazon Business', 'N/A', 'business@amazon.com', 'EE.UU.', 2, 'Amazon');

INSERT INTO productos (codigo, nombre, categoria, descripcion, tipo_stock, stock_actual, precio_referencial) VALUES
('FER-001', 'Cuchilla Doble Filo Industrial (Pack x100)', 'Ferretería General', 'Cuchillas reforzadas de acero para corte pesado', 'Permanente', 45, 12.50),
('SOFT-001', 'Licencia Microsoft Office 365 Professional', 'Tecnología y Software', 'Suscripción/Licencia corporativa anual', 'Permanente', 12, 65.00),
('HERR-002', 'Taladro Perforador Industrial 850W', 'Ferretería General', 'Equipo bajo pedido para obras gubernamentales', 'Bajo Pedido', 0, 145.00),
('OFI-003', 'Kit Suministros Oficina Ejecutivo', 'Suministros de Oficina', 'Resmas, carpetas, esferos y accesorios', 'Bajo Pedido', 0, 35.00);

INSERT INTO clientes (tipo_cliente, razon_social_nombre, ruc_cedula, telefono, email, direccion, dias_credito) VALUES
('B2B', 'Ministerio de Obras Públicas Zonal 8', '0960001110001', '042112233', 'compras@obraspublicas.gob.ec', 'Guayaquil - Av. Francisco de Orellana', 72),
('B2B', 'Constructora Eléctrica del Pacífico S.A.', '0995544332001', '0990011223', 'gerencia@conselpac.com', 'Guayaquil - Vía a Samborondón', 72),
('B2C', 'Juan Fernando Gómez', '0923456789', '0981122334', 'juan.gomez@gmail.com', 'Guayaquil - Urdesa Central', 0);
