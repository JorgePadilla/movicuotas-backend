# Late Payment Jobs System - Phase 5

## Overview

The Late Payment Jobs System is a comprehensive background job architecture that automatically manages overdue payment detection, customer notifications, cobrador reporting, and device blocking. All jobs are powered by **Solid Queue** with strategic scheduling to create an efficient collection workflow.

## Architecture

### Job Queue Configuration

All jobs are configured in `config/solid_queue.yml` with queue-based priorities:

```yaml
processes:
  - host: localhost
    queues: [ default, mailers, notifications, reminders, blocking ]
    concurrency: 5
    polling_interval: 0.1
```

### Queue Priority Levels

| Queue | Concurrency | Use Case | Priority |
|-------|-------------|----------|----------|
| `reminders` | 5 | Overdue identification | High |
| `notifications` | 10 | Customer & cobrador alerts | High |
| `blocking` | 3 | Device blocking operations | Critical (limited) |
| `default` | 5 | Late fees & maintenance | Standard |

## Jobs Overview

### 1. MarkInstallmentsOverdueJob

**Schedule**: Daily at 12:00 AM (midnight)
**Queue**: `reminders`
**Priority**: High

**Responsibility**:
- Identifies pending installments with past due dates
- Marks them as `overdue` in the database
- Triggers cascading loan status updates

**Business Logic**:
```ruby
Installment.pending.where("due_date < ?", Date.today).each do |inst|
  inst.mark_as_overdue  # Updates status and triggers loan update
end
```

**Key Features**:
- ✅ Automatic status transition
- ✅ Callback-triggered loan updates
- ✅ Idempotent (safe to run multiple times)
- ✅ Handles bulk updates efficiently

**Error Handling**:
- Logs individual installation errors
- Continues processing remaining installments
- Notifies error monitoring system

---

### 2. SendOverdueNotificationJob

**Schedule**: Daily at 12:15 AM (midnight + 15 minutes)
**Queue**: `notifications`
**Priority**: High

**Responsibility**:
- Sends customer notifications at overdue milestones (1, 7, 14, 30+ days)
- Respects customer notification preferences
- Respects quiet hours settings
- Escalates warnings at critical thresholds

**Customer Notification Milestones**:

| Days | Message | Escalation |
|------|---------|-----------|
| 1 | "Tu pago está vencido..." | Standard |
| 7 | "Tu pago lleva 7 días en mora..." | Standard |
| 14 | "Aviso importante: Tu dispositivo será bloqueado..." | Medium |
| 30+ | "Tu dispositivo será bloqueado hoy..." | Critical (device_blocking_alert) |

**Preference Validation**:
```ruby
preference.can_receive_notification?("overdue_warning") && !preference.in_quiet_hours?
```

**Notification Data Structure**:
```ruby
{
  days_overdue: 7,
  installment_count: 2,
  total_amount: 250.50
}
```

**Key Features**:
- ✅ Multi-channel delivery (FCM/SMS)
- ✅ Preference-aware (opt-out supported)
- ✅ Quiet hours respected (no 10 PM - 7 AM notifications)
- ✅ Escalation warnings at 30+ days
- ✅ Idempotent design

---

### 3. SendLatePaymentWarningJob

**Schedule**: Daily at 6:00 AM
**Queue**: `notifications`
**Priority**: High

**Responsibility**:
- Sends escalating warning messages at specific thresholds
- Focuses on impending actions (pre-blocking warnings)
- Distinct from overdue notifications (more aggressive messaging)

**Warning Thresholds**:

| Days | Warning Level | Message Focus | Type |
|------|---------------|---------------|------|
| 3 | Info | Payment approaching | payment_reminder |
| 7 | Warning | Days in mora | overdue_warning |
| 14 | Urgent | Device at risk | overdue_warning |
| 27 | Critical | **3 DAYS UNTIL BLOCK** | device_lock |

**Message Templates**:
```
Day 3:  "Tu pago está próximo a vencer. Monto: L. 250.00. ¡Paga ahora!"
Day 7:  "Tu pago lleva 7 días en mora. Evita cargos adicionales."
Day 14: "IMPORTANTE: Tu dispositivo corre peligro de bloqueo."
Day 27: "⚠️ CRÍTICO: Tu dispositivo será BLOQUEADO en 3 DÍAS. ¡PAGA AHORA!"
```

