# API: Activación de Dispositivos

## Endpoint

```
POST /api/v1/devices/activate
```

**Sin autenticación requerida** (el código de activación actúa como credencial)

## Request

```json
{
  "activation_code": "A1B2C3",
  "fcm_token": "firebase_cloud_messaging_token...",
  "platform": "android",
  "device_name": "Samsung Galaxy S21"
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `activation_code` | string(6) | Sí | Código alfanumérico uppercase (ej: A1B2C3) |
| `fcm_token` | string | Sí | Token de Firebase Cloud Messaging |
| `platform` | string | No | "android" o "ios" (default: "android") |
| `device_name` | string | No | Nombre/modelo del dispositivo |

## Responses

### 200 OK - Activación exitosa

```json
{
  "message": "Dispositivo activado correctamente",
  "activated_at": "2026-01-22T14:30:00Z",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "customer": {
    "id": 123,
    "full_name": "Juan Pérez",
    "phone": "99887766"
  },
  "loan": {
    "id": 456,
    "contract_number": "S01-2026-01-22-000001",
    "total_amount": 15000.00,
    "remaining_balance": 12500.00,
    "status": "active",
    "next_payment_date": "2026-02-05",
    "next_payment_amount": 1250.00
  }
}
```

**Nota**: El campo `token` es un JWT válido por 30 días. La app debe guardarlo en almacenamiento seguro y usarlo para autenticar llamadas a la API.

### 400 Bad Request - Falta FCM token

```json
{
  "success": false,
  "error": "Token FCM requerido"
}
```

### 404 Not Found - Código inválido

```json
{
  "success": false,
  "error": "Codigo de activacion invalido"
}
```

### 422 Unprocessable Entity - Ya activado

```json
{
  "success": false,
  "error": "Este dispositivo ya fue activado"
}
```

## Flujo de Activación

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP MÓVIL                                 │
├─────────────────────────────────────────────────────────────────┤
│  1. Usuario abre la app por primera vez                         │
│  2. No tiene JWT guardado → Muestra pantalla de activación      │
│  3. Usuario ingresa código de 6 caracteres (del contrato)       │
│  4. App obtiene FCM token de Firebase                           │
│  5. App envía POST /api/v1/devices/activate                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         BACKEND                                  │
├─────────────────────────────────────────────────────────────────┤
│  1. Busca Device por activation_code                            │
│  2. Verifica que no esté ya activado                            │
│  3. Crea/actualiza DeviceToken con FCM token                    │
│  4. Marca Device como activado (activated_at = now)             │
│  5. Genera JWT token para el customer                           │
│  6. Retorna token, datos del cliente y préstamo                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        APP MÓVIL                                 │
├─────────────────────────────────────────────────────────────────┤
│  7. Guarda JWT token en almacenamiento seguro                   │
│  8. Guarda datos del cliente/préstamo localmente               │
│  9. Navega al Dashboard principal (sin login adicional)         │
│ 10. Ahora puede recibir notificaciones push                    │
└─────────────────────────────────────────────────────────────────┘
```

## Modelo de Datos

### Device (existente)

```ruby
# app/models/device.rb
class Device < ApplicationRecord
  # Campos relevantes para activación:
  # - activation_code: string(6) - Código único generado al crear el device
  # - activated_at: datetime - Cuándo se activó (null si no activado)

  has_many :device_tokens, dependent: :nullify

  def activate!
    update!(activated_at: Time.current)
  end

  def activated?
    activated_at.present?
  end
end
```

### DeviceToken (existente)

```ruby
# app/models/device_token.rb
class DeviceToken < ApplicationRecord
  # Campos:
  # - token: string - FCM token
  # - platform: string - android/ios
  # - device_name: string - Nombre del dispositivo
  # - device_id: FK - Dispositivo asociado
  # - customer_id: FK - Cliente asociado
  # - active: boolean - Si el token está activo
  # - last_used_at: datetime - Última vez usado

  belongs_to :device, optional: true
  belongs_to :customer, optional: true
end
```

## Testing con cURL

```bash
# Activar un dispositivo
curl -X POST https://movicuotas.com/api/v1/devices/activate \
  -H "Content-Type: application/json" \
  -d '{
    "activation_code": "A1B2C3",
    "fcm_token": "test_fcm_token_123",
    "platform": "android",
    "device_name": "Test Device"
  }'
```

## Vista en Admin

Los dispositivos activados se pueden ver en:
- **Admin → Dispositivos** (`/admin/devices`)
- Filtro "Activados" muestra solo los que tienen `activated_at` presente
- La columna "Activado" muestra la fecha de activación

## Notas Importantes

1. **Código de activación único**: Generado automáticamente al crear el Device (6 caracteres alfanuméricos uppercase)

2. **Una sola activación**: Actualmente un dispositivo solo se puede activar una vez. Si el cliente cambia de teléfono o reinstala la app, el admin debe:
   - Limpiar `activated_at` del Device para permitir re-activación
   - O crear un nuevo Device con nuevo código

3. **FCM Token**: Se guarda para enviar notificaciones push sobre:
   - Recordatorios de pago
   - Confirmaciones de pago
   - Notificaciones de mora

4. **Seguridad**: El código de activación es efectivamente una credencial de un solo uso. No se debe compartir públicamente.
