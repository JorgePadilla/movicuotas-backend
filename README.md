# MOVICUOTAS Backend - Rails 8 Admin Platform

**Repository:** `movicuotas-backend`
**Description:** Sistema administrativo para gestión de créditos de dispositivos móviles. Plataforma backend construida en Rails 8 para MOVICUOTAS - Tu Crédito, Tu Móvil.

## Project Overview

This is the backend administrative platform for MOVICUOTAS, a mobile phone credit sales system. It manages customers, devices, loans (with contract numbers), payments, and integrates with MDM for remote device control.

**Tech Stack**: Rails 8, PostgreSQL, ViewComponent 4, Solid Queue, ActiveStorage (S3)
**Brand Color**: #125282 (RGB: 18, 82, 130)

## Architecture Overview

### Core Components
- **Admin Web Interface**: Rails views with ViewComponent 4 for UI
- **REST API** (`/api/v1`): JSON endpoints for Flutter mobile app
- **Background Jobs**: Solid Queue for notifications and async tasks
- **Storage**: ActiveStorage with S3 for receipts and documents
- **Authentication**: Devise for admin users
- **Authorization**: Pundit for role-based access control

### Two User Types
1. **Administrators**: Full access to all features
2. **Vendedores (Sales Staff)**: Limited to customer/loan management

## Database Schema

### Core Models

```ruby
# users - Admin and sales staff
- email (string, unique, indexed)
- encrypted_password (string)
- role (enum: admin, vendedor)
- full_name (string)
- timestamps

# customers - End customers buying devices on credit
- customer_number (string, unique, indexed) # Auto-generated: CUST-000001
- full_name (string, required)
- email (string, indexed)
- phone (string, required, indexed)
- address (text)
- identification_type (enum: cedula, passport, ruc)
- identification_number (string, unique, indexed)
- fcm_token (string) # For push notifications
- status (enum: active, suspended, blocked)
- notes (text)
- timestamps

# devices - Cell phones being sold
- imei (string, unique, required, indexed)
- brand (string, required)
- model (string, required)
- purchase_price (decimal, precision: 10, scale: 2)
- customer_id (references customers)
- mdm_device_id (string) # ID in MDM system
- lock_status (enum: unlocked, locked, pending)
- locked_at (datetime)
- locked_by_id (references users)
- notes (text)
- timestamps

# loans - Credit agreements
- customer_id (references customers, required)
- device_id (references devices, required)
- contract_number (string, unique, required, indexed) # Format: S01-2025-12-04-000001
- branch_number (string, required) # e.g., "S01", "S02"
- total_amount (decimal, precision: 10, scale: 2)
- down_payment (decimal, precision: 10, scale: 2)
- financed_amount (decimal, precision: 10, scale: 2)
- interest_rate (decimal, precision: 5, scale: 2) # Annual %
- number_of_installments (integer)
- installment_amount (decimal, precision: 10, scale: 2)
- start_date (date)
- end_date (date)
- status (enum: active, paid_off, defaulted, cancelled)
- created_by_id (references users)
- timestamps

# installments - Individual payment due dates
- loan_id (references loans, required)
- installment_number (integer, required)
- due_date (date, required, indexed)
- amount (decimal, precision: 10, scale: 2)
- principal (decimal, precision: 10, scale: 2)
- interest (decimal, precision: 10, scale: 2)
- late_fee (decimal, precision: 10, scale: 2, default: 0)
- status (enum: pending, paid, overdue, cancelled)
- paid_date (date)
- paid_amount (decimal, precision: 10, scale: 2)
- timestamps

# payments - Actual payments made
- installment_id (references installments, required)
- customer_id (references customers, required)
- amount (decimal, precision: 10, scale: 2, required)
- payment_date (date, required, indexed)
- payment_method (enum: cash, transfer, deposit, other)
- reference_number (string)
- receipt_image (active_storage attachment)
- verification_status (enum: pending, verified, rejected)
- verified_by_id (references users)
- verified_at (datetime)
- notes (text)
- timestamps

# notifications - Push notifications sent to customers
- customer_id (references customers, required)
- notification_type (enum: payment_reminder, payment_confirmed, overdue_warning, device_lock_warning)
- title (string, required)
- body (text, required)
- sent_at (datetime, indexed)
- read_at (datetime)
- fcm_response (jsonb)
- timestamps

# audit_logs - Track all important actions
- user_id (references users)
- action (string, required) # created, updated, deleted, locked, unlocked
- resource_type (string, required)
- resource_id (integer, required)
- changes (jsonb) # Store what changed
- ip_address (inet)
- timestamps
```

