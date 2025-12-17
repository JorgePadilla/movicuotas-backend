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

### Three User Types
1. **Administrators (Admin)**: Full access to all features
2. **Vendedores (Sales Staff)**: Limited to customer/loan management and sales process
3. **Cobradores (Collection Agents)**: Read-only access focused on overdue accounts and MDM device control

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

### Vendor Workflow (18-Screen Process)

**CRITICAL NAVIGATION FLOW:**
```
Login (Step 1) → Customer Search (Step 2 - MAIN SCREEN) → [Dashboard accessible from menu]
```

#### Step 1: Login
Standard authentication for vendor users.

**UI Elements:**
- Email input field
- Password input field
- "Iniciar Sesión" button

**Next:** Step 2 (Buscar Cliente - Main Screen)

---

#### Step 2: Buscar Cliente (Main Screen)
**CRITICAL:** This is the main screen after login, NOT the dashboard.

**Primary Function:** Search for customer by identification number across ALL stores.

**UI Elements:**
- Large search bar: "Número de Identidad del Cliente"
- Prominent button: "Buscar en TODAS las tiendas"
- Navigation menu (sidebar/header):
  - 📊 Dashboard (accessible from menu)
  - 👥 Clientes
  - 💰 Préstamos
  - 💳 Pagos
  - 📋 Reportes

**Business Logic:**
```ruby
def search_customer(identification_number)
  # Check active loans across ALL branches
  active_loan = Loan.joins(:customer)
                   .where(customers: { identification_number: identification_number })
                   .where(status: 'active')
                   .first

  if active_loan
    {
      blocked: true,
      message: "Cliente tiene crédito activo en tienda #{active_loan.branch_number}",
      contract_number: active_loan.contract_number,
      alert_color: "red",
      action: "show_blocked_screen" # Step 3a
    }
  else
    {
      blocked: false,
      message: "Cliente disponible para nuevo crédito",
      alert_color: "green",
      action: "show_available_screen" # Step 3b
    }
  end
end
```

**UI Response:**
- **If blocked:** Show Step 3a
- **If available:** Show Step 3b

**Notes:**
- Search is the PRIMARY action
- Dashboard is SECONDARY, accessible via menu
- This screen is the "home" for vendors
- Always returns here after completing a sale

---

#### Step 3a: Cliente Bloqueado (If has active loan)
**Screen Type:** Error/Blocking

**UI Elements:**
- Red alert banner (`#ef4444`)
- Message: "Cliente tiene crédito activo. Finaliza el pago de tus Movicuotas para aplicar a más créditos!"
- Display: Contract number, Branch number
- Button: "← Nueva Búsqueda" (returns to Step 2)

**Business Rule:** NO progression allowed. Must search different customer.

---

#### Step 3b: Cliente Disponible (If no active loan)
**Screen Type:** Success/Confirmation

**UI Elements:**
- Green confirmation banner (`#10b981`)
- Message: "Cliente disponible para nuevo crédito"
- Verification checkmark: "✓ Sin créditos activos"
- Button: "Iniciar Solicitud →" (proceeds to Step 4)

**Business Rule:** Enable credit application flow.

---

#### Step 4: Datos Generales (Credit Application - Part 1)
- Collect customer data (personal info)
- **REQUIRED**: Capture date of birth (fecha de nacimiento) to calculate age
- Fields: Número de Identidad, Nombre Completo, Género, Fecha de Nacimiento, Dirección, Ciudad, Departamento, Teléfono
- Button: "Siguiente"

---

#### Step 5: Fotografías (Credit Application - Part 2)
- Upload ID photos (front/back) and facial verification to S3
- Verification method selector (SMS/WhatsApp)
- Email (optional)
- Button: "Siguiente"

---

#### Step 6: Datos Laborales (Credit Application - Part 3)
- Employment status selector
- Salary range selector
- Button: "Siguiente"

---

#### Step 7: Resumen Solicitud (Credit Application - Part 4)
- Read-only summary of all entered data
- Button: "Enviar Solicitud"

**Next:** Submit for approval → Step 8a or 8b

