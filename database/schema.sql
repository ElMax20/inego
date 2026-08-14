-- ============================================================
-- SCRIPT DE BASE DE DATOS OFICIAL PARA MYSQL WORKBENCH
-- Proyecto: Sistema ERP / CRM Inego Industrias
-- Arquitectura: Relacional N-Capas (Normalizado 3NF)
-- Ubicación: Guayaquil, Ecuador
-- ============================================================

CREATE DATABASE IF NOT EXISTS inego_industrias
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE inego_industrias;

-- ============================================================
-- 1. SEGURIDAD Y CONTROL DE ACCESO (ROLES, USUARIOS, AUDITORÍA)
-- ============================================================

-- Tabla de Roles Operativos
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla de Usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    rol_id INT NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE RESTRICT,
    INDEX idx_usuarios_username (username),
    INDEX idx_usuarios_rol (rol_id)
) ENGINE=InnoDB;

-- Tabla de Auditoría Log (Tareas Compartidas y Trazabilidad)
CREATE TABLE IF NOT EXISTS auditoria_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT,
    usuario_nombre VARCHAR(100) NOT NULL,
    tipo_accion VARCHAR(100) NOT NULL,
    detalles TEXT,
    ip_host VARCHAR(50) DEFAULT 'Local Desktop',
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_auditoria_fecha (fecha_hora),
    INDEX idx_auditoria_usuario (usuario_id)
) ENGINE=InnoDB;

-- ============================================================
-- 2. CATALOGO DE PROVEEDORES Y CLASIFICACIÓN
-- ============================================================

-- Categorías de Proveedores
CREATE TABLE IF NOT EXISTS categorias_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

-- Proveedores
CREATE TABLE IF NOT EXISTS proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empresa VARCHAR(150) NOT NULL,
    ruc_cedula VARCHAR(20) NOT NULL,
    contacto_nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    direccion VARCHAR(200) NOT NULL,
    ubicacion VARCHAR(100) DEFAULT 'Guayaquil',
    categoria_id INT,
    tipo_proveedor ENUM('Guayaquil (90%)', 'Otras Provincias', 'Amazon', 'Tiendamia') NOT NULL DEFAULT 'Guayaquil (90%)',
    rating INT DEFAULT 5,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias_proveedor(id) ON DELETE SET NULL,
    INDEX idx_proveedores_ruc (ruc_cedula),
    INDEX idx_proveedores_categoria (categoria_id)
) ENGINE=InnoDB;

-- ============================================================
-- 3. CATÁLOGO DE PRODUCTOS E INVENTARIO HÍBRIDO
-- ============================================================

-- Categorías de Productos
CREATE TABLE IF NOT EXISTS categorias_producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

-- Productos (Modelo Híbrido: Stock Permanente vs Bajo Pedido)
CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    categoria_id INT,
    descripcion TEXT,
    tipo_stock ENUM('Permanente', 'Bajo Pedido') NOT NULL DEFAULT 'Bajo Pedido',
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    precio_referencial DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias_producto(id) ON DELETE SET NULL,
    INDEX idx_productos_codigo (codigo),
    INDEX idx_productos_nombre (nombre),
    INDEX idx_productos_categoria (categoria_id)
) ENGINE=InnoDB;

-- Relación N:M Producto ↔ Proveedor
CREATE TABLE IF NOT EXISTS producto_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    proveedor_id INT NOT NULL,
    codigo_proveedor VARCHAR(50),
    precio_actual DECIMAL(12, 2) NOT NULL,
    tiempo_entrega_dias INT DEFAULT 1,
    estado_disponibilidad ENUM('En Stock Proveedor', 'Bajo Pedido 24-48h', 'Agotado') DEFAULT 'En Stock Proveedor',
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    observaciones TEXT,
    UNIQUE KEY uq_producto_proveedor (producto_id, proveedor_id),
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE CASCADE,
    INDEX idx_prod_prov_producto (producto_id),
    INDEX idx_prod_prov_proveedor (proveedor_id)
) ENGINE=InnoDB;

-- Historial de Precios de Proveedores por Producto
CREATE TABLE IF NOT EXISTS historial_precios_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    proveedor_id INT NOT NULL,
    precio DECIMAL(12, 2) NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE CASCADE,
    INDEX idx_hist_precio_prod (producto_id),
    INDEX idx_hist_precio_prov (proveedor_id),
    INDEX idx_hist_precio_fecha (fecha_registro)
) ENGINE=InnoDB;

