# Arquitectura del Sistema: INEGO Industrias ERP / CRM

## 1. Visión General

El sistema **INEGO Industrias** utiliza una arquitectura **N-Capas orientada a módulos** para mantener una clara separación de responsabilidades, alta mantenibilidad y escalabilidad adecuada para un entorno corporativo y académico.

```
┌─────────────────────────────────────────────────────────┐
│              Capa de Interfaz / Módulos                 │
│      (views/ + modules/ + customtkinter desktop)       │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Capa de Servicios                     │
│                       (services/)                       │
│    (Lógica de negocio, cálculos de bono 5%, validaciones)│
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                 Capa de Repositorios                    │
│                     (repositories/)                     │
│   (Consultas de persistencia, CRUD, mapeo de datos)     │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│             Capa de Gestión de Base de Datos            │
│                  (database/ + schema.sql)               │
│          (Motor MySQL 8.0+ / Fallback SQLite)           │
└─────────────────────────────────────────────────────────┘
```

## 2. Descripción de Capas

1. **Interfaz / Módulos (`views/`, `modules/`)**: Contiene las pantallas gráficas y los componentes de usuario construidos con CustomTkinter en modo ventana única.
2. **Servicios (`services/`)**: Implementa las reglas de negocio (cálculo de bono del 5% para socios, validaciones de formato, lógica de crédito a 72 días).
3. **Repositorios (`repositories/`)**: Encapsula las operaciones de acceso a datos para abstraer las sentencias SQL.
4. **Base de Datos (`database/`)**: Contiene el archivo oficial `schema.sql` y el gestor de conexión dual (`connection.py`).

## 3. Estructura de Carpetas

```
INEGO Industrias/
├── main.py
├── config.py
├── database/
│   ├── connection.py
│   └── schema.sql
├── models/
│   └── models.py
├── repositories/
├── services/
├── views/
├── modules/
├── utils/
├── tests/
└── docs/
    ├── arquitectura.md
    └── modelo_base_datos.md
```