---

#### Step 8a: No Aprobado (Application Rejected)
**UI Elements:**
- Red message (`#ef4444`): "No Aprobado"
- Rejection reason display
- Button: "Nueva Búsqueda" (returns to Step 2)

---

#### Step 8b: Aprobado (Application Approved)
**UI Elements:**
- Green message (`#10b981`): "Aprobado"
- Display: Application number (format: `APP-000001`)
- **IMPORTANT:** Do NOT display approved amount
- Button: "Continuar" (proceeds to Step 9)

**Backend:** Generate application number, store approved amount (backend only)

---

#### Step 9: Recuperar Solicitud
**UI Elements:**
- Input field: "Ingrese Número de Solicitud aprobada"
- Button: "Ingresar"
- Upon entry, display (read-only): Nombre, Identidad, Teléfono, Correo, Foto
- **CRITICAL:** Do NOT display "Monto Aprobado" on frontend
- Button: "Proceder" (to Step 10)

---

#### Step 10: Catálogo Teléfonos (Device Selection)
**UI Elements:**
- Visual grid of phone models with prices
- **Logic:** Backend validates `phone_price <= approved_amount`
- Fields appear when model selected: IMEI, Color
- Button: "Siguiente" (to Step 11)

**Note:** NO accessories feature. Phone only.

---

#### Step 11: Confirmación (Purchase Summary)
**UI Elements:**
- Display: Selected phone model, Total price (phone only)
- Button: "Siguiente" (to Step 12)

---

#### Step 12: Calculadora (Payment Calculator)
**UI Elements:**
- Summary: Phone model, Total price
- Down payment selector: 30%, 40%, 50% (radio buttons)
- Installment term selector: 6, 8, 12 bi-weekly periods
- Dynamic display: "Cuota Quincenal: L. ----"
- Button: "Generar Crédito" (to Step 13)

**Calculation:** Based on phone price ONLY (no accessories)

---

#### Step 13: Contrato (Contract Display)
**UI Elements:**
- Document viewer with complete contract
- All customer and loan data pre-filled
- Button: "Aceptar" (to Step 14)

---

#### Step 14: Firma Digital (Digital Signature)
**UI Elements:**
- Touch-sensitive signature area
- Button: "Guardar" (to Step 15)
- Save signature to S3

---

#### Step 15: Crédito Aplicado (Success Confirmation)
**UI Elements:**
- Large success message (green `#10b981`): "¡Crédito Aplicado! Felicidades. Estás a unos pasos de disfrutar de nueva compra."
- Two action buttons:
  1. "Descargar Contrato"
  2. "Proceder a Configuración de Teléfono" (to Step 16)

---

#### Step 16: Código QR (QR Generation)
**UI Elements:**
- Large QR code display (BluePrint for MDM)
- Instruction: "Escanee este QR con el teléfono del cliente para iniciar la configuración."
- MDM configuration mechanism

---

#### Step 17: Checklist Final (Device Configuration)
**UI Elements:**
- Title: "Verificación de Configuración del Cliente"
- Manual checklist:
  - [ ] BluePrint escaneado y configuración realizada
  - [ ] Aplicación MDM instalada y confirmada
  - [ ] Aplicación MoviCuotas instalada y Log-in realizado
- Button: "Finalizar Proceso de Venta" (returns to Step 2)

---

#### Step 18: Tracking de Préstamo (Loan Tracking Dashboard)
**Accessible from:** Main navigation menu

**UI Elements:**
- Loan status display
- Installment schedule with status
- Payment history
- Remaining balance
- Next payment due date

---

### Dashboard (Accessible from Navigation Menu)

**Access:** From navigation menu on main screen (Step 2)

**Not the main screen** - vendors start at Customer Search (Step 2), not Dashboard.

**UI Elements:**
- Total customers (active/suspended/blocked)
- Total devices assigned
- Active loans count and total value
- Payments collected this month
- Overdue installments count and value
- Recent payments list (last 10)
- Upcoming due dates (next 7 days)
- Quick actions (can initiate "Nueva Búsqueda")

