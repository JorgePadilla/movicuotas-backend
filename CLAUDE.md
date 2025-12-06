# CLAUDE.md - AI Assistant Context

This file provides context for AI assistants (like Claude Code) working on this project.

## Project Identity

**Name**: MOVICUOTAS Backend
**Type**: Rails 8 Admin Platform + REST API
**Purpose**: Credit management system for mobile phone sales
**Brand Color**: #125282 (RGB: 18, 82, 130)

## Tech Stack

- **Framework**: Ruby on Rails 8
- **Database**: PostgreSQL
- **UI Components**: ViewComponent 4
- **Background Jobs**: Solid Queue
- **Storage**: ActiveStorage with AWS S3
- **Authentication**: Devise
- **Authorization**: Pundit
- **API**: RESTful JSON endpoints (`/api/v1`)
- **Client**: Flutter mobile app (separate repo)

## Project Structure

```
movicuotas-backend/
├── app/
│   ├── components/         # ViewComponent 4 components
│   │   ├── shared/        # Reusable UI components
│   │   ├── admin/         # Admin-specific components
│   │   └── reports/       # Report components
│   ├── controllers/
│   │   ├── admin/         # Admin web interface
│   │   └── api/v1/        # Mobile app API
│   ├── models/
│   │   ├── customer.rb
│   │   ├── device.rb
│   │   ├── loan.rb
│   │   ├── installment.rb
│   │   ├── payment.rb
│   │   └── notification.rb
│   ├── policies/          # Pundit authorization
│   ├── services/          # Business logic
│   │   ├── loan_calculator_service.rb
│   │   ├── payment_processor_service.rb
│   │   ├── notification_service.rb
│   │   └── mdm_service.rb
│   └── jobs/              # Solid Queue background jobs
├── db/
│   ├── migrate/
│   └── seeds.rb
└── test/                  # Minitest tests
```

## Core Domain Models

### User Types
1. **Administrators**: Full system access
2. **Vendedores**: Limited to customer/loan management

### Main Entities
1. **Customer**: End customer buying on credit
2. **Device**: Mobile phone with IMEI and MDM tracking
3. **Loan**: Credit agreement with contract number (format: `S01-2025-12-04-000001`)
4. **Installment**: Individual payment due dates
5. **Payment**: Actual payments made (with receipt images in S3)
6. **Notification**: FCM push notifications to customers

## Key Business Rules

### Loan Creation
- Auto-generate contract number: `{branch}-{date}-{sequence}`
- Calculate installment schedule with interest
- Generate all installments upfront
- Assign device to customer atomically

### Payment Processing
- Upload receipts to S3
- Support partial payments
- Calculate late fees for overdue
- Apply overpayments to next installment
- Send FCM confirmation notification

### Device Locking (Phase 1)
**Manual Process**:
1. Admin marks device as "pending lock"
2. Admin manually logs into MDM panel
3. Admin executes lock in MDM
4. Admin confirms lock in Rails app
5. System updates status to "locked"

**Note**: Automatic MDM API integration is Phase 2+

### Late Payment Detection
- Daily job marks overdue installments
- Sends FCM warning notifications
- Calculates late fees

## Critical Patterns to Follow

### 1. Service Objects for Business Logic
```ruby
# Good: Extract complex logic to services
class LoanCalculatorService
  def initialize(loan)
    @loan = loan
  end

  def generate_installments
    # Complex calculation here
  end
end

# Usage in controller
service = LoanCalculatorService.new(loan)
installments = service.generate_installments
```

### 2. Background Jobs for Async Work
```ruby
# Use Solid Queue for notifications
class SendPaymentReminderJob < ApplicationJob
  queue_as :notifications

  def perform(customer_id, installment_id)
    # Send FCM notification
  end
end
```

### 3. ViewComponents for UI
```ruby
# app/components/admin/customers/customer_card_component.rb
class Admin::Customers::CustomerCardComponent < ViewComponent::Base
  def initialize(customer:)
    @customer = customer
  end
end
```

### 4. Pundit for Authorization
```ruby
# Always authorize in controllers
def update
  @customer = Customer.find(params[:id])
  authorize @customer
  # ...
end
```

### 5. Audit Logging
```ruby
# Log important actions
AuditLog.create!(
  user: current_user,
  action: 'locked',
  resource: device,
  changes: device.previous_changes
)
```