-- ============================================================
-- 4. GESTIÓN DE CLIENTES Y POLÍTICAS DE CRÉDITO B2B / B2C
-- ============================================================

-- Clientes
CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_cliente ENUM('B2B', 'B2C') NOT NULL DEFAULT 'B2C',
    razon_social_nombre VARCHAR(150) NOT NULL,
    ruc_cedula VARCHAR(20) NOT NULL,
    telefono VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    direccion VARCHAR(200) NOT NULL DEFAULT 'Guayaquil',
    dias_credito INT NOT NULL DEFAULT 0, -- 72 días si B2B, 0 si B2C
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_clientes_ruc (ruc_cedula),
    INDEX idx_clientes_tipo (tipo_cliente)
) ENGINE=InnoDB;

-- ============================================================
-- 5. IMPUESTOS
-- ============================================================

-- Impuestos Configurables
CREATE TABLE IF NOT EXISTS impuestos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    porcentaje DECIMAL(5, 2) NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- ============================================================
-- 6. COTIZACIONES Y DETALLES
-- ============================================================

-- Cotizaciones (Cabecera)
CREATE TABLE IF NOT EXISTS cotizaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_cotizacion VARCHAR(50) NOT NULL UNIQUE,
    cliente_id INT NOT NULL,
    usuario_id INT NOT NULL,
    fecha_emision DATE NOT NULL DEFAULT (CURRENT_DATE),
    fecha_vencimiento DATE,
    impuesto_id INT,
    porcentaje_impuesto_aplicado DECIMAL(5, 2) NOT NULL DEFAULT 15.00,
    es_credito_72dias TINYINT(1) NOT NULL DEFAULT 0,
    estado ENUM('Borrador', 'Enviada', 'Aprobada', 'Facturada', 'Rechazada') NOT NULL DEFAULT 'Enviada',
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    monto_impuesto DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    observaciones TEXT,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY (impuesto_id) REFERENCES impuestos(id) ON DELETE SET NULL,
    INDEX idx_cotizaciones_numero (numero_cotizacion),
    INDEX idx_cotizaciones_cliente (cliente_id),
    INDEX idx_cotizaciones_fecha (fecha_emision)
) ENGINE=InnoDB;

-- Detalle de Cotización
CREATE TABLE IF NOT EXISTS cotizacion_detalles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cotizacion_id INT NOT NULL,
    producto_id INT NOT NULL,
    proveedor_elegido_id INT,
    cantidad INT NOT NULL,
    precio_costo_unitario DECIMAL(12, 2) NOT NULL,
    precio_venta_unitario DECIMAL(12, 2) NOT NULL,
    subtotal_linea DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (proveedor_elegido_id) REFERENCES proveedores(id) ON DELETE SET NULL,
    INDEX idx_cot_det_cotizacion (cotizacion_id),
    INDEX idx_cot_det_producto (producto_id)
) ENGINE=InnoDB;

-- ============================================================
-- 7. ÓRDENES / VENTAS Y DETALLES
-- ============================================================

-- Ventas / Órdenes de Compra (Cabecera)
CREATE TABLE IF NOT EXISTS ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_orden VARCHAR(50) NOT NULL UNIQUE,
    cotizacion_id INT,
    cliente_id INT NOT NULL,
    usuario_id INT NOT NULL,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    tipo_pago ENUM('Contado', 'Crédito') NOT NULL DEFAULT 'Contado',
    impuesto_id INT,
    porcentaje_impuesto_aplicado DECIMAL(5, 2) NOT NULL DEFAULT 15.00,
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    monto_impuesto DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    estado ENUM('Generada', 'En Proceso', 'Despachada', 'Completada', 'Cancelada') NOT NULL DEFAULT 'Generada',
    observaciones TEXT,
    FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id) ON DELETE SET NULL,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY (impuesto_id) REFERENCES impuestos(id) ON DELETE SET NULL,
    INDEX idx_ventas_numero (numero_orden),
    INDEX idx_ventas_cliente (cliente_id),
    INDEX idx_ventas_fecha (fecha_venta)
) ENGINE=InnoDB;

-- Detalle de Venta / Orden
CREATE TABLE IF NOT EXISTS venta_detalles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12, 2) NOT NULL,
    subtotal_linea DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    INDEX idx_ven_det_venta (venta_id),
    INDEX idx_ven_det_producto (producto_id)
) ENGINE=InnoDB;