**Navigation:**
- Returns to Step 2 (Buscar Cliente) when starting new sale

---

## Cobrador (Collection Agent) Workflow

### Overview
The Cobrador role is specifically designed for collection agents who manage overdue accounts and device blocking through MDM. This role has read-only access to most data but can execute device locks.

### Access Level: READ + MDM CONTROL

**Primary Functions:**
1. View devices with overdue payments
2. Block/unblock devices via MDM system
3. View payment history (read-only)
4. Generate collection reports

**Restrictions:**
- ❌ Cannot create users
- ❌ Cannot edit users
- ❌ Cannot delete any records
- ❌ Cannot create credit applications
- ❌ Cannot register payments
- ❌ Cannot edit customer information
- ❌ Cannot access system configuration

### Cobrador Dashboard

```ruby
def cobrador_dashboard
  {
    overdue_devices: {
      total_count: Installment.overdue.count,
      total_amount: Installment.overdue.sum(:amount),
      by_days: {
        "1-7": Installment.overdue.where("due_date >= ?", 7.days.ago).count,
        "8-15": Installment.overdue.where("due_date < ? AND due_date >= ?", 7.days.ago, 15.days.ago).count,
        "16-30": Installment.overdue.where("due_date < ? AND due_date >= ?", 15.days.ago, 30.days.ago).count,
        "30+": Installment.overdue.where("due_date < ?", 30.days.ago).count
      }
    },
    blocked_devices: Device.where(lock_status: 'locked').count,
    pending_blocks: Device.where(lock_status: 'pending').count,
    recent_blocks: Device.where(lock_status: 'locked')
                        .where("locked_at >= ?", 7.days.ago)
                        .count
  }
end
```

### View Overdue Devices

**Screen:** Lista de Dispositivos en Mora

**Query:**
```ruby
def overdue_devices_list(filters = {})
  devices = Device.joins(loan: :installments)
                  .where(installments: { status: 'overdue' })
                  .select(
                    'devices.*',
                    'loans.contract_number',
                    'customers.full_name as customer_name',
                    'COUNT(installments.id) as overdue_count',
                    'SUM(installments.amount) as total_overdue',
                    'MIN(installments.due_date) as first_overdue_date',
                    'CURRENT_DATE - MIN(installments.due_date) as days_overdue'
                  )
                  .group('devices.id, loans.id, customers.id')

  # Apply filters
  devices = devices.where('days_overdue >= ?', filters[:min_days]) if filters[:min_days]
  devices = devices.where('total_overdue >= ?', filters[:min_amount]) if filters[:min_amount]
  devices = devices.where(loans: { branch_number: filters[:branch] }) if filters[:branch]

  devices.order('days_overdue DESC')
end
```

**UI Elements:**
- Table with: Customer name, Contract number, Days overdue, Amount overdue, Device status
- Filters: By days overdue, By amount, By branch
- Action buttons: View detail, Block device

### Device Detail (Overdue)

**Screen:** Detalle de Dispositivo en Mora

```ruby
def device_overdue_detail(device_id)
  device = Device.includes(loan: [:customer, :installments]).find(device_id)

  {
    device: {
      imei: device.imei,
      brand: device.brand,
      model: device.model,
      lock_status: device.lock_status,
      locked_at: device.locked_at
    },
    customer: {
      name: device.loan.customer.full_name,
      phone: device.loan.customer.phone,
      identification: device.loan.customer.identification_number
    },
    loan: {
      contract_number: device.loan.contract_number,
      status: device.loan.status
    },
    overdue: {
      installments: device.loan.installments.overdue.order(:due_date),
      total_overdue: device.loan.installments.overdue.sum(:amount),
      days_since_first: (Date.today - device.loan.installments.overdue.minimum(:due_date)).to_i
    },
    upcoming: device.loan.installments.pending.order(:due_date).limit(3)
  }
end
```

**Actions Available:**
- ✅ Block device (if not already blocked)
- ✅ View full payment history (read-only)
- ✅ Export detail to PDF
- ❌ Cannot edit loan
- ❌ Cannot register payment
- ❌ Cannot edit customer

