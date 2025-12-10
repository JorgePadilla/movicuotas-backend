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
│   │   ├── vendor/        # Vendor-specific components
│   │   └── reports/       # Report components
│   ├── controllers/
│   │   ├── admin/         # Admin web interface
│   │   ├── vendor/        # Vendor web interface (10-step workflow)
│   │   └── api/v1/        # Mobile app API
│   ├── models/
│   │   ├── customer.rb
│   │   ├── device.rb
│   │   ├── loan.rb
│   │   ├── installment.rb
│   │   ├── payment.rb
│   │   ├── notification.rb
│   │   ├── credit_application.rb
│   │   ├── phone_model.rb
│   │   ├── loan_accessory.rb
│   │   ├── contract.rb
│   │   └── mdm_blueprint.rb
│   ├── policies/          # Pundit authorization
│   ├── services/          # Business logic
│   │   ├── loan_calculator_service.rb
│   │   ├── payment_processor_service.rb
│   │   ├── notification_service.rb
│   │   ├── credit_approval_service.rb
│   │   ├── contract_generator_service.rb
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
4. **Installment**: Individual payment due dates (bi-weekly)
5. **Payment**: Actual payments made (with receipt images in S3)
6. **Notification**: FCM push notifications to customers
7. **CreditApplication**: Credit application requests from vendors
8. **PhoneModel**: Catalog of available phone models
9. **LoanAccessory**: Accessories purchased with remaining credit
10. **Contract**: Digital contracts with customer signatures
11. **MdmBlueprint**: QR codes for device MDM configuration

## Key Business Rules

### Vendor Workflow (10-Step Process)

**Step 1: Customer Verification**
- Check if customer has active loan by identification number
- Block if active loan exists
- Allow progression only if no active loans

**Step 2: Credit Application**
- Collect customer data (personal, employment, income)
- Upload ID photos (front/back) and facial verification to S3
- Submit for approval (manual or automated)
- Generate application number if approved (format: `APP-000001`)

**Step 3: Device Selection**
- Retrieve approved application by number
- Display phone models where price <= approved amount
- Validate IMEI uniqueness
- Allow accessory selection with remaining credit

**Step 4: Purchase Confirmation**
- Display summary: phone + accessories + total

**Step 5: Payment Calculator**
- Down payment options: 30%, 40%, 50%
- Installment terms: 6, 8, or 12 bi-weekly periods
- Calculate and display bi-weekly payment amount dynamically

**Step 6: Contract Signature**
- Generate contract PDF with all details
- Capture digital signature
- Save to S3

**Step 7: Confirmation**
- Display success message
- Offer contract download
- Proceed to device configuration

**Step 8: QR Generation**
- Display QR code (BluePrint) for MDM setup
- Vendor scans with customer's device

**Step 9-10: Device Configuration**
- Install MDM app via QR
- Install MoviCuotas app
- Vendor completes checklist
- Finalize sale

### Loan Creation
- Auto-generate contract number: `{branch}-{date}-{sequence}`
- Calculate bi-weekly installment schedule with interest
- Generate all installments upfront (bi-weekly due dates)
- Assign device to customer atomically
- Create contract with digital signature

### Payment Processing
- Upload receipts to S3
- Support partial payments
- Calculate late fees for overdue (bi-weekly periods)
- Apply overpayments to next installment
- Send FCM confirmation notification
- Bi-weekly payment schedule (every 15 days)

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

## Vendor Workflow Implementation Notes

### Controllers Structure
- `Vendor::CustomerVerificationsController` - Step 1: Check active loans
- `Vendor::CreditApplicationsController` - Steps 2-3: Application submission and retrieval
- `Vendor::DeviceSelectionsController` - Step 3: Phone model and accessory selection
- `Vendor::PaymentCalculatorsController` - Step 5: Calculate bi-weekly payments
- `Vendor::ContractsController` - Step 6: Contract generation and signature
- `Vendor::LoansController` - Step 7: Finalize loan creation
- `Vendor::MdmBlueprintsController` - Step 8: QR code display
- `Vendor::DeviceConfigurationsController` - Steps 9-10: Final checklist

### Key Services for Vendor Workflow
- `CreditApprovalService` - Evaluate application and determine approval
- `ContractGeneratorService` - Generate PDF contracts with customer data
- `BiweeklyCalculatorService` - Calculate bi-weekly installment payments
- `LoanFinalizationService` - Complete loan creation with all dependencies

### Important Validations
1. **Active Loan Check**: `Customer.joins(:loans).where(loans: { status: 'active' })`
2. **IMEI Uniqueness**: Validate IMEI not in `devices` table
3. **Price Validation**: `phone_price + accessories <= approved_amount`
4. **Bi-weekly Calculation**: Use proper interest rate division (annual_rate / 26 for bi-weekly)

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
bin/rails routes | grep vendor  # View vendor routes
```

### Testing
```bash
bin/rails test               # Run all tests
bin/rails test test/models
bin/rails test test/services
bin/rails test test/controllers/vendor
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
- Vendor workflow specification (10-step process)

### In Progress
- Database schema design
- Model generation
- Basic CRUD setup

### Next Steps
1. Generate models with migrations (including new vendor workflow models)
2. Add validations and associations
3. Create seed data (including phone models, MDM blueprints)
4. Build vendor interface with ViewComponents (10-step workflow)
5. Build admin interface with ViewComponents
6. Implement core services:
   - LoanCalculatorService (bi-weekly installments)
   - PaymentProcessorService
   - CreditApprovalService
   - ContractGeneratorService
   - BiweeklyCalculatorService
7. Setup Solid Queue jobs
8. Configure S3 for file storage (receipts, ID photos, contracts, signatures)
9. Build API endpoints
10. Setup Devise and Pundit
11. Write tests (especially vendor workflow integration tests)

## Questions to Ask When Stuck

1. **For features**: Does this belong in a controller, model, or service?
2. **For authorization**: What user roles can do this action? (Admin vs Vendedor)
3. **For background jobs**: Does this need to be async?
4. **For API**: What does the mobile app need in the response?
5. **For UI**: Can I reuse an existing ViewComponent?
6. **For vendor workflow**: Which step (1-10) does this belong to?
7. **For calculations**: Is this bi-weekly or monthly? (System uses bi-weekly installments)
8. **For file uploads**: Does this need S3 storage? (ID photos, receipts, contracts, signatures)

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

## Key Vendor Workflow Reminders

When implementing vendor features, remember:
1. **Step 1 blocks progression** if customer has active loan
2. **All calculations are bi-weekly** (not monthly)
3. **Down payment options**: Only 30%, 40%, or 50%
4. **Installment options**: Only 6, 8, or 12 bi-weekly periods
5. **File uploads**: ID photos (front/back), facial verification, contract signature → S3
6. **Application numbers**: Format `APP-000001` (sequential)
7. **Contract numbers**: Format `{branch}-{date}-{sequence}` (e.g., `S01-2025-12-04-000001`)
8. **IMEI validation**: Must be unique across entire system
9. **Price validation**: Total (phone + accessories) must be <= approved amount
10. **Digital signatures**: Capture via touch interface, save as image

---

**Last Updated**: 2025-12-10
**Project Status**: Phase 1 - Setup with Vendor Workflow Specification
