# Background Jobs

This project uses **Solid Queue** (Rails 8 default) for background job processing.

## Production Setup

### Running Solid Queue in Puma (Single Server)

For our $10 Lightsail instance (1 vCPU, 1GB RAM), Solid Queue runs **inside the Puma process** to minimize memory overhead.

**Configuration:** Set environment variable in `/etc/systemd/system/puma_movicuotas.env`:

```
SOLID_QUEUE_IN_PUMA=true
```

This is enabled via `config/puma.rb`:

```ruby
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
```

**To restart after config changes:**

```bash
sudo systemctl restart puma_movicuotas
```

### Production Queue Configuration

File: `config/solid_queue.yml`

```yaml
production:
  # Optimized for $10 Lightsail (1 vCPU, 1GB RAM)
  # - Single process: less memory overhead
  # - 3 workers: enough for low traffic
  # - 1s polling: ~1 DB query/sec instead of ~30
  processes:
    - host: localhost
      queues: [ default, mailers, notifications, reminders, blocking ]
      concurrency: 3
      polling_interval: 1
```

---

## Job Inventory

| Job | Queue | Schedule | Purpose |
|-----|-------|----------|---------|
| MarkInstallmentsOverdueJob | reminders | 12:01 AM daily | Mark past-due installments as overdue |
| DailyCollectionReminderJob | reminders | 9:00 AM daily | Send payment reminders to customers |
| CheckPaymentConfirmationsJob | notifications | Every 30 min | Notify customers of payment status |
| CleanupOldNotificationsJob | default | 2:00 AM daily | Delete old notification records |
| SendPushNotificationJob | notifications | Event-driven | Send FCM push notifications |
| SendOverdueNotificationJob | notifications | Manual trigger | Escalating overdue notifications |
| SendLatePaymentWarningJob | notifications | Manual trigger | Warnings before device blocking |
| NotifySupervisorsJob | notifications | Manual trigger | Daily reports to supervisors |
| AutoBlockDeviceJob | blocking | Manual trigger | Block devices (not automated) |

### Recurring Jobs

Configured in `config/recurring.yml`. Active scheduled jobs:

- **12:01 AM** - `MarkInstallmentsOverdueJob`: Updates installment statuses
- **2:00 AM** - `CleanupOldNotificationsJob`: Cleans up old records
- **9:00 AM** - `DailyCollectionReminderJob`: Sends customer reminders
- **Every 30 min** - `CheckPaymentConfirmationsJob`: Payment status notifications
- **Hourly :12** - Built-in cleanup of finished Solid Queue jobs

### Manual Trigger Jobs

Available at `/admin/jobs` for admin users:

- MarkInstallmentsOverdueJob
- SendOverdueNotificationJob
- SendLatePaymentWarningJob
- NotifySupervisorsJob
- AutoBlockDeviceJob

**Note:** Device blocking (`AutoBlockDeviceJob`) is intentionally manual. Employees view overdue devices in the supervisor dashboard and block them manually via the MDM system.

---

## Notification Delivery

### Primary Method: FCM Push Notifications

All customer notifications use Firebase Cloud Messaging (FCM) via the Flutter mobile app.

**Flow:**
1. Job creates `Notification` record
2. `after_create_commit` triggers `SendPushNotificationJob`
3. `FcmService` sends push to customer's registered device tokens

### SMS

SMS is **only** used for OTP verification during credit applications, not for payment reminders or notifications.

### Email

Not used in this project.

---

## Monitoring

### Mission Control Jobs

Web UI available at `/admin/jobs` for monitoring:

- View queued, running, and failed jobs
- Retry failed jobs
- See job execution times

### Useful Commands

```bash
# Check Solid Queue status (if running as separate service)
sudo systemctl status solid_queue

# View Puma logs (includes Solid Queue when SOLID_QUEUE_IN_PUMA=true)
sudo journalctl -u puma_movicuotas -f

# Rails console - check pending jobs
SolidQueue::Job.where(finished_at: nil).count

# Rails console - check failed jobs
SolidQueue::FailedExecution.count
```

---

## Development

In development, Solid Queue runs with:

- 5 workers
- 1 second polling
- All queues in single process

To start in development:

```bash
# Option 1: Foreman with Procfile
bin/dev

# Option 2: Manually
bundle exec rake solid_queue:start
```