### Block Device via MDM

**CRITICAL BUSINESS RULE:** Only Cobradores and Admins can block devices.

```ruby
# app/services/mdm_block_service.rb
class MdmBlockService
  def initialize(device, user)
    @device = device
    @user = user
    @reason = "Overdue payment"
  end

  def block!
    return { error: "Unauthorized" } unless can_block?
    return { error: "Already blocked" } if @device.locked?

    ActiveRecord::Base.transaction do
      # Update device status
      @device.update!(
        lock_status: 'pending',
        locked_by: @user,
        locked_at: Time.current
      )

      # Create audit log
      AuditLog.create!(
        user: @user,
        action: 'device_block_requested',
        resource_type: 'Device',
        resource_id: @device.id,
        changes: {
          reason: @reason,
          overdue_days: calculate_overdue_days,
          overdue_amount: calculate_overdue_amount
        }
      )

      # Queue MDM blocking job
      MdmBlockDeviceJob.perform_later(@device.id)

      # Notify customer
      NotificationService.send_device_lock_warning(
        @device.loan.customer,
        days_to_unlock: 3
      )
    end

    { success: true, message: "Dispositivo marcado para bloqueo" }
  end

  private

  def can_block?
    @user.admin? || @user.cobrador?
  end

  def calculate_overdue_days
    first_overdue = @device.loan.installments.overdue.minimum(:due_date)
    return 0 unless first_overdue
    (Date.today - first_overdue).to_i
  end

  def calculate_overdue_amount
    @device.loan.installments.overdue.sum(:amount)
  end
end
```

**UI Flow:**
1. Cobrador views overdue device detail
2. Clicks "🔴 Bloquear Dispositivo" button
3. Confirmation screen shows:
   - Device info
   - Customer info
   - Overdue days and amount
   - Warning message
4. Confirm action → Device status changes to 'pending'
5. Background job executes MDM block
6. Customer receives notification
7. Device status updates to 'locked'

### View Payment History (Read-Only)

**Screen:** Historial de Pagos (Solo Lectura)

```ruby
def payment_history_readonly(loan_id)
  loan = Loan.includes(:customer, :installments, :payments).find(loan_id)

  {
    customer: {
      name: loan.customer.full_name,
      contract_number: loan.contract_number
    },
    summary: {
      total_installments: loan.number_of_installments,
      paid_installments: loan.installments.paid.count,
      pending_installments: loan.installments.pending.count,
      overdue_installments: loan.installments.overdue.count,
      total_paid: loan.payments.sum(:amount),
      total_pending: loan.installments.pending.sum(:amount)
    },
    installments: loan.installments.order(:installment_number).map do |inst|
      {
        number: inst.installment_number,
        due_date: inst.due_date,
        amount: inst.amount,
        status: inst.status,
        paid_date: inst.paid_date,
        paid_amount: inst.paid_amount,
        days_overdue: inst.overdue? ? (Date.today - inst.due_date).to_i : 0
      }
    end,
    payments: loan.payments.order(payment_date: :desc).map do |payment|
      {
        date: payment.payment_date,
        amount: payment.amount,
        method: payment.payment_method,
        reference: payment.reference_number,
        verified: payment.verification_status == 'verified',
        receipt_url: payment.receipt_image.attached? ? url_for(payment.receipt_image) : nil
      }
    end
  }
end
```

**UI Elements:**
- Header: Customer name, Contract number
- Summary cards: Total paid, Total pending, Overdue count
- Table 1: Installments with status
- Table 2: Payment history with receipts
- **All fields are READ-ONLY**
- ❌ No edit buttons
- ❌ No delete buttons
- ✅ Export to PDF button only

### Collection Reports

**Screen:** Reportes de Mora