**Key Features**:
- ✅ Threshold-based (only sends on specific days)
- ✅ Escalating urgency
- ✅ Pre-emptive blocking warnings
- ✅ Preference and quiet hour compliance
- ✅ High visibility critical warnings

---

### 4. NotifyCobradorosJob

**Schedule**: Daily at 7:00 AM
**Queue**: `notifications`
**Priority**: High

**Responsibility**:
- Sends daily collection summary to all cobradores
- Provides actionable metrics and insights
- Groups overdue accounts by age range

**Daily Report Contents**:

```
📊 Reporte de Mora - 01/01/2026

💰 Total en Mora: L. 45,234.50
📦 Cuotas en mora: 156

Desglose por antigüedad:
• 1-7 días: 45 cuotas (L. 12,300.00)
• 8-15 días: 38 cuotas (L. 10,500.00)
• 16-30 días: 42 cuotas (L. 11,200.00)
• 30+ días: 31 cuotas (L. 11,234.50)

🔒 Dispositivos bloqueados: 28
⏳ Bloqueos pendientes: 5
🆕 Bloqueados hoy: 3
```

**Metrics Calculated**:
```ruby
{
  total_overdue_count: 156,
  total_overdue_amount: 45234.50,
  by_days: {
    "1_to_7": { count: 45, amount: 12300.00 },
    "8_to_15": { count: 38, amount: 10500.00 },
    "16_to_30": { count: 42, amount: 11200.00 },
    "30_plus": { count: 31, amount: 11234.50 }
  },
  blocked_devices_count: 28,
  pending_blocks_count: 5,
  blocked_today_count: 3
}
```

**Key Features**:
- ✅ Daily summary for all cobradores
- ✅ Actionable metrics breakdown
- ✅ Device blocking tracking
- ✅ Recent blocking activity
- ✅ Drives collection activities

**Audience**: All users with `role: "cobrador"`

---

### 5. AutoBlockDeviceJob

**Schedule**: Daily at 8:00 AM
**Queue**: `blocking`
**Priority**: Critical (limited concurrency: 3)

**Responsibility**:
- Automatically blocks devices 30+ days overdue
- Uses MdmBlockService for authorization and audit logging
- Sends device blocking notifications to customers
- Updates device status from `unlocked` → `pending` → `locked`

**Blocking Criteria**:
```sql
-- Devices with 30+ days overdue installments
SELECT DISTINCT devices.*
FROM devices
JOIN loans ON devices.loan_id = loans.id
JOIN installments ON loans.id = installments.loan_id
WHERE installments.status = 'overdue'
  AND (CURRENT_DATE - installments.due_date) >= 30
  AND devices.lock_status IN ('unlocked', NULL)
```

**Device State Transitions**:
```
unlocked → [MdmBlockService.block!] → pending → [MDM API] → locked
                                      ↓
                            [Send Notification]
                            [Create Audit Log]
```

**Notification Sent**:
```ruby
Notification.create!(
  customer: customer,
  title: "Tu dispositivo ha sido bloqueado",
  message: "Tu dispositivo ha sido bloqueado debido a mora...",
  notification_type: "device_blocking_alert",
  delivery_method: "fcm",
  status: "pending"
)
```

**Audit Trail**:
```ruby
AuditLog.create!(
  user: system_user,
  action: "device_block_requested",
  resource_type: "Device",
  resource_id: device.id,
  change_details: {
    reason: "Overdue payment",
    overdue_days: 35,
    overdue_amount: 500.00
  }
)
```