## Common Tasks & Commands

### Setup
```bash
bin/setup                    # Initial setup
bin/rails db:create db:migrate db:seed
```

### Development
```bash
bin/dev                      # Start server + jobs
bin/rails c                  # Console
bin/rails routes | grep api  # View API routes
```

### Testing
```bash
bin/rails test               # Run all tests
bin/rails test test/models
bin/rails test test/services
```

### Database
```bash
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:reset           # Drop, create, migrate, seed
```

## API Endpoints for Mobile App

### Authentication
```
POST /api/v1/auth/login
  Body: { identification_number, contract_number }
  Returns: { token, customer, loan }

GET /api/v1/auth/forgot_contract?phone=xxx
  Returns: Contract number via SMS
```

### Customer Features
```
GET /api/v1/dashboard
  Returns: Active loan, next payment, device status

GET /api/v1/installments
  Returns: Payment schedule

POST /api/v1/payments
  Body: { installment_id, amount, payment_date, receipt_image }
  Returns: Payment confirmation

GET /api/v1/notifications
  Returns: Customer notifications
```

## Coding Conventions

### Models
- Use enums for status fields
- Add database indexes for foreign keys and frequently queried fields
- Validate presence and uniqueness where appropriate
- Use scopes for common queries

### Controllers
- Keep actions thin, delegate to services
- Always authorize with Pundit
- Use strong parameters
- Return proper HTTP status codes

### Services
- One public method per service
- Use `ActiveRecord::Base.transaction` for multi-step operations
- Raise custom errors for business logic failures
- Return meaningful objects, not booleans

### Components
- Keep components focused and reusable
- Pass data via initializer, not instance variables
- Use slots for flexible content areas

### Jobs
- Set appropriate queue priorities
- Use `retry_on` for transient failures
- Keep jobs idempotent

## Environment-Specific Behavior

### Development
- Use local storage for ActiveStorage
- FCM notifications logged, not sent
- Seed data includes test customers/loans

### Production
- S3 for file storage
- Real FCM notifications
- Audit logging enabled
- Rate limiting enforced

## Security Checklist

When implementing features, ensure:
- [ ] Pundit policy defined and checked
- [ ] Input validated and sanitized
- [ ] SQL injection prevented (use ActiveRecord)
- [ ] File uploads validated (type, size)
- [ ] Sensitive actions audit logged
- [ ] API endpoints require authentication
- [ ] CORS configured properly

## Testing Guidelines

### What to Test
- Model validations and associations
- Service object calculations (especially loan math)
- Authorization policies
- API authentication and responses
- Background job execution

### What NOT to Test
- Framework functionality
- Third-party gems
- Simple CRUD operations

## Common Pitfalls to Avoid

1. **Don't bypass authorization**: Always use `authorize` in controllers
2. **Don't put business logic in controllers**: Use services
3. **Don't forget transactions**: Loan creation, payment processing need atomicity
4. **Don't hardcode**: Use enums, constants, environment variables
5. **Don't skip audit logs**: Track locks, payments, status changes

## Current Phase: Phase 1 (Setup)

### Completed
- Project planning and documentation

### In Progress
- Database schema design
- Model generation
- Basic CRUD setup

### Next Steps
1. Generate models with migrations
2. Add validations and associations
3. Create seed data
4. Build admin interface with ViewComponents
5. Implement core services (loan calculator, payment processor)
6. Setup Solid Queue jobs
7. Configure S3 for file storage
8. Build API endpoints
9. Setup Devise and Pundit
10. Write tests

## Questions to Ask When Stuck

1. **For features**: Does this belong in a controller, model, or service?
2. **For authorization**: What user roles can do this action?
3. **For background jobs**: Does this need to be async?
4. **For API**: What does the mobile app need in the response?
5. **For UI**: Can I reuse an existing ViewComponent?

## Useful References

- **README.md**: Complete project documentation
- **Database Schema**: See README "Database Schema" section
- **API Spec**: See README "API Endpoints" section
- **Business Logic**: See README "Business Logic" section

## Development Philosophy

- **Keep it simple**: Don't over-engineer
- **Security first**: Authorize everything
- **Test the important stuff**: Business logic, calculations, authorization
- **Use Rails conventions**: Don't fight the framework
- **Document as you go**: Update this file when patterns change

---

**Last Updated**: 2025-12-05
**Project Status**: Phase 1 - Setup