```ruby
def collection_reports(date_range = nil)
  date_range ||= 30.days.ago..Date.today

  {
    summary: {
      total_overdue_count: Installment.overdue.count,
      total_overdue_amount: Installment.overdue.sum(:amount),
      devices_blocked: Device.where(lock_status: 'locked').count,
      devices_at_risk: Device.joins(loan: :installments)
                             .where(installments: { status: 'overdue' })
                             .where(lock_status: 'unlocked')
                             .distinct.count
    },
    by_days: {
      "1-7 días": overdue_by_range(1, 7),
      "8-15 días": overdue_by_range(8, 15),
      "16-30 días": overdue_by_range(16, 30),
      "30+ días": overdue_by_range(31, 999)
    },
    by_branch: Loan.joins(:installments)
                   .where(installments: { status: 'overdue' })
                   .group(:branch_number)
                   .select('branch_number, COUNT(DISTINCT loans.id) as loan_count, SUM(installments.amount) as total_amount'),
    recent_blocks: Device.where(lock_status: 'locked')
                         .where("locked_at >= ?", date_range.begin)
                         .order(locked_at: :desc)
                         .limit(50),
    recovery_rate: calculate_recovery_rate(date_range)
  }
end

private

def overdue_by_range(min_days, max_days)
  Installment.overdue
             .where("CURRENT_DATE - due_date BETWEEN ? AND ?", min_days, max_days)
             .select('COUNT(*) as count, SUM(amount) as total')
             .first
end

def calculate_recovery_rate(date_range)
  overdue_at_start = Installment.where("due_date < ?", date_range.begin).where(status: 'overdue').sum(:amount)
  paid_during = Payment.where(payment_date: date_range).sum(:amount)

  return 0 if overdue_at_start.zero?
  ((paid_during / overdue_at_start) * 100).round(2)
end
```

**UI Elements:**
- Summary cards with key metrics
- Chart: Overdue by days range
- Chart: Overdue by branch
- Table: Recent blocks
- Export to PDF/Excel

---

### Loan Creation (Steps 10-15)
- **Pre-requisite**: Verify NO active loans exist for customer across ALL stores (validated in Step 2)
- Customer selects phone model only (NO accessories)
- Calculate financed amount: `phone_price - down_payment`
- Auto-generate contract number: `{branch}-{date}-{sequence}`
- Calculate bi-weekly installment schedule with interest
- Generate all installments upfront (bi-weekly due dates)
- Assign device to customer atomically
- Create contract with digital signature
- Set loan status to 'active'
- **IMPORTANT**: Only ONE active loan per customer in entire system
- Total amount = phone price ONLY

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

### 4. Pundit for Authorization

**Policy Examples for Cobrador Role:**

```ruby
# app/policies/device_policy.rb
class DevicePolicy < ApplicationPolicy
  def lock?
    user.admin? || user.cobrador? # Cobrador CAN block devices
  end

  def unlock?
    user.admin? # Only admin can unlock
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end
end

# app/policies/payment_policy.rb
class PaymentPolicy < ApplicationPolicy
  def index?
    true # Everyone can view
  end

  def show?
    true # Everyone can view details
  end

  def create?
    user.admin? || user.vendedor? # Cobrador CANNOT create
  end

  def update?
    user.admin? # Cobrador CANNOT update
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end
end

# app/policies/loan_policy.rb
class LoanPolicy < ApplicationPolicy
  def index?
    true # Everyone can view
  end

  def show?
    true # Everyone can view details
  end

  def create?
    user.admin? || user.vendedor? # Cobrador CANNOT create
  end

  def update?
    user.admin? || user.vendedor? # Cobrador CANNOT update
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end
end

# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    user.admin? # Only admin can view users
  end

  def create?
    user.admin? # Cobrador CANNOT create users
  end

  def update?
    user.admin? # Cobrador CANNOT edit users
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete users
  end
end

# app/policies/customer_policy.rb
class CustomerPolicy < ApplicationPolicy
  def index?
    true # Everyone can view
  end

  def show?
    true # Everyone can view details
  end

  def create?
    user.admin? || user.vendedor? # Cobrador CANNOT create
  end

  def update?
    user.admin? || user.vendedor? # Cobrador CANNOT update
  end

  def destroy?
    user.admin? # Cobrador CANNOT delete
  end

  def block?
    user.admin? # Only admin can block customers
  end
end

# Usage in controllers
def update
  @customer = Customer.find(params[:id])
  authorize @customer
  # ...
end
```