-- ============================================================
-- 8. VENTAS A CRÉDITO Y CUENTAS POR COBRAR (B2B 72 DÍAS)
-- ============================================================

-- Cuentas por Cobrar
CREATE TABLE IF NOT EXISTS cuentas_por_cobrar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    cliente_id INT NOT NULL,
    monto_original DECIMAL(12, 2) NOT NULL,
    saldo_pendiente DECIMAL(12, 2) NOT NULL,
    fecha_emision DATE NOT NULL DEFAULT (CURRENT_DATE),
    fecha_vencimiento DATE NOT NULL,
    estado ENUM('Vigente', 'Vencida', 'Pagada') NOT NULL DEFAULT 'Vigente',
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    INDEX idx_cxc_venta (venta_id),
    INDEX idx_cxc_cliente (cliente_id),
    INDEX idx_cxc_vencimiento (fecha_vencimiento),
    INDEX idx_cxc_estado (estado)
) ENGINE=InnoDB;

-- Registro de Pagos de Créditos
CREATE TABLE IF NOT EXISTS pagos_credito (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_por_cobrar_id INT NOT NULL,
    fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP,
    monto_pagado DECIMAL(12, 2) NOT NULL,
    forma_pago ENUM('Efectivo', 'Transferencia', 'Cheque', 'Depósito') NOT NULL DEFAULT 'Transferencia',
    numero_comprobante VARCHAR(50),
    usuario_id INT,
    observaciones TEXT,
    FOREIGN KEY (cuenta_por_cobrar_id) REFERENCES cuentas_por_cobrar(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_pagos_cxc (cuenta_por_cobrar_id)
) ENGINE=InnoDB;

-- ============================================================
-- 9. GUÍAS DE REMISIÓN
-- ============================================================

-- Guías de Remisión (Transporte Físico y Despachos)
CREATE TABLE IF NOT EXISTS guias_remision (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_guia VARCHAR(50) NOT NULL UNIQUE,
    venta_id INT NOT NULL,
    cliente_id INT NOT NULL,
    usuario_responsable_id INT NOT NULL,
    fecha_emision DATETIME DEFAULT CURRENT_TIMESTAMP,
    direccion_partida VARCHAR(200) NOT NULL DEFAULT 'Guayaquil',
    direccion_destino VARCHAR(200) NOT NULL,
    conductor_transportista VARCHAR(100),
    placa_vehiculo VARCHAR(20),
    estado ENUM('En Tránsito', 'Entregada', 'Anulada') NOT NULL DEFAULT 'En Tránsito',
    observaciones TEXT,
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_responsable_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    INDEX idx_guias_numero (numero_guia),
    INDEX idx_guias_venta (venta_id),
    INDEX idx_guias_cliente (cliente_id)
) ENGINE=InnoDB;

-- Detalle de Guía de Remisión
CREATE TABLE IF NOT EXISTS guia_remision_detalles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    guia_remision_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad_transportada INT NOT NULL,
    FOREIGN KEY (guia_remision_id) REFERENCES guias_remision(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    INDEX idx_guia_det_guia (guia_remision_id),
    INDEX idx_guia_det_producto (producto_id)
) ENGINE=InnoDB;

-- ============================================================
-- 10. CAJA, GASTOS Y FLUJO DE EFECTIVO
-- ============================================================

-- Categorías de Gastos
CREATE TABLE IF NOT EXISTS categorias_gasto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

-- Movimientos de Caja (Ingresos y Egresos / Caja Chica)
CREATE TABLE IF NOT EXISTS caja_movimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo ENUM('Ingreso', 'Egreso') NOT NULL,
    categoria_gasto_id INT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    concepto_descripcion VARCHAR(200) NOT NULL,
    monto DECIMAL(12, 2) NOT NULL,
    metodo_pago ENUM('Caja Chica', 'Transferencia', 'Efectivo', 'Cheque') NOT NULL DEFAULT 'Caja Chica',
    usuario_id INT NOT NULL,
    referencia_operacion VARCHAR(100),
    observaciones TEXT,
    FOREIGN KEY (categoria_gasto_id) REFERENCES categorias_gasto(id) ON DELETE SET NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    INDEX idx_caja_fecha (fecha),
    INDEX idx_caja_tipo (tipo),
    INDEX idx_caja_categoria (categoria_gasto_id)
) ENGINE=InnoDB;

-- ============================================================
-- 11. SOCIOS Y PAGOS MENSUALES
-- ============================================================