### Indexes
```ruby
add_index :customers, :customer_number, unique: true
add_index :customers, :email
add_index :customers, :phone
add_index :customers, :identification_number, unique: true
add_index :devices, :imei, unique: true
add_index :devices, :customer_id
add_index :loans, :contract_number, unique: true
add_index :installments, :due_date
add_index :installments, [:loan_id, :installment_number]
add_index :payments, :payment_date
add_index :notifications, :sent_at
add_index :audit_logs, [:resource_type, :resource_id]
```

## Business Logic

### Loan Creation Process
1. Validate customer exists and is active
2. Validate device exists and is not assigned
3. Calculate financed amount: `total_amount - down_payment`
4. Generate installment schedule using `LoanCalculatorService`
5. Create loan and all installments in a transaction
6. Assign device to customer
7. Send welcome notification

### Payment Processing
1. Receive payment with optional receipt image
2. Upload receipt to S3 via ActiveStorage
3. Mark installment as paid or partially paid
4. If overpayment, apply to next installment
5. Calculate late fees if overdue
6. Send payment confirmation notification
7. Check if loan is fully paid
8. Audit log the payment

### Late Payment Detection (Daily Job)
```ruby
# Run daily via Solid Queue
class MarkOverdueInstallmentsJob
  def perform
    Installment.pending.where('due_date < ?', Date.today).find_each do |installment|
      installment.mark_as_overdue!
      SendNotificationJob.perform_later(installment.customer_id, :overdue_warning)
    end
  end
end
```

### Device Lock/Unlock Flow
1. Admin selects device from dashboard
2. Admin clicks "Request Lock" button
3. System updates device status to 'pending'
4. **Manual Step**: Admin logs into MDM panel separately
5. Admin executes lock in MDM system
6. Admin returns to Rails app and confirms lock
7. System updates status to 'locked' and records timestamp
8. Audit log created
9. Customer receives notification (if app is still accessible)

**Note**: Automatic MDM API integration is Phase 2+ (separate project)

## API Endpoints (for Mobile App)

### Authentication
```
POST /api/v1/auth/login
  - Option 1: identification_number + contract_number
  - Option 2: customer_number + contract_number
  - Returns: JWT token, customer info, loan details

GET /api/v1/auth/forgot_contract
  - Params: phone or email
  - Returns: contract number(s) via SMS/email
  - Security: Rate limited, requires verification
```

### Customer Dashboard
```
GET /api/v1/dashboard
  - Returns: active loan, next payment, total debt, lock status
```

### Payments
```
GET /api/v1/payments
  - Returns: payment history

POST /api/v1/payments
  - Params: installment_id, amount, payment_date, receipt_image
  - Creates payment record and uploads receipt to S3
```

### Installments
```
GET /api/v1/installments
  - Returns: all installments for customer's active loan
```

### Notifications
```
GET /api/v1/notifications
  - Returns: customer's notifications

PUT /api/v1/notifications/:id/mark_read
  - Marks notification as read
```

## Services Layer

### LoanCalculatorService
```ruby
# Calculate installment schedule with interest
class LoanCalculatorService
  def initialize(loan)
    @loan = loan
  end

  def generate_installments
    # Calculate monthly payment using amortization formula
    # Create installments array with due dates
    # Return array of installment attributes
  end

  private

  def monthly_interest_rate
    @loan.interest_rate / 12 / 100
  end

  def monthly_payment
    # PMT formula: P * (r(1+r)^n) / ((1+r)^n - 1)
  end
end
```