## Permissions Matrix

| Action | Admin | Vendedor | Cobrador |
|--------|-------|----------|----------|
| **Customer Management** |
| View customers | ✅ | ✅ | ✅ Read-only |
| Create customers | ✅ | ✅ | ❌ |
| Edit customers | ✅ | ✅ | ❌ |
| Delete customers | ✅ | ❌ | ❌ |
| Block customers | ✅ | ❌ | ❌ |
| **Credit & Loans** |
| Create credit application | ✅ | ✅ | ❌ |
| Approve credit | ✅ | Automatic | ❌ |
| View loans | ✅ | ✅ Own only | ✅ All |
| Edit loans | ✅ | ✅ Own only | ❌ |
| Delete loans | ✅ | ❌ | ❌ |
| **Payments** |
| View payments | ✅ | ✅ | ✅ Read-only |
| Register payment | ✅ | ✅ | ❌ |
| Verify payment | ✅ | ❌ | ❌ |
| Delete payment | ✅ | ❌ | ❌ |
| **Device Management** |
| View devices | ✅ | ✅ | ✅ Overdue only |
| Assign device | ✅ | ✅ | ❌ |
| Block device (MDM) | ✅ | ❌ | ✅ |
| Unblock device | ✅ | ❌ | ❌ |
| Delete device | ✅ | ❌ | ❌ |
| **Reports** |
| View all reports | ✅ | ❌ | ❌ |
| View own sales | ✅ | ✅ | ❌ |
| View collection reports | ✅ | ❌ | ✅ |
| Export reports | ✅ | ✅ Own only | ✅ Collection only |
| **User Management** |
| View users | ✅ | ❌ | ❌ |
| Create users | ✅ | ❌ | ❌ |
| Edit users | ✅ | ❌ | ❌ |
| Delete users | ✅ | ❌ | ❌ |
| **System** |
| System configuration | ✅ | ❌ | ❌ |
| View audit logs | ✅ | ❌ | ❌ |
| Dashboard access | ✅ Full | ✅ Sales | ✅ Collection |

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
- `Vendor::SessionsController` - Step 1: Login
- `Vendor::CustomerSearchController` - Step 2: Main screen - Search customer across all stores
- `Vendor::CreditApplicationsController` - Steps 4-7: Application submission
- `Vendor::DeviceSelectionsController` - Step 10: Phone model selection
- `Vendor::PaymentCalculatorsController` - Step 12: Calculate bi-weekly payments
- `Vendor::ContractsController` - Steps 13-14: Contract generation and signature
- `Vendor::LoansController` - Step 15: Finalize loan creation
- `Vendor::MdmBlueprintsController` - Step 16: QR code display
- `Vendor::DeviceConfigurationsController` - Step 17: Final checklist
- `Vendor::DashboardController` - Dashboard (accessible from menu)

### Key Services for Vendor Workflow
- `CreditApprovalService` - Evaluate application and determine approval
- `ContractGeneratorService` - Generate PDF contracts with customer data
- `BiweeklyCalculatorService` - Calculate bi-weekly installment payments
- `LoanFinalizationService` - Complete loan creation with all dependencies

### Important Validations
1. **Active Loan Check (CRITICAL - Step 2)**:
   - Query: `Customer.joins(:loans).where(loans: { status: 'active' })`
   - **Must check across ALL stores/branches in entire system**
   - Block new credit if ANY active loan exists
   - This is the MAIN SCREEN after login
2. **IMEI Uniqueness**: Validate IMEI not in `devices` table
3. **Price Validation**: `phone_price <= approved_amount` (phone only, no accessories)
4. **Bi-weekly Calculation**: Use proper interest rate division (annual_rate / 26 for bi-weekly)
5. **Age Validation**: Calculate from date_of_birth, must meet minimum age requirement
6. **Payment Tracking**: Each payment must link to installment(s) and update loan balance

## Background Jobs for Collection

