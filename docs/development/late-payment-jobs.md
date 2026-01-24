# Payment Notification Jobs

## Overview

The payment notification system uses two main jobs that run daily at 8:00 AM Honduras time to send push notifications to customers about their installment payments.

## Jobs

### 1. PaymentReminderNotificationJob

**Schedule**: Daily at 8:00 AM (America/Tegucigalpa)
**Queue**: `reminders`
**Priority**: High

Sends payment reminders to customers **before** their installments are due.

**Notification Schedule:**

| Days Before | Title | Message |
|-------------|-------|---------|
| 3 días | Recordatorio de Pago | "Tu próxima cuota vence en 3 días. Monto: L. {amount}, Fecha: {date}" |
| 1 día | Pago Mañana | "Mañana vence tu cuota. Evita atrasos pagando L. {amount} a tiempo" |
| 0 días | Pago Hoy | "Hoy vence tu cuota. Paga hoy L. {amount} y mantén tu teléfono activo." |

**How it works:**
1. Queries `Installment.pending` with `due_date` matching today + N days
2. Creates a `Notification` record for each matching installment
3. `SendPushNotificationJob` sends the FCM push automatically via callback

---

### 2. OverduePaymentNotificationJob

**Schedule**: Daily at 8:00 AM (America/Tegucigalpa)
**Queue**: `reminders`
**Priority**: High

Sends notifications to customers **after** their installments become overdue.

**Notification Schedule:**

| Days After | Title | Message |
|------------|-------|---------|
| 1 día | Cuota Vencida | "Tu cuota está vencida. Ponte al día para evitar restricciones en tu dispositivo." |
| 3 días | Aviso Importante | "Tu dispositivo puede estar restringido. ¿Necesitas ayuda? Contáctanos." |

**How it works:**
1. Queries `Installment.overdue` with `due_date` matching today - N days
2. Creates a `Notification` record for each matching installment
3. `SendPushNotificationJob` sends the FCM push automatically via callback

---

### 3. MarkInstallmentsOverdueJob

**Schedule**: Daily at 12:01 AM
**Queue**: `reminders`
**Priority**: High

Marks pending installments as overdue when their due date has passed.

**Business Logic:**
```ruby
Installment.pending.where("due_date < ?", Date.today).find_each do |installment|
  installment.mark_as_overdue
end
```

This job runs at midnight to ensure installments are marked as overdue before the notification jobs run at 8:00 AM.

---

## Execution Sequence

```
00:01 ► MarkInstallmentsOverdueJob
        Identifies and marks overdue installments
        └─ Updates status from 'pending' to 'overdue'

08:00 ► PaymentReminderNotificationJob
        Sends reminders for upcoming payments
        └─ 3 days before, 1 day before, day of payment

08:00 ► OverduePaymentNotificationJob
        Sends notifications for overdue payments
        └─ 1 day after, 3 days after
```

---

## Configuration

### Recurring Jobs (`config/recurring.yml`)

```yaml
production:
  mark_installments_overdue:
    class: MarkInstallmentsOverdueJob
    queue: reminders
    schedule: at 12:01am every day
    description: "Mark past-due installments as overdue and update loan status"

  payment_reminder_notifications:
    class: PaymentReminderNotificationJob
    queue: reminders
    schedule: at 8am every day America/Tegucigalpa
    description: "Envía recordatorios de pago 3 días antes, 1 día antes, y el día del vencimiento"

  overdue_payment_notifications:
    class: OverduePaymentNotificationJob
    queue: reminders
    schedule: at 8am every day America/Tegucigalpa
    description: "Envía notificaciones a clientes con cuotas vencidas (1 y 3 días después)"
```

---

## Device Blocking

Device blocking is done **manually** by employees through the supervisor dashboard. There is no automatic device blocking integration in the system.

When a loan is significantly overdue (30+ days), employees can:
1. View overdue loans in the cobrador/supervisor dashboard
2. Manually block devices through the MDM system
3. Update the device status in the system

---

## Manual Execution

All jobs can be triggered manually from `/admin/jobs`:

- **Marcar Cuotas Vencidas** - Mark overdue installments
- **Recordatorios de Pago** - Send payment reminders
- **Notificaciones de Mora** - Send overdue notifications

---

## Notification Delivery

All notifications use **FCM (Firebase Cloud Messaging)** push notifications delivered to the Flutter mobile app.

**Flow:**
1. Job creates `Notification` record with `delivery_method: "fcm"`
2. `after_create_commit` callback triggers `SendPushNotificationJob`
3. `FcmService` sends push to customer's registered device tokens
4. Notification status updated to `delivered` or `failed`

---

**Last Updated**: January 2026
