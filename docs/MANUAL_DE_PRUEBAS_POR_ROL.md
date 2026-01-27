# MOVICUOTAS - Manual de Pruebas por Rol
## Sistema de Crédito para Dispositivos Móviles

**Versión:** 1.0
**Fecha:** Enero 2026
**Aplicación:** MOVICUOTAS Backend Admin Panel

---

## Recursos Visuales

Este manual incluye GIFs animados que demuestran el flujo de trabajo de cada rol:

| Rol | Archivo | Descripción |
|-----|---------|-------------|
| Vendedor | `images/manual/vendedor-workflow.gif` | Login → Búsqueda de Cliente → Dashboard |
| Supervisor | `images/manual/supervisor-workflow.gif` | Login → Dashboard → Dispositivos en Mora |
| Administrador | `images/manual/admin-workflow.gif` | Login → Dashboard → Gestión de Usuarios |

> **Nota:** Copie los archivos GIF descargados a la carpeta `docs/images/manual/`

---

## Índice

1. [Información General](#1-información-general)
2. [Credenciales de Prueba](#2-credenciales-de-prueba)
3. [Rol: Vendedor (Seller)](#3-rol-vendedor-seller)
4. [Rol: Supervisor](#4-rol-supervisor)
5. [Rol: Administrador](#5-rol-administrador)
6. [Matriz de Permisos](#6-matriz-de-permisos)
7. [Flujos de Trabajo Principales](#7-flujos-de-trabajo-principales)

---

## 1. Información General

### 1.1 Descripción del Sistema

MOVICUOTAS es un sistema de gestión de créditos para la venta de dispositivos móviles. El sistema permite:

- Registro y gestión de clientes
- Solicitudes de crédito con aprobación automática
- Seguimiento de préstamos y cuotas quincenales
- Gestión de pagos con verificación
- Control de dispositivos mediante MDM (Mobile Device Management)
- Bloqueo/desbloqueo de dispositivos por mora

### 1.2 Roles del Sistema

| Rol | Descripción | Acceso Principal |
|-----|-------------|------------------|
| **Vendedor** | Personal de ventas en tienda | Portal de Vendedor (`/vendor`) |
| **Supervisor** | Agente de cobranza | Panel de Supervisor (`/supervisor`) |
| **Administrador** | Acceso completo al sistema | Dashboard Admin (`/admin`) |

### 1.3 URL de Acceso

- **Producción:** `https://app.movicuotas.com`
- **Desarrollo:** `http://localhost:3000`
- **Página de Login:** `/login`

---

## 2. Credenciales de Prueba

### 2.1 Usuarios de Prueba

| Rol | Email | Contraseña | Sucursal |
|-----|-------|------------|----------|
| Administrador | `admin@movicuotas.com` | `password123` | Todas |
| Supervisor | `supervisor@movicuotas.com` | `password123` | Todas |
| Vendedor | `vendedor@movicuotas.com` | `password123` | S01 |

> **Nota:** Las contraseñas son solo para ambiente de pruebas. En producción, usar contraseñas seguras.

---

## 3. Rol: Vendedor (Seller)

![Vendedor Workflow](images/manual/vendedor-workflow.gif)

### 3.1 Descripción del Rol

El **Vendedor** es el personal de tienda responsable de:
- Atender a clientes que desean comprar dispositivos a crédito
- Registrar nuevos clientes en el sistema
- Procesar solicitudes de crédito
- Configurar dispositivos vendidos
- Registrar pagos de clientes

### 3.2 Acceso al Sistema

1. Ir a `/login`
2. Ingresar: `vendedor@movicuotas.com` / `password123`
3. El sistema redirige a: **Búsqueda de Cliente** (`/vendor/customer_search`)

### 3.3 Pantalla Principal: Búsqueda de Cliente

**URL:** `/vendor/customer_search`

Esta es la pantalla principal del vendedor. Permite buscar clientes por número de identidad.

**Elementos:**
- Campo de búsqueda: "Número de Identidad del Cliente"
- Botón: "Buscar en TODAS las tiendas"

**Resultados posibles:**
- **Cliente Bloqueado (rojo):** Tiene crédito activo, no puede solicitar otro
- **Cliente Disponible (verde):** Puede iniciar nueva solicitud de crédito

### 3.4 Menú de Navegación

El vendedor tiene acceso a las siguientes secciones:

| Sección | Descripción | URL |
|---------|-------------|-----|
| Dashboard | Resumen de ventas y estadísticas | `/vendor/dashboard` |
| Buscar Cliente | Búsqueda para iniciar venta | `/vendor/customer_search` |
| Préstamos | Lista de préstamos del vendedor | `/vendor/loans` |
| Pagos | Historial de pagos registrados | `/vendor/payments` |

### 3.5 Funcionalidades del Vendedor

#### 3.5.1 Buscar Cliente
- **Acción:** Ingresar número de identidad y buscar
- **Resultado:** Verificación si cliente puede acceder a crédito

#### 3.5.2 Crear Solicitud de Crédito (18 Pasos)

| Paso | Pantalla | Descripción |
|------|----------|-------------|
| 1 | Login | Autenticación |
| 2 | Buscar Cliente | Búsqueda por identidad |
| 3a | Cliente Bloqueado | Si tiene crédito activo |
| 3b | Cliente Disponible | Si puede solicitar crédito |
| 4 | Datos Generales | Información personal del cliente |
| 5 | Fotografías | Fotos de identidad y verificación facial |
| 6 | Datos Laborales | Información de empleo e ingresos |
| 7 | Resumen | Revisión de datos ingresados |
| 8a | No Aprobado | Solicitud rechazada |
| 8b | Aprobado | Solicitud aprobada |
| 9 | Recuperar Solicitud | Ingresar número de solicitud aprobada |
| 10 | Catálogo de Teléfonos | Selección de dispositivo |
| 11 | Confirmación | Resumen de compra |
| 12 | Calculadora | Selección de prima y cuotas |
| 13 | Contrato | Visualización del contrato |
| 14 | Firma Digital | Captura de firma del cliente |
| 15 | Crédito Aplicado | Confirmación de éxito |
| 16 | Código QR | Configuración MDM del dispositivo |
| 17 | Checklist Final | Verificación de configuración |
| 18 | Tracking | Seguimiento del préstamo |

#### 3.5.3 Ver Dashboard de Vendedor
- **URL:** `/vendor/dashboard`
- **Contenido:**
  - Total de clientes registrados
  - Préstamos activos
  - Pagos recibidos este mes
  - Cuotas vencidas

#### 3.5.4 Ver Préstamos
- **URL:** `/vendor/loans`
- **Acceso:** Solo préstamos propios (creados por el vendedor)
- **Acciones:** Ver detalle, descargar contrato

#### 3.5.5 Ver Pagos
- **URL:** `/vendor/payments`
- **Acceso:** Solo pagos de sus préstamos
- **Acciones:** Ver historial (solo lectura)

### 3.6 Restricciones del Vendedor

| Acción | Permitido |
|--------|-----------|
| Crear clientes | ✅ |
| Editar clientes | ✅ |
| Eliminar clientes | ❌ |
| Bloquear dispositivos | ❌ |
| Desbloquear dispositivos | ❌ |
| Verificar pagos | ❌ |
| Ver otros vendedores | ❌ |
| Acceso a reportes globales | ❌ |
| Gestión de usuarios | ❌ |

### 3.7 Casos de Prueba - Vendedor

| ID | Caso de Prueba | Pasos | Resultado Esperado |
|----|----------------|-------|-------------------|
| V01 | Login exitoso | 1. Ir a /login<br>2. Ingresar credenciales<br>3. Clic en "Iniciar Sesión" | Redirige a /vendor/customer_search |
| V02 | Buscar cliente disponible | 1. Ingresar identidad sin crédito activo<br>2. Clic en "Buscar" | Mensaje verde: "Cliente disponible" |
| V03 | Buscar cliente bloqueado | 1. Ingresar identidad con crédito activo<br>2. Clic en "Buscar" | Mensaje rojo: "Cliente tiene crédito activo" |
| V04 | Crear solicitud de crédito | Completar flujo de 18 pasos | Préstamo creado exitosamente |
| V05 | Ver dashboard | Navegar a Dashboard desde menú | Muestra estadísticas del vendedor |
| V06 | Intento de acceso admin | Navegar a /admin/dashboard | Redirigido o error de autorización |

---

## 4. Rol: Supervisor

![Supervisor Workflow](images/manual/supervisor-workflow.gif)

### 4.1 Descripción del Rol

El **Supervisor** es el agente de cobranza responsable de:
- Monitorear dispositivos con pagos vencidos
- Bloquear dispositivos por mora
- Ver historial de pagos (solo lectura)
- Generar reportes de cobranza

### 4.2 Acceso al Sistema

1. Ir a `/login`
2. Ingresar: `supervisor@movicuotas.com` / `password123`
3. El sistema redirige a: **Dashboard de Supervisor** (`/supervisor/dashboard`)

### 4.3 Pantalla Principal: Dashboard de Supervisor

**URL:** `/supervisor/dashboard`

**Contenido:**
- Total de dispositivos en mora
- Monto total vencido
- Dispositivos bloqueados
- Dispositivos pendientes de bloqueo
- Estadísticas por días de mora (1-7, 8-15, 16-30, 30+)

### 4.4 Menú de Navegación

| Sección | Descripción | URL |
|---------|-------------|-----|
| Dashboard | Resumen de cobranza | `/supervisor/dashboard` |
| Dispositivos en Mora | Lista de dispositivos vencidos | `/supervisor/overdue_devices` |
| Operaciones Masivas | Bloqueo múltiple de dispositivos | `/supervisor/bulk-operations` |
| Reportes de Cobranza | Análisis de mora | `/supervisor/collection-reports` |

### 4.5 Funcionalidades del Supervisor

#### 4.5.1 Ver Dispositivos en Mora
- **URL:** `/supervisor/overdue_devices`
- **Contenido:**
  - Lista de dispositivos con pagos vencidos
  - Días de mora
  - Monto vencido
  - Estado del dispositivo (bloqueado/desbloqueado)

#### 4.5.2 Bloquear Dispositivo Individual
- **Acción:** Desde detalle de dispositivo, clic en "Bloquear Dispositivo"
- **Proceso:**
  1. Muestra confirmación con datos del dispositivo y cliente
  2. Confirmar bloqueo
  3. Sistema envía notificación al cliente
  4. Dispositivo marcado como "pendiente" → "bloqueado"

#### 4.5.3 Operaciones Masivas de Bloqueo
- **URL:** `/supervisor/bulk-operations`
- **Acción:** Seleccionar múltiples dispositivos para bloqueo simultáneo
- **Filtros disponibles:**
  - Por días de mora mínimos
  - Por monto mínimo vencido
  - Por sucursal

#### 4.5.4 Ver Historial de Pagos (Solo Lectura)
- **URL:** `/supervisor/loans/:loan_id/payment-history`
- **Contenido:**
  - Información del cliente y préstamo
  - Lista de cuotas con estado
  - Historial de pagos realizados
  - **Solo lectura** - no puede editar ni registrar pagos

#### 4.5.5 Reportes de Cobranza
- **URL:** `/supervisor/collection-reports`
- **Contenido:**
  - Resumen de mora por periodo
  - Mora por sucursal
  - Dispositivos bloqueados recientemente
  - Tasa de recuperación
  - Exportar a PDF/Excel

### 4.6 Restricciones del Supervisor

| Acción | Permitido |
|--------|-----------|
| Ver dispositivos en mora | ✅ |
| Bloquear dispositivos | ✅ |
| Desbloquear dispositivos | ❌ (Solo Admin) |
| Ver historial de pagos | ✅ (Solo lectura) |
| Registrar pagos | ❌ |
| Verificar pagos | ❌ |
| Crear clientes | ❌ |
| Editar clientes | ❌ |
| Crear préstamos | ❌ |
| Gestión de usuarios | ❌ |
| Reportes de cobranza | ✅ |

### 4.7 Casos de Prueba - Supervisor

| ID | Caso de Prueba | Pasos | Resultado Esperado |
|----|----------------|-------|-------------------|
| S01 | Login exitoso | 1. Ir a /login<br>2. Ingresar credenciales<br>3. Clic en "Iniciar Sesión" | Redirige a /supervisor/dashboard |
| S02 | Ver dispositivos en mora | Navegar a "Dispositivos en Mora" | Lista de dispositivos con pagos vencidos |
| S03 | Bloquear dispositivo | 1. Seleccionar dispositivo<br>2. Clic "Bloquear"<br>3. Confirmar | Dispositivo cambia a estado "bloqueado" |
| S04 | Operación masiva | 1. Ir a Operaciones Masivas<br>2. Seleccionar dispositivos<br>3. Confirmar bloqueo | Múltiples dispositivos bloqueados |
| S05 | Ver historial de pagos | Seleccionar préstamo y ver historial | Muestra pagos (solo lectura) |
| S06 | Generar reporte | 1. Ir a Reportes<br>2. Seleccionar periodo<br>3. Exportar | Descarga PDF/Excel |
| S07 | Intento de registrar pago | Navegar a sección de pagos | No tiene acceso o botones deshabilitados |
| S08 | Intento de acceso admin | Navegar a /admin/users | Redirigido o error de autorización |

---

## 5. Rol: Administrador

![Admin Workflow](images/manual/admin-workflow.gif)

### 5.1 Descripción del Rol

El **Administrador** tiene acceso completo al sistema:
- Gestión de usuarios (crear, editar, eliminar)
- Gestión de clientes y préstamos
- Verificación de pagos
- Bloqueo/desbloqueo de dispositivos
- Configuración del sistema
- Reportes y auditoría
- Catálogo de teléfonos
- Monitoreo de jobs en background

### 5.2 Acceso al Sistema

1. Ir a `/login`
2. Ingresar: `admin@movicuotas.com` / `password123`
3. El sistema redirige a: **Dashboard de Administrador** (`/admin/dashboard`)

### 5.3 Pantalla Principal: Dashboard de Administrador

**URL:** `/admin/dashboard`

**Contenido:**
- **Usuarios:** Total, por rol, activos últimos 30 días
- **Clientes:** Total, con préstamos activos, suspendidos, bloqueados
- **Préstamos:** Total, activos, completados, en mora, valor total
- **Pagos:** Total recaudado, ingresos, monto en mora
- **Dispositivos:** Total, asignados, disponibles
- **Estadísticas por Sucursal**
- **Listas recientes:** Préstamos, pagos, usuarios

### 5.4 Menú de Navegación

| Sección | Descripción | URL |
|---------|-------------|-----|
| Dashboard | Resumen ejecutivo | `/admin/dashboard` |
| Gestión de Usuarios | CRUD de usuarios | `/admin/users` |
| Gestión de Clientes | CRUD de clientes | `/admin/customers` |
| Gestión de Contratos | Ver contratos | `/admin/contracts` |
| Catálogo de Teléfonos | Gestión de modelos | `/admin/phone_models` |
| QR por Defecto | Configurar QR MDM | `/admin/default_qr_codes` |
| Reportes del Sistema | Análisis y métricas | `/admin/reports` |
| Préstamos y Pagos | Gestión de préstamos | `/admin/loans` |
| Dispositivos | Gestión de dispositivos | `/admin/devices` |
| Monitoreo de Jobs | Jobs en background | `/admin/jobs` |
| Auditoría | Logs de acciones | `/admin/audit_logs` |
| Primas Pendientes | Verificar depósitos | `/admin/down_payments` |

### 5.5 Funcionalidades del Administrador

#### 5.5.1 Gestión de Usuarios
- **URL:** `/admin/users`
- **Acciones:**
  - Crear nuevo usuario (vendedor, supervisor, admin)
  - Editar usuario existente
  - Eliminar usuario
  - Asignar sucursal

#### 5.5.2 Gestión de Clientes
- **URL:** `/admin/customers`
- **Acciones:**
  - Ver todos los clientes
  - Editar información del cliente
  - Eliminar cliente (si no tiene préstamos activos)
  - Bloquear/desbloquear cliente

#### 5.5.3 Gestión de Préstamos
- **URL:** `/admin/loans`
- **Acciones:**
  - Ver todos los préstamos
  - Ver detalle de préstamo
  - Ver historial de pagos

#### 5.5.4 Verificación de Pagos
- **URL:** `/admin/payments`
- **Acciones:**
  - Ver todos los pagos
  - Verificar pago (aprobar comprobante)
  - Rechazar pago (con motivo)
  - Ver comprobante de pago

#### 5.5.5 Gestión de Dispositivos
- **URL:** `/admin/devices`
- **Acciones:**
  - Ver todos los dispositivos
  - Bloquear dispositivo
  - Desbloquear dispositivo
  - Reset de activación

#### 5.5.6 Catálogo de Teléfonos
- **URL:** `/admin/phone_models`
- **Acciones:**
  - Crear modelo de teléfono
  - Editar modelo (nombre, precio, imagen)
  - Activar/desactivar modelo
  - Eliminar modelo

#### 5.5.7 Reportes del Sistema
- **URL:** `/admin/reports`
- **Tipos de reportes:**
  - Análisis por sucursal
  - Reporte de ingresos
  - Portafolio de clientes
  - Exportar reportes (PDF/Excel)

#### 5.5.8 Auditoría
- **URL:** `/admin/audit_logs`
- **Contenido:**
  - Registro de todas las acciones del sistema
  - Filtros por usuario, acción, fecha
  - Detalles de cambios realizados

#### 5.5.9 Monitoreo de Jobs
- **URL:** `/admin/jobs`
- **Acciones:**
  - Ver jobs en cola
  - Ver jobs completados/fallidos
  - Reintentar jobs fallidos
  - Cancelar jobs pendientes

#### 5.5.10 Verificación de Primas (Down Payments)
- **URL:** `/admin/down_payments`
- **Acciones:**
  - Ver depósitos pendientes de verificación
  - Verificar depósito (aprobar)
  - Rechazar depósito (con motivo)

### 5.6 Acceso Completo del Administrador

| Acción | Permitido |
|--------|-----------|
| Crear usuarios | ✅ |
| Editar usuarios | ✅ |
| Eliminar usuarios | ✅ |
| Crear clientes | ✅ |
| Editar clientes | ✅ |
| Eliminar clientes | ✅ |
| Bloquear clientes | ✅ |
| Ver todos los préstamos | ✅ |
| Editar préstamos | ✅ |
| Eliminar préstamos | ✅ |
| Ver todos los pagos | ✅ |
| Verificar pagos | ✅ |
| Rechazar pagos | ✅ |
| Eliminar pagos | ✅ |
| Bloquear dispositivos | ✅ |
| Desbloquear dispositivos | ✅ |
| Eliminar dispositivos | ✅ |
| Ver reportes globales | ✅ |
| Exportar reportes | ✅ |
| Configuración del sistema | ✅ |
| Ver logs de auditoría | ✅ |
| Monitorear jobs | ✅ |

### 5.7 Casos de Prueba - Administrador

| ID | Caso de Prueba | Pasos | Resultado Esperado |
|----|----------------|-------|-------------------|
| A01 | Login exitoso | 1. Ir a /login<br>2. Ingresar credenciales<br>3. Clic en "Iniciar Sesión" | Redirige a /admin/dashboard |
| A02 | Crear usuario | 1. Ir a Gestión de Usuarios<br>2. Clic "Nuevo Usuario"<br>3. Completar formulario<br>4. Guardar | Usuario creado exitosamente |
| A03 | Editar usuario | 1. Seleccionar usuario<br>2. Editar datos<br>3. Guardar | Cambios guardados |
| A04 | Eliminar usuario | 1. Seleccionar usuario<br>2. Clic "Eliminar"<br>3. Confirmar | Usuario eliminado |
| A05 | Verificar pago | 1. Ir a Pagos<br>2. Seleccionar pago pendiente<br>3. Ver comprobante<br>4. Clic "Verificar" | Pago marcado como verificado |
| A06 | Rechazar pago | 1. Ir a Pagos<br>2. Seleccionar pago<br>3. Clic "Rechazar"<br>4. Ingresar motivo | Pago rechazado con motivo |
| A07 | Bloquear dispositivo | 1. Ir a Dispositivos<br>2. Seleccionar dispositivo<br>3. Clic "Bloquear" | Dispositivo bloqueado |
| A08 | Desbloquear dispositivo | 1. Ir a Dispositivos<br>2. Seleccionar dispositivo bloqueado<br>3. Clic "Desbloquear" | Dispositivo desbloqueado |
| A09 | Crear modelo de teléfono | 1. Ir a Catálogo<br>2. Clic "Nuevo Modelo"<br>3. Completar datos<br>4. Guardar | Modelo creado |
| A10 | Ver logs de auditoría | 1. Ir a Auditoría<br>2. Aplicar filtros | Muestra registro de acciones |
| A11 | Exportar reporte | 1. Ir a Reportes<br>2. Seleccionar tipo<br>3. Clic "Exportar" | Descarga archivo |
| A12 | Monitorear jobs | 1. Ir a Jobs<br>2. Ver cola de trabajos | Muestra jobs pendientes/completados |

---

## 6. Matriz de Permisos

### 6.1 Resumen de Permisos por Rol

| Funcionalidad | Vendedor | Supervisor | Admin |
|---------------|:--------:|:----------:|:-----:|
| **Gestión de Clientes** |
| Ver clientes | ✅ | ✅ (lectura) | ✅ |
| Crear clientes | ✅ | ❌ | ✅ |
| Editar clientes | ✅ | ❌ | ✅ |
| Eliminar clientes | ❌ | ❌ | ✅ |
| Bloquear clientes | ❌ | ❌ | ✅ |
| **Créditos y Préstamos** |
| Crear solicitud de crédito | ✅ | ❌ | ✅ |
| Ver préstamos | ✅ (propios) | ✅ (todos) | ✅ |
| Editar préstamos | ✅ (propios) | ❌ | ✅ |
| Eliminar préstamos | ❌ | ❌ | ✅ |
| **Pagos** |
| Ver pagos | ✅ | ✅ (lectura) | ✅ |
| Registrar pago | ✅ | ❌ | ✅ |
| Verificar pago | ❌ | ❌ | ✅ |
| Eliminar pago | ❌ | ❌ | ✅ |
| **Dispositivos** |
| Ver dispositivos | ✅ | ✅ (en mora) | ✅ |
| Asignar dispositivo | ✅ | ❌ | ✅ |
| Bloquear dispositivo | ❌ | ✅ | ✅ |
| Desbloquear dispositivo | ❌ | ❌ | ✅ |
| **Reportes** |
| Ver todos los reportes | ❌ | ❌ | ✅ |
| Ver propias ventas | ✅ | ❌ | ✅ |
| Ver reportes de cobranza | ❌ | ✅ | ✅ |
| Exportar reportes | ✅ (propios) | ✅ (cobranza) | ✅ |
| **Usuarios** |
| Ver usuarios | ❌ | ❌ | ✅ |
| Crear usuarios | ❌ | ❌ | ✅ |
| Editar usuarios | ❌ | ❌ | ✅ |
| Eliminar usuarios | ❌ | ❌ | ✅ |
| **Sistema** |
| Configuración | ❌ | ❌ | ✅ |
| Ver auditoría | ❌ | ❌ | ✅ |
| Monitorear jobs | ❌ | ❌ | ✅ |

### 6.2 Acceso por URL

| URL Base | Vendedor | Supervisor | Admin |
|----------|:--------:|:----------:|:-----:|
| `/vendor/*` | ✅ | ❌ | ✅ |
| `/supervisor/*` | ❌ | ✅ | ✅ |
| `/admin/*` | ❌ | ❌ | ✅ |

---

## 7. Flujos de Trabajo Principales

### 7.1 Flujo de Venta (Vendedor)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Login     │────▶│   Buscar    │────▶│  Cliente    │
│             │     │   Cliente   │     │  Disponible │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┘
                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Datos     │────▶│   Fotos     │────▶│   Datos     │
│  Generales  │     │  Identidad  │     │  Laborales  │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┘
                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Resumen    │────▶│  Aprobación │────▶│  Selección  │
│  Solicitud  │     │  Automática │     │  Teléfono   │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┘
                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Calculadora │────▶│  Contrato   │────▶│   Firma     │
│   Pagos     │     │             │     │  Digital    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┘
                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Éxito     │────▶│  Código QR  │────▶│  Checklist  │
│   Crédito   │     │    MDM      │     │   Final     │
└─────────────┘     └─────────────┘     └─────────────┘
```

### 7.2 Flujo de Cobranza (Supervisor)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Dashboard  │────▶│ Dispositivos│────▶│  Detalle    │
│  Supervisor │     │  en Mora    │     │ Dispositivo │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                           ┌───────────────────┴───────────────────┐
                           ▼                                       ▼
                    ┌─────────────┐                         ┌─────────────┐
                    │  Bloquear   │                         │  Ver        │
                    │ Dispositivo │                         │  Historial  │
                    └──────┬──────┘                         └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Confirmar  │
                    │   Bloqueo   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Notificar  │
                    │   Cliente   │
                    └─────────────┘
```

### 7.3 Flujo de Verificación de Pagos (Admin)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Dashboard  │────▶│   Pagos     │────▶│   Ver       │
│    Admin    │     │  Pendientes │     │ Comprobante │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                           ┌───────────────────┴───────────────────┐
                           ▼                                       ▼
                    ┌─────────────┐                         ┌─────────────┐
                    │  Verificar  │                         │  Rechazar   │
                    │    Pago     │                         │    Pago     │
                    └──────┬──────┘                         └──────┬──────┘
                           │                                       │
                           ▼                                       ▼
                    ┌─────────────┐                         ┌─────────────┐
                    │   Cuota     │                         │  Registrar  │
                    │   Pagada    │                         │   Motivo    │
                    └─────────────┘                         └─────────────┘
```

---

## Anexos

### A. Códigos de Error Comunes

| Código | Mensaje | Solución |
|--------|---------|----------|
| 401 | No autorizado | Iniciar sesión nuevamente |
| 403 | Acceso denegado | Verificar permisos del rol |
| 404 | No encontrado | Verificar que el recurso existe |
| 422 | Datos inválidos | Revisar campos del formulario |

### B. Contacto de Soporte

- **Email:** admin@taphn.com
- **Teléfono:** +504 89978918

### C. Historial de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | Enero 2026 | Versión inicial del manual |

---

**© 2026 MOVICUOTAS - Sistema de Crédito para Móviles**
