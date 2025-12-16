# CLAUDE.md - AI Assistant Context

This file provides context for AI assistants (like Claude Code) working on this project.

## Project Identity

**Name**: MOVICUOTAS Backend
**Full Brand**: MOVICUOTAS - Tu Crédito, Tu Móvil
**Type**: Rails 8 Admin Platform + REST API
**Purpose**: Credit management system for mobile phone sales
**Brand Color**: #125282 (RGB: 18, 82, 130)

## Visual Style Guide and Color Palette

### Corporate Color
**Primary Brand Color**: `#125282` (Azul Corporativo MOVICUOTAS)
- **RGB**: 18, 82, 130
- **HSL**: 207°, 76%, 29%
- **CMYK**: 86, 37, 0, 49

**Color Psychology**: The dark blue conveys:
- Trust and security - Essential for financial transactions
- Professionalism - Associated with serious financial institutions
- Stability - Communicates that the platform is solid and reliable
- Authority - Inspires respect and credibility

**Applications**:
- Main headers and navigation
- Logos and branding
- Primary action buttons
- Important titles
- Main borders and dividers

### Functional Colors

#### Status Colors

**Success / Approved - Green**: `#10b981` (RGB: 16, 185, 129)
- Credit approved
- Payment verified successfully
- Process completed
- Action confirmations
- "Active" or "Current" status badges

**Error / Rejected - Red**: `#ef4444` (RGB: 239, 68, 68)
- Credit rejected
- Customer blocked (active credit exists)
- Overdue payments / late fees
- Validation errors
- Critical error messages
- Device lock warnings

**Warning / Pending - Orange**: `#f59e0b` (RGB: 245, 158, 11)
- Payment due soon (3-5 days)
- Pending review application
- Pending verification
- Documents to complete
- Intermediate states

**Information / Neutral - Blue**: `#3b82f6` (RGB: 59, 130, 246)
- Informational messages
- Tooltips and help
- General notifications
- Secondary links
- Informational badges

#### Interface Colors

**Purple - Products and Catalog**: `#6366f1` (RGB: 99, 102, 241)
- Phone catalog
- Products section
- Device configuration
- QR codes / BluePrints


### Neutral Colors

| Color | HEX | Use |
|-------|-----|-----|
| Dark Gray | `#1f2937` | Main text, secondary headers |
| Medium Gray | `#6b7280` | Secondary text, descriptions |
| Light Gray | `#d1d5db` | Borders, separators |
| Very Light Gray | `#f3f4f6` | Secondary backgrounds, cards |
| White | `#ffffff` | Main background, featured cards |

### Typography

**Heading 1 - Main Titles**
- Font: Inter / Calibri - Bold
- Size: 28pt
- Color: `#125282`

**Heading 2 - Sections**
- Font: Inter / Calibri - Semibold
- Size: 20pt
- Color: `#1f2937`

**Body Text**
- Font: Inter / Calibri - Regular
- Size: 12pt
- Color: `#1f2937`

### Accessibility Requirements (WCAG 2.1 Level AA)

**Minimum Contrast Ratios**:
- Normal text: 4.5:1
- Large text (18pt+): 3:1
- Interactive elements: 3:1

**Approved Colors on White Background**:
- ✅ `#125282` (Corporate Blue) - Contrast 8.2:1
- ✅ `#1f2937` (Dark Gray) - Contrast 14.1:1
- ✅ `#ef4444` (Red) - Contrast 4.5:1
- ✅ `#10b981` (Green) - Contrast 3.9:1 (large text only)

### Design Best Practices

**✅ DO**:
- Use `#125282` for brand and navigation
- Green only for confirmed success
- Red only for errors/rejections
- Maintain accessible contrast (WCAG AA)
- Use grays for text hierarchy

**❌ DON'T**:
- Mix green with red in same context
- Use red for decoration
- Change the corporate blue `#125282`
- Use colors with low contrast
- Invent new status colors

### Design Philosophy

The MOVICUOTAS color palette is specifically designed for a financial credit system. Each color serves a precise psychological function:
- Generate trust in money transactions
- Clearly communicate the status of each operation
- Reduce anxiety in approval/rejection processes
- Intuitively guide the user through each step

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
1. **Customer**: End customer buying on credit (with date of birth for age calculation)
2. **Device**: Mobile phone with IMEI and MDM tracking
3. **Loan**: Credit agreement with contract number (format: `S01-2025-12-04-000001`)
   - **CRITICAL**: Track loan status across ALL stores/branches
   - Only ONE active loan per customer system-wide
4. **Installment**: Individual payment due dates (bi-weekly)
   - Must track status: pending, paid, overdue, cancelled
   - Each installment linked to specific loan
5. **Payment**: Actual payments made (with receipt images in S3)
   - Must track which installment(s) each payment applies to
   - Track payment history for reporting
6. **Notification**: FCM push notifications to customers
7. **CreditApplication**: Credit application requests from vendors
8. **PhoneModel**: Catalog of available phone models
9. **Contract**: Digital contracts with customer signatures
10. **MdmBlueprint**: QR codes for device MDM configuration

## Key Business Rules

### Vendor Workflow (10-Step Process)

**Step 1: Customer Verification**
- Check if customer has active loan by identification number **ACROSS ALL STORES/BRANCHES**
- Block if active loan exists in ANY store
- Display message: "Cliente tiene crédito activo. Finaliza el pago de tus Movicuotas para aplicar a más créditos!"
- Allow progression only if no active loans exist in the entire system
- **CRITICAL**: This is a system-wide check, not per-store