-- Tabla de Socios de la Empresa
CREATE TABLE IF NOT EXISTS socios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    identificacion VARCHAR(20) NOT NULL UNIQUE,
    cargo_rol VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Pagos y Roles a Socios ($50 Fijo + 5% Bono)
CREATE TABLE IF NOT EXISTS pagos_socios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    periodo_mes_anio VARCHAR(20) NOT NULL,
    socio_id INT NOT NULL,
    pago_fijo DECIMAL(12, 2) NOT NULL DEFAULT 50.00,
    total_ventas_mes DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    porcentaje_bono DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
    bono_calculado DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    bono_ajustado DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_pagado DECIMAL(12, 2) NOT NULL,
    fecha_pago DATE NOT NULL DEFAULT (CURRENT_DATE),
    estado ENUM('Pendiente', 'Pagado') NOT NULL DEFAULT 'Pagado',
    observaciones TEXT,
    FOREIGN KEY (socio_id) REFERENCES socios(id) ON DELETE CASCADE,
    INDEX idx_pagos_socios_socio (socio_id),
    INDEX idx_pagos_socios_periodo (periodo_mes_anio)
) ENGINE=InnoDB;


-- ============================================================
-- DATOS SEMILLA DE CONFIGURACIÓN INICIAL DE CATÁLOGOS
-- ============================================================

-- Roles Operativos Básicos
INSERT INTO roles (nombre, descripcion) VALUES
('Administrador de Dinero', 'Dirección financiera y gestión general del capital'),
('Compras y Mercadería', 'Gestión de proveedores, cotizaciones e inventario'),
('Contabilidad', 'Supervisión contable, impuestos y emisión de roles de pago');

-- Usuarios Semilla (Claves cifradas SHA-256)
-- admin -> admin123 | compras -> compras123 | contador -> contador123
INSERT INTO usuarios (username, password_hash, nombre_completo, email, rol_id, activo) VALUES
('admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'Socio 1 - Administrador de Dinero', 'socio1@inego.com', 1, 1),
('compras', 'b7f433aa632b7f7e9148d5b883017a02b1f855d4960309995166f2824982a7f5', 'Socio 2 - Compras y Mercadería', 'socio2@inego.com', 2, 1),
('contador', '73d6118d7bcbc8f50aa966b4458f27aa5eefbf190e87eb0c16922b9c7b949ecb', 'Socio 3 - Proceso Contable', 'socio3@inego.com', 3, 1);

-- Impuestos Iniciales
INSERT INTO impuestos (nombre, porcentaje, activo) VALUES
('IVA General 15%', 15.00, 1),
('IVA 0% Exento', 0.00, 1);

-- Categorías de Proveedores
INSERT INTO categorias_proveedor (nombre, descripcion) VALUES
('Ferretería General', 'Herramientas, cuchillas, tornillería y consumibles'),
('Tecnología y Software', 'Licencias de software, equipos y accesorios de computación'),
('Suministros de Oficina', 'Papelería, carpetas, tintas y accesorios');

-- Categorías de Productos
INSERT INTO categorias_producto (nombre, descripcion) VALUES
('Ferretería General', 'Herramientas manuales, cuchillas e insumos industriales'),
('Tecnología y Software', 'Licencias de software corporativo y periféricos'),
('Suministros de Oficina', 'Artículos de escritorio y papelería corporativa');

-- Categorías de Gastos Operativos
INSERT INTO categorias_gasto (nombre, descripcion) VALUES
('Agua y Servicios', 'Pago de servicios básicos de la oficina'),
('Logística y Envíos', 'Transporte y fletes para contratos con el gobierno'),
('Gestión Operativa', 'Gastos administrativos y materiales de oficina'),
('Compras Varias', 'Adquisiciones menores y caja chica'),
('Mantenimiento', 'Reparación de equipos e infraestructura'),
('Otros', 'Imprevistos y egresos varios');

-- Registro de Socios
INSERT INTO socios (nombre_completo, identificacion, cargo_rol, email) VALUES
('Socio 1 - Administrador de Dinero', '0912345678', 'Socio Principal - Finanzas', 'socio1@inego.com'),
('Socio 2 - Compras y Mercadería', '0923456789', 'Socio Operativo - Compras', 'socio2@inego.com'),
('Socio 3 - Proceso Contable', '0934567890', 'Socio Contable - Impuestos', 'socio3@inego.com');