**Key Features**:
- ✅ Automatic blocking at 30-day threshold
- ✅ Authorization checks via MdmBlockService
- ✅ Audit logging for compliance
- ✅ Customer notification
- ✅ Error handling (continues if one device fails)
- ✅ Idempotent (won't re-block already locked devices)
- ✅ Limited concurrency (prevents MDM API overload)

**System User**:
- Creates/uses `system@movicuotas.local` user for automated actions
- Full admin role for MDM operations

---

### 6. CalculateLateFeesJob

**Schedule**: Weekly on Monday at 12:00 AM
**Queue**: `default`
**Priority**: Standard

**Status**: 🔴 **BUSINESS DECISION PENDING** - Infrastructure ready, no fees applied yet

**Responsibility**:
- Framework ready for late fee calculation when business defines rules
- Job runs on schedule but does NOT apply fees
- Database fields prepared for future implementation
- Infrastructure ready for audit logging

**Current Status**:
The job is scheduled and running, but **NO LATE FEES are being calculated or applied** because business rules have not been defined yet.

**Pending Business Decisions**:
1. **When should fees start?** (e.g., 7 days overdue, 14 days, 30 days)
2. **How should they be calculated?**
   - Fixed amount per period?
   - Percentage of overdue amount?
   - Tiered based on days overdue?
3. **What are the limits/caps?**
   - Minimum fee per installment?
   - Maximum fee per installment?
   - Maximum as percentage of original amount?
4. **How often should they compound?**
   - Once only?
   - Weekly?
   - Monthly?
   - Daily?
5. **Customer notifications?**
   - Notify customers when fees are applied?
   - Include fees in overdue warnings?
   - Separate notification?

**Implementation Ready When Business Rules Defined**:

Once the business team defines late fee rules, implementation is straightforward:

```ruby
# 1. Uncomment the implementation in app/jobs/calculate_late_fees_job.rb
# 2. Update the calculate_late_fee_amount method with your rules
# 3. Update tests to verify calculations
# 4. Deploy

# Example implementation (to be customized):
def calculate_late_fee_amount(installment, days_overdue)
  # DEFINE YOUR BUSINESS RULES HERE:
  # base_fee = ...
  # max_fee = ...
  # return [base_fee, max_fee].min
end
```

**Database Fields Ready**:
```sql
-- These fields exist and are ready for late fee tracking:
ALTER TABLE installments ADD COLUMN late_fee_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE installments ADD COLUMN late_fee_calculated_at TIMESTAMP;
```

**Audit Trail Ready**:
```ruby
# When business rules are defined, this audit log will be created:
AuditLog.create!(
  user_id: system_user.id,
  action: "late_fee_calculated",
  resource_type: "Installment",
  resource_id: installment.id,
  change_details: {
    late_fee_amount: 5.0,
    days_overdue: 15,
    original_amount: 100.0,
    new_total: 105.0
  }
)
```

**Key Features (Ready for Implementation)**:
- ✅ Job scheduled weekly
- ✅ Database fields prepared
- ✅ Audit log infrastructure ready
- ✅ Error handling framework in place
- ✅ Code comments document implementation steps
- ⏳ Calculation logic waiting for business input

---

## Execution Schedule

### Daily Job Sequence

```timeline
00:00 - MarkInstallmentsOverdueJob
        └─ Identifies pending installments with past due dates
        └─ Marks them as overdue
        └─ Updates loan statuses

00:15 - SendOverdueNotificationJob
        └─ Sends notifications at milestone days (1, 7, 14, 30+)
        └─ Respects customer preferences
        └─ Escalates warnings at critical thresholds

06:00 - SendLatePaymentWarningJob
        └─ Sends escalating warnings (3, 7, 14, 27 days)
        └─ Pre-emptive blocking warnings
        └─ Highest urgency at day 27

07:00 - NotifyCobradorosJob
        └─ Sends daily collection report to all cobradores
        └─ Includes actionable metrics
        └─ Drives collection activities

08:00 - AutoBlockDeviceJob
        └─ Auto-blocks devices 30+ days overdue
        └─ Sends notifications to customers
        └─ Creates audit logs

00:00 (Monday) - CalculateLateFeesJob
                 └─ Calculates weekly late fees
                 └─ Applies to 7+ days overdue
                 └─ Creates audit trail
```

### Key Dependencies

```
MarkInstallmentsOverdueJob (00:00)
        ↓ (15 minutes)
SendOverdueNotificationJob (00:15)
        ↓ (5 hours 45 minutes)
SendLatePaymentWarningJob (06:00)
        ↓ (1 hour)
NotifyCobradorosJob (07:00)
        ↓ (1 hour)
AutoBlockDeviceJob (08:00)
```

---

## Database Schema Changes

### Installments Table
```sql
ALTER TABLE installments ADD COLUMN late_fee_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE installments ADD COLUMN late_fee_calculated_at TIMESTAMP;
CREATE INDEX idx_installments_overdue_fee_calculation
  ON installments(status, late_fee_calculated_at);
```

### Devices Table
```sql
ALTER TABLE devices ADD COLUMN auto_block_notified_at TIMESTAMP;
CREATE INDEX idx_devices_auto_block_tracking
  ON devices(lock_status, auto_block_notified_at);
```

---

## Configuration

### Solid Queue Configuration

**File**: `config/solid_queue.yml`

```yaml
production:
  processes:
    # Standard queues
    - host: localhost
      queues: [ default, mailers ]
      concurrency: 5
      polling_interval: 0.1

    # Notification queue (high volume)
    - host: localhost
      queues: [ notifications, reminders ]
      concurrency: 10
      polling_interval: 0.1

    # Blocking queue (rate limited)
    - host: localhost
      queues: [ blocking ]
      concurrency: 3
      polling_interval: 0.1
```

### Recurring Jobs Configuration

**File**: `config/recurring.yml`

See job scheduler configuration with exact schedule times and descriptions.

### Notification Preferences

Users can control overdue notifications via `NotificationPreference`:

```ruby
preference = user.notification_preference

preference.overdue_warnings = true/false
preference.receive_fcm_notifications = true/false
preference.receive_sms_notifications = true/false
preference.quiet_hours_start = "22:00"
preference.quiet_hours_end = "07:00"
```

---

## Testing

### Test Structure

```
test/jobs/
├── mark_installments_overdue_job_test.rb
├── send_overdue_notification_job_test.rb
├── notify_cobradores_job_test.rb
├── auto_block_device_job_test.rb
├── send_late_payment_warning_job_test.rb
└── calculate_late_fees_job_test.rb
```

### Running Tests

```bash
# All job tests
bin/rails test test/jobs/

# Specific job test
bin/rails test test/jobs/mark_installments_overdue_job_test.rb

# With verbose output
bin/rails test test/jobs/ -v
```

### Test Coverage

- **Unit Tests**: Individual job logic
- **Integration Tests**: Multi-job sequences
- **Preference Tests**: Notification compliance
- **Error Handling**: Graceful failure
- **Idempotency Tests**: Safe re-runs
- **Data Integrity**: Audit logs and calculations

---

## Monitoring & Troubleshooting

### Job Monitoring

```bash
# View Solid Queue dashboard (if available)
bin/rails routes | grep solid_queue

# Check job status
SolidQueue::Job.recent.limit(10)

# Check failed jobs
SolidQueue::Job.failed.order(created_at: :desc)
```

### Common Issues

#### 1. Jobs Not Running

**Cause**: Solid Queue process not running
**Solution**:
```bash
# Start Solid Queue in development
bundle exec solid_queue start

# Or with foreman
bin/dev
```

#### 2. Duplicate Notifications

**Cause**: Job ran multiple times
**Solution**: Use idempotency checks in job logic

#### 3. System User Not Found

**Cause**: `system@movicuotas.local` user doesn't exist
**Solution**: Job creates it automatically on first run

#### 4. MDM Blocking Failures

**Cause**: MdmBlockService errors
**Solution**: Check MdmBlockService logs; job continues processing other devices

### Error Logs

All jobs log to:
```
log/
├── development.log
├── production.log
└── solid_queue.log
```

---

## Late Fee Configuration

### Current Settings

```ruby
LATE_FEE_PERCENTAGE = 5          # 5% of overdue amount
LATE_FEE_MAX_PERCENTAGE = 20     # Cap at 20% of original amount
CALCULATION_INTERVAL_DAYS = 7    # Run weekly (7 day minimum)
```

### Business Review

These settings should be reviewed and adjusted with business stakeholders:

- Should late fees be applied daily, weekly, or monthly?
- Should the percentage be fixed or tiered (by days overdue)?
- Should there be a grace period before fees apply?
- Should notification preferences affect fee calculation?

---

## Phase 5 Completion Checklist

- ✅ 6 background jobs implemented
- ✅ Solid Queue integration complete
- ✅ Job scheduling configured
- ✅ Database migrations created
- ✅ Comprehensive test suite (40+ tests)
- ✅ Notification system integration
- ✅ Device auto-blocking integration
- ✅ Audit logging for compliance
- ✅ Documentation complete

---

## Future Enhancements

### Phase 6 Potential

- SMS notifications support (complementing FCM)
- Email notification fallback
- Device unblocking after payment
- Late fee waiver rules
- Selective blocking (specific regions/branches)
- Advanced cobrador assignment
- Payment plan suggestions

---

## Related Documentation

- [Background Jobs Guide](background-jobs.md)
- [Notification System](../architecture/notifications.md)
- [Device Blocking (MDM)](cobrador-workflow.md#block-device-via-mdm)
- [Solid Queue Setup](../architecture/tech-stack.md#solid-queue)

---

**Last Updated**: January 1, 2026
**Phase**: Phase 5 - Background Jobs & Notifications
**Status**: Complete ✅