**Step 2: Credit Application**
- Collect customer data (personal, employment, income)
- **REQUIRED**: Capture date of birth (fecha de nacimiento) to calculate age
- Upload ID photos (front/back) and facial verification to S3
- Submit for approval (manual or automated)
- Generate application number if approved (format: `APP-000001`)
- Age validation: Customer must meet minimum age requirement

**Step 3: Device Selection**
- Retrieve approved application by number
- Display phone models where price <= approved amount
- Validate IMEI uniqueness
- Display customer data (read-only): Nombre, Identidad, Teléfono, Correo, Foto
- **NOTE**: Do NOT display approved amount on frontend after this step

**Step 4: Purchase Confirmation**
- Display summary: selected phone model + total price

**Step 5: Payment Calculator**
- Display phone model and total price
- Down payment options: 30%, 40%, 50%
- Installment terms: 6, 8, or 12 bi-weekly periods
- Calculate and display bi-weekly payment amount dynamically
- **Payment Tracking**: System must track each installment and payment status

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
- **Pre-requisite**: Verify NO active loans exist for customer across ALL stores
- Auto-generate contract number: `{branch}-{date}-{sequence}`
- Calculate bi-weekly installment schedule with interest
- Generate all installments upfront (bi-weekly due dates)
- Assign device to customer atomically
- Create contract with digital signature
- Set loan status to 'active'
- **IMPORTANT**: Only ONE active loan per customer in entire system

### Payment Processing
- Upload receipts to S3
- Support partial payments
- **Track each payment**: Link to specific installment(s)
- **Track payment history**: Maintain complete audit trail
- Calculate late fees for overdue (bi-weekly periods)
- Apply overpayments to next installment
- Update installment status when paid
- Send FCM confirmation notification
- Bi-weekly payment schedule (every 15 days)
- **Critical**: Update loan status when fully paid (all installments completed)

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

  def status_color
    case @customer.status
    when 'active' then '#10b981'      # Green - Success
    when 'suspended' then '#f59e0b'   # Orange - Warning
    when 'blocked' then '#ef4444'     # Red - Error
    end
  end

  def status_badge_class
    case @customer.status
    when 'active' then 'bg-green-100 text-green-800'
    when 'suspended' then 'bg-orange-100 text-orange-800'
    when 'blocked' then 'bg-red-100 text-red-800'
    end
  end
end
```

**Important**: Always use the defined color palette:
- Primary brand: `#125282`
- Success/approved: `#10b981`
- Error/rejected: `#ef4444`
- Warning/pending: `#f59e0b`
- Info: `#3b82f6`
- Products: `#6366f1`
- Accessories: `#ec4899`

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
1. **Active Loan Check (CRITICAL)**:
   - Query: `Customer.joins(:loans).where(loans: { status: 'active' })`
   - **Must check across ALL stores/branches in entire system**
   - Block new credit if ANY active loan exists
2. **IMEI Uniqueness**: Validate IMEI not in `devices` table
3. **Price Validation**: `phone_price <= approved_amount` (no accessories)
4. **Bi-weekly Calculation**: Use proper interest rate division (annual_rate / 26 for bi-weekly)
5. **Age Validation**: Calculate from date_of_birth, must meet minimum age requirement
6. **Payment Tracking**: Each payment must link to installment(s) and update loan balance

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
- **Always use the defined color palette** - Never hardcode arbitrary colors
- Use Tailwind CSS color utilities that match the brand palette
- Example: `bg-[#125282]` for corporate blue, `text-green-600` for success states

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
1. **Step 1 blocks progression** if customer has active loan **IN ANY STORE** - Display RED (`#ef4444`) alert message
2. **CRITICAL**: Check active loans across ALL stores/branches system-wide
3. **All calculations are bi-weekly** (not monthly)
4. **Down payment options**: Only 30%, 40%, or 50%
5. **Installment options**: Only 6, 8, or 12 bi-weekly periods
6. **File uploads**: ID photos (front/back), facial verification, contract signature → S3
7. **Application numbers**: Format `APP-000001` (sequential)
8. **Contract numbers**: Format `{branch}-{date}-{sequence}` (e.g., `S01-2025-12-04-000001`)
9. **IMEI validation**: Must be unique across entire system
10. **Price validation**: Phone price must be <= approved amount (NO accessories)
11. **Digital signatures**: Capture via touch interface, save as image
12. **Date of birth**: Required field to calculate customer age
13. **Payment tracking**: Track every payment and link to specific installments
14. **Hide approved amount**: Do NOT display on frontend after Step 3 (only backend validation)

### UI Color Guidelines for Vendor Workflow

**Step 1 - Customer Verification**:
- Active loan exists → RED (`#ef4444`) alert
- No active loan → GREEN (`#10b981`) confirmation

**Step 2.4 - Application Result**:
- Approved → GREEN (`#10b981`) with "Aprobado" message
- Not Approved → RED (`#ef4444`) with "No Aprobado" message

**Step 3 - Phone Models**:
- Use PURPLE (`#6366f1`) for product cards and catalog items

**Step 5 - Payment Calculator**:
- Primary buttons → CORPORATE BLUE (`#125282`)
- Display calculated amounts in DARK GRAY (`#1f2937`)

**Step 6 - Contract Signature**:
- Success message → GREEN (`#10b981`)
- Signature area border → CORPORATE BLUE (`#125282`)

**Step 7 - Final Confirmation**:
- Success message → GREEN (`#10b981`) large text
- Primary action buttons → CORPORATE BLUE (`#125282`)

---

**Last Updated**: 2025-12-14
**Project Status**: Phase 1 - Setup with Vendor Workflow Specification + Visual Style Guide