### PaymentProcessorService
```ruby
class PaymentProcessorService
  def initialize(payment)
    @payment = payment
  end

  def process!
    ActiveRecord::Base.transaction do
      apply_payment_to_installment
      handle_overpayment if overpayment?
      calculate_late_fees
      update_loan_status
      send_confirmation_notification
      create_audit_log
    end
  end
end
```

### NotificationService
```ruby
class NotificationService
  def self.send_payment_reminder(customer, installment)
    # Build FCM payload
    # Send via FCM gem
    # Log notification in database
  end

  def self.send_overdue_warning(customer)
    # Send warning about overdue payment
  end

  def self.send_lock_warning(customer, days_until_lock)
    # Warn customer device will be locked
  end
end
```

### MdmService (Placeholder)
```ruby
class MdmService
  # Future: API integration with MDM provider
  # For now: Manual process with status tracking

  def self.request_lock(device)
    device.update(lock_status: 'pending')
    # Admin manually locks via MDM panel
  end

  def self.confirm_lock(device, user)
    device.update(
      lock_status: 'locked',
      locked_at: Time.current,
      locked_by: user
    )
  end
end
```

## Background Jobs (Solid Queue)

### Queues Configuration
```yaml
# config/solid_queue.yml
production:
  queues:
    - notifications: 10
    - payments: 5
    - mdm_actions: 3
    - default: 2
```

### Jobs
```ruby
# Send payment reminders 3 days before due date
class SendPaymentReminderJob < ApplicationJob
  queue_as :notifications

  def perform
    upcoming = Installment.pending.where(
      due_date: 3.days.from_now.to_date
    )
    upcoming.each do |installment|
      NotificationService.send_payment_reminder(
        installment.customer,
        installment
      )
    end
  end
end

# Check for overdue installments daily
class MarkOverdueInstallmentsJob < ApplicationJob
  queue_as :default

  def perform
    Installment.pending.where('due_date < ?', Date.today).find_each do |inst|
      inst.update(status: 'overdue')
      NotificationService.send_overdue_warning(inst.customer)
    end
  end
end

# Send FCM notification
class SendFcmNotificationJob < ApplicationJob
  queue_as :notifications
  retry_on StandardError, attempts: 3

  def perform(customer_id, title, body)
    customer = Customer.find(customer_id)
    return unless customer.fcm_token.present?

    # Send via FCM gem
    # Log notification
  end
end
```

## ViewComponent 4 Structure

### Component Organization
```
app/components/
├── shared/
│   ├── button_component.rb
│   ├── card_component.rb
│   ├── badge_component.rb
│   └── table_component.rb
├── admin/
│   ├── dashboard/
│   │   ├── stat_card_component.rb
│   │   └── recent_payments_component.rb
│   ├── customers/
│   │   ├── customer_card_component.rb
│   │   └── customer_status_badge_component.rb
│   └── loans/
│       ├── loan_summary_component.rb
│       └── installment_table_component.rb
└── reports/
    ├── payment_chart_component.rb
    └── portfolio_summary_component.rb
```

### Example Component
```ruby
# app/components/admin/customers/customer_card_component.rb
class Admin::Customers::CustomerCardComponent < ViewComponent::Base
  def initialize(customer:)
    @customer = customer
  end

  def status_color
    case @customer.status
    when 'active' then 'green'
    when 'suspended' then 'yellow'
    when 'blocked' then 'red'
    end
  end
end
```

## Admin Dashboard Features

### Main Dashboard
- Total customers (active/suspended/blocked)
- Total devices assigned
- Active loans count and total value
- Payments collected this month
- Overdue installments count and value
- Recent payments list (last 10)
- Upcoming due dates (next 7 days)

### Customer Management
- List all customers (filterable by status)
- Create/Edit customer
- View customer detail:
  - Personal info
  - Active loan(s)
  - Payment history
  - Device assigned
  - Notification history
- Suspend/Activate customer
- Block customer (triggers device lock warning)

### Device Management
- List all devices (filterable by status)
- Create/Edit device
- Assign device to customer (via loan creation)
- View device detail:
  - Technical specs
  - Assigned customer
  - Lock status
  - Lock/Unlock buttons (manual MDM process)

