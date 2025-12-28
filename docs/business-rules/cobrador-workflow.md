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