### NotifyCollectionAgentJob

```ruby
class NotifyCollectionAgentJob < ApplicationJob
  queue_as :notifications

  def perform
    # Notify cobradores daily about new overdue accounts
    overdue_today = Installment.where(
      due_date: Date.yesterday,
      status: 'pending'
    ).update_all(status: 'overdue')

    if overdue_today > 0
      User.where(role: 'cobrador').find_each do |cobrador|
        CollectionMailer.daily_overdue_report(cobrador).deliver_later
      end
    end
  end
end
```

### AutoBlockDeviceJob

```ruby
class AutoBlockDeviceJob < ApplicationJob
  queue_as :mdm_actions

  def perform
    # Auto-block devices with 30+ days overdue
    critical_overdue = Device.joins(loan: :installments)
                             .where(installments: { status: 'overdue' })
                             .where('installments.due_date < ?', 30.days.ago)
                             .where(lock_status: 'unlocked')
                             .distinct

    critical_overdue.each do |device|
      MdmBlockService.new(device, User.system_user).block!
    end
  end
end
```

## User Model with Cobrador Helpers

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum role: { admin: 'admin', vendedor: 'vendedor', cobrador: 'cobrador' }

  # Role helpers
  def admin?
    role == 'admin'
  end

  def vendedor?
    role == 'vendedor'
  end

  def cobrador?
    role == 'cobrador'
  end

  # Permission helpers
  def can_create_loans?
    admin? || vendedor?
  end

  def can_block_devices?
    admin? || cobrador?
  end

  def can_manage_users?
    admin?
  end

  def can_delete_records?
    admin?
  end

  # System user for automated actions
  def self.system_user
    find_or_create_by(email: 'system@movicuotas.com') do |user|
      user.role = 'admin'
      user.full_name = 'System'
      user.password = SecureRandom.hex(32)
    end
  end
end
```

## Cobrador Routes

```ruby
# config/routes.rb

namespace :cobrador do
  get 'dashboard', to: 'dashboard#index'

  resources :overdue_devices, only: [:index, :show] do
    member do
      post :block
      get :payment_history
    end
  end

  resources :collection_reports, only: [:index] do
    collection do
      get :export
    end
  end

  resources :payments, only: [:index, :show] # Read-only
  resources :loans, only: [:index, :show] # Read-only
end
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

**NAVIGATION:**
1. **Main screen is Step 2 (Customer Search)** - NOT Dashboard
2. **Dashboard is accessible from menu** - Secondary function
3. **Flow**: Login → Search → [Process or Dashboard from menu]

**BUSINESS RULES:**
4. **Step 2 is CRITICAL** - Check active loans across ALL stores/branches system-wide
5. **Block if active loan exists** in ANY store - Display RED (`#ef4444`) alert (Step 3a)
6. **Only ONE active loan** per customer in entire system

**WORKFLOW (18 SCREENS):**
7. **All calculations are bi-weekly** (not monthly)
8. **Down payment options**: Only 30%, 40%, or 50%
9. **Installment options**: Only 6, 8, or 12 bi-weekly periods
10. **NO accessories feature** - Phone price only
11. **Price validation**: Phone price must be <= approved amount

**DATA HANDLING:**
12. **File uploads**: ID photos (front/back), facial verification, contract signature → S3
13. **Application numbers**: Format `APP-000001` (sequential)
14. **Contract numbers**: Format `{branch}-{date}-{sequence}` (e.g., `S01-2025-12-04-000001`)
15. **IMEI validation**: Must be unique across entire system
16. **Digital signatures**: Capture via touch interface, save as image
17. **Date of birth**: Required field to calculate customer age
18. **Payment tracking**: Track every payment and link to specific installments
19. **Hide approved amount**: Do NOT display on frontend after Step 8b (only backend validation)

### UI Color Guidelines for Vendor Workflow

**Step 2 - Customer Search (Main Screen)**:
- Search button → CORPORATE BLUE (`#125282`)
- Navigation menu → CORPORATE BLUE (`#125282`)