### Loan Management
- Create new loan (wizard-style):
  1. Select customer
  2. Select device
  3. Enter loan terms (amount, down payment, interest, installments)
  4. Preview installment schedule
  5. Confirm and create
- View loan detail:
  - Customer and device info
  - Payment schedule
  - Payment history
  - Remaining balance
  - Status

### Payment Management
- List all payments (filterable by date, status)
- Register manual payment:
  - Select customer/installment
  - Enter amount, date, method
  - Upload receipt image
- Verify pending payments:
  - View uploaded receipt
  - Approve or reject
  - Add notes
- View payment detail

### Reports
- Portfolio health report
- Overdue installments report
- Collections report (by date range)
- Customer payment behavior
- Export to CSV/PDF

## File Storage (S3)

### ActiveStorage Attachments
```ruby
class Payment < ApplicationRecord
  has_one_attached :receipt_image

  validates :receipt_image, content_type: ['image/png', 'image/jpg', 'image/jpeg'],
                            size: { less_than: 5.megabytes }
end
```

### S3 Buckets
- `movicuotas-receipts-production` - Payment receipts
- `movicuotas-documents-production` - Customer documents (ID scans, etc.)
- `movicuotas-receipts-development` - Development/testing

### Storage Configuration
```yaml
# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: us-east-1
  bucket: movicuotas-receipts-<%= Rails.env %>
```

## Authorization (Pundit)

### Policies
```ruby
# app/policies/customer_policy.rb
class CustomerPolicy < ApplicationPolicy
  def create?
    user.admin? || user.vendedor?
  end

  def update?
    user.admin? || user.vendedor?
  end

  def destroy?
    user.admin?
  end

  def block?
    user.admin?
  end
end

# app/policies/device_policy.rb
class DevicePolicy < ApplicationPolicy
  def lock?
    user.admin?
  end

  def unlock?
    user.admin?
  end
end
```

## Testing Strategy

### Model Tests (Minitest)
- Validations
- Associations
- Scopes
- State transitions

### Service Tests
- Loan calculation accuracy
- Payment processing edge cases
- Notification delivery

### Integration Tests
- Loan creation flow
- Payment registration flow
- Device lock/unlock flow

### API Tests
- Authentication
- CRUD operations
- Authorization checks
- Error responses

## Security Considerations

- Devise authentication with strong password requirements
- Pundit authorization on all actions
- API authentication via JWT tokens
- CORS configuration for mobile app
- Audit logging for sensitive actions (locks, payments)
- S3 signed URLs with expiration for receipts
- Rate limiting on API endpoints
- Input sanitization and validation

## Environment Variables

```bash
# Required in production
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
AWS_BUCKET=movicuotas-receipts-production
FCM_SERVER_KEY=...
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...
SECRET_KEY_BASE=...
```

## Getting Started

### Prerequisites
- Ruby 3.2+
- PostgreSQL 14+
- Redis (for Solid Queue)
- Node.js 18+ (for asset compilation)

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd movicuotas-backend

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start the server
bin/dev
```

### Development
```bash
bin/dev                      # Start server + Solid Queue
bin/rails console            # Rails console
bin/rails routes             # View all routes
bin/rails test               # Run tests
```

## Deployment Checklist

- [ ] Database migrations run
- [ ] Assets precompiled
- [ ] Environment variables set
- [ ] S3 buckets created and accessible
- [ ] Solid Queue worker running
- [ ] Admin user seeded
- [ ] CORS configured for mobile app domain
- [ ] SSL certificate configured
- [ ] Backup strategy in place

## Development Workflow

1. Create feature branch from `main`
2. Write tests for new feature
3. Implement feature
4. Ensure all tests pass
5. Create PR with description
6. Code review
7. Merge to `main`
8. Deploy to staging
9. QA testing
10. Deploy to production

## Contributing

This is a private project. For development questions or issues, contact the development team.

## License

Proprietary

---

**Project Status**: Phase 1 (Setup)
**Next Milestone**: Database schema + basic CRUD (Phase 2)