**Step 3a - Cliente Bloqueado**:
- Alert banner → RED (`#ef4444`)
- Error message text → RED (`#ef4444`)

**Step 3b - Cliente Disponible**:
- Confirmation banner → GREEN (`#10b981`)
- Success message → GREEN (`#10b981`)

**Step 8a - Application Rejected**:
- Rejection message → RED (`#ef4444`)

**Step 8b - Application Approved**:
- Approval message → GREEN (`#10b981`)

**Step 10 - Phone Catalog**:
- Product cards → PURPLE (`#6366f1`)

**Step 12 - Payment Calculator**:
- Primary buttons → CORPORATE BLUE (`#125282`)
- Calculated amounts → DARK GRAY (`#1f2937`)

**Step 14 - Contract Signature**:
- Signature area border → CORPORATE BLUE (`#125282`)

**Step 15 - Final Confirmation**:
- Success message → GREEN (`#10b981`) large text
- Primary action buttons → CORPORATE BLUE (`#125282`)

---

**Last Updated**: 2025-12-16
**Project Status**: Phase 1 - Setup with Vendor Workflow Specification + Visual Style Guide

---

## Project Status

**Phase 1:** Database schema + basic CRUD (In Progress)

**Current Milestone:** Vendor Workflow Implementation (18 Screens)

**Screen Count:** 18 screens total
```
Pantalla 1: Login
Pantalla 2: Buscar Cliente (MAIN SCREEN)
Pantalla 3a: Cliente Bloqueado
Pantalla 3b: Cliente Disponible
Pantalla 4: Datos Generales
Pantalla 5: Fotografías
Pantalla 6: Datos Laborales
Pantalla 7: Resumen Solicitud
Pantalla 8a: No Aprobado
Pantalla 8b: Aprobado (sin monto)
Pantalla 9: Recuperar Solicitud
Pantalla 10: Catálogo Teléfonos
Pantalla 11: Confirmación (solo teléfono)
Pantalla 12: Calculadora
Pantalla 13: Contrato
Pantalla 14: Firma Digital
Pantalla 15: Crédito Aplicado
Pantalla 16: Código QR
Pantalla 17: Checklist Final
Pantalla 18: Tracking de Préstamo
```

**Next Milestones:**
- [ ] Implement customer search as main screen (Step 2)
- [ ] Implement customer verification across all stores
- [ ] Add age calculation and validation
- [ ] ✅ Remove all accessories references (COMPLETED v1.2)
- [ ] Hide approved_amount in vendor frontend (Step 8b, 9)
- [ ] Build loan tracking dashboard (Step 18)
- [ ] Complete payment tracking system
- [ ] Build navigation menu with Dashboard access
- [ ] Implement 18-screen vendor workflow

**Recent Changes (v1.3 - 2025-12-16):**
- ✅ Added third role: **Cobrador (Collection Agent)**
- ✅ Cobrador dashboard with overdue devices tracking
- ✅ MDM block permissions for Cobradores (can block, cannot unlock)
- ✅ Read-only payment history access for Cobradores
- ✅ Collection reports and analytics
- ✅ Auto-block for 30+ days overdue (automated job)
- ✅ Daily notifications to collection agents
- ✅ Complete permissions matrix (3 roles)
- ✅ Pundit policies updated for all roles
- ✅ Cobrador routes and controllers structure
- ✅ User model with role helpers (admin?, vendedor?, cobrador?)
- ✅ MdmBlockService with cobrador authorization
- ✅ **Restrictions**: Cobradores cannot create, edit, or delete anything

**Recent Changes (v1.2 - 2025-12-16):**
- ✅ Removed accessories completely from system
- ✅ Changed main screen from Dashboard to Customer Search (Step 2)
- ✅ Dashboard now accessible via navigation menu (secondary)
- ✅ Updated vendor workflow to 18 screens (was 19)
- ✅ Simplified loan structure (phone price only, no accessories)
- ✅ Renumbered all workflow steps
- ✅ Updated all business rules and validations
- ✅ Flow: Login → Search (Main) → [Process or Dashboard from menu]
