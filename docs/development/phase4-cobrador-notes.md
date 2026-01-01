# Phase 4: Cobrador Interface Implementation

**Status:** In Progress
**Start Date:** 2026-01-01
**Target Completion:** Q1 2026

## Overview

Phase 4 implements the Cobrador (Collection Agent) interface for MOVICUOTAS. The Cobrador role is specifically designed for collection agents who manage overdue accounts and device blocking through the MDM system. This phase focuses on read-only data access with the critical ability to execute device locks.

## Completed Features (7/11)

### 1. ✅ Cobrador Dashboard (`/cobrador/dashboard`)

**File:** `app/controllers/cobrador/dashboard_controller.rb`
**View:** `app/views/cobrador/dashboard/index.html.erb`

**Features:**
- Real-time metrics on overdue installments
- Blocked devices tracking (locked, pending, recent)
- Breakdown of overdue by days (1-7, 8-15, 16-30, 30+ days)
- Quick access to all Cobrador features
- Responsive design with Tailwind CSS

**Metrics Displayed:**
- Total overdue installments count
- Total overdue amount (RD$)
- Blocked devices count
- Pending blocks count
- Recent blocks (last 7 days)

### 2. ✅ Overdue Devices List (`/cobrador/overdue_devices`)

**File:** `app/controllers/cobrador/overdue_devices_controller.rb`
**View:** `app/views/cobrador/overdue_devices/index.html.erb`

**Features:**
- Advanced filtering capabilities
- Filter by: minimum days overdue, minimum amount, branch
- Displays: customer name, IMEI, device model, contract number
- Device status indicators (🔴 Bloqueado, 🟡 Pendiente, 🟢 Desbloqueado)
- Links to device detail pages
- Sortable columns by days overdue and amount

**Authorization:** Cobradores see only devices with overdue installments

### 3. ✅ Device Detail View (`/cobrador/overdue_devices/:id`)

**File:** `app/controllers/cobrador/overdue_devices_controller.rb`
**View:** `app/views/cobrador/overdue_devices/show.html.erb`

**Displays:**
- Device information (IMEI, brand, model, lock status)
- Customer information (name, phone, identification)
- Loan details (contract number, status)
- Overdue information (total amount, days overdue, count)
- Complete overdue installments table with details
- Upcoming installments preview
- Block device action button (for unlocked devices only)

### 4. ✅ Device Blocking Service

**File:** `app/services/mdm_block_service.rb`

**Key Features:**
- Authorization checks (Cobrador or Admin only)
- Prevents blocking already-locked devices
- Updates device lock status to "pending"
- Creates audit log entries automatically
- Prepared for MDM job queue integration
- Handles customer notifications setup

**Usage:**
```ruby
service = MdmBlockService.new(device, current_user)
result = service.block!
# Returns: { success: true, message: "..." } or { error: "..." }
```

### 5. ✅ Block Confirmation Page (`/cobrador/overdue_devices/:id/block`)

**View:** `app/views/cobrador/overdue_devices/block_confirmation.html.erb`

**Features:**
- Clear warning about blocking consequences
- Complete device, customer, and overdue information
- Shows RD$ amount and days overdue
- Confirms the action before execution
- Cancel option to prevent accidental blocks

### 6. ✅ Payment History Read-Only View (`/cobrador/loans/:loan_id/payment-history`)

**File:** `app/controllers/cobrador/payment_history_controller.rb`
**View:** `app/views/cobrador/payment_history/show.html.erb`

**Features:**
- Complete installments history with status
- Payment history with verification status
- Summary statistics (paid, pending, overdue)
- No edit/delete capabilities
- Displays receipt status for payments
- Customer contract information

**Authorization:** Read-only for all users, Cobradores can see all loans

### 7. ✅ Collection Reports (`/cobrador/collection-reports`)

**File:** `app/controllers/cobrador/collection_reports_controller.rb`
**View:** `app/views/cobrador/collection_reports/index.html.erb`

**Features:**
- Date range filtering (defaults to 30 days)
- Summary metrics dashboard:
  - Total overdue count and amount
  - Blocked devices count
  - At-risk (unlocked) devices with overdue
  - Recovery rate calculation
- Breakdown by days overdue
- Breakdown by branch
- Recent blocks table with timestamps
- Visual progress bars for data comparison

## Remaining Tasks (4/11)

### 1. ⏳ MDM API Integration
- Implement `MdmBlockDeviceJob` for async blocking
- Connect to actual MDM API endpoint
- Handle MDM success/failure responses
- Update device status to "locked" on confirmation
- Implement retry logic for failed blocks

### 2. ⏳ Customer Notifications
- Implement `NotificationService` for device lock warnings
- Send FCM (Firebase Cloud Messaging) notifications
- SMS notifications (optional)
- Email notifications to customers
- Include unlock timeline (e.g., "3 days to unlock")

### 3. ⏳ Batch Device Blocking Operations
- Create batch blocking UI for multiple devices
- Implement transaction safety for batch operations
- Progress tracking for batch operations
- Audit logging for each block in batch

### 4. ⏳ Advanced Export
- PDF export for collection reports
- Excel export with multiple sheets
- Date-based file naming
- Download from reports page

## Routes

```ruby
namespace :cobrador do
  get "dashboard", to: "dashboard#index"

  resources :overdue_devices, only: [:index, :show] do
    member do
      get :block
      post :confirm_block
    end
  end

  get "loans/:loan_id/payment-history", to: "payment_history#show", as: "loan_payment_history"
  get "collection-reports", to: "collection_reports#index", as: "collection_reports"
end
```

## Controllers

### DashboardController
- `index` - Display Cobrador dashboard with metrics

### OverdueDevicesController
- `index` - List overdue devices with filters
- `show` - Display device detail
- `block` - Show block confirmation page
- `confirm_block` - Execute device block via service

### PaymentHistoryController
- `show` - Display loan payment history

### CollectionReportsController
- `index` - Display collection reports with analytics

## Policies (Pundit)

### Key Authorization Rules

**DevicePolicy:**
- `index?` - All authenticated users can view devices (scope filters for Cobrador)
- `show?` - All authenticated users can view device details
- `lock?` - Only Admin and Cobrador can block devices

**LoanPolicy:**
- `index?` - All authenticated users can view loans (scope filters)
- `show?` - All authenticated users can view loan details
- **Scope for Cobrador:** All loans (read-only access)

**PaymentPolicy:**
- `index?` - All authenticated users can view payments
- `show?` - All authenticated users can view payment details
- **Scope for Cobrador:** All payments (read-only access)

## Test Coverage

**Test Files Created:**
- `test/controllers/cobrador/dashboard_controller_test.rb`
- `test/controllers/cobrador/overdue_devices_controller_test.rb`
- `test/controllers/cobrador/payment_history_controller_test.rb`
- `test/controllers/cobrador/collection_reports_controller_test.rb`
- `test/services/mdm_block_service_test.rb`

**Test Coverage Areas:**
- Authorization checks (Cobrador access, Vendedor denial, Admin access)
- Dashboard metrics calculation
- Overdue devices filtering (days, amount, branch)
- Device detail display
- Block confirmation workflow
- Block service execution and validation
- Payment history read-only enforcement
- Collection reports metrics and filtering

## Database Considerations

**Models Used:**
- `Device` - Device information and lock status
- `Loan` - Loan details and associations
- `Customer` - Customer information
- `Installment` - Payment schedule and status
- `Payment` - Payment records
- `AuditLog` - Audit trail for device blocks
- `User` - User information (locked_by reference)

**Key Attributes:**
- `devices.lock_status` - "unlocked", "pending", "locked"
- `devices.locked_at` - Timestamp of block request
- `devices.locked_by` - User who initiated block
- `installments.status` - "pending", "paid", "overdue", "cancelled"
- `installments.due_date` - Used for days overdue calculation

## Security Considerations

1. **Authorization:** All endpoints protected with Pundit policies
2. **Read-Only:** Payment and loan data is read-only for Cobradores
3. **Audit Logging:** All device blocks are logged with user and timestamp
4. **Transaction Safety:** Device blocking uses database transactions
5. **Data Filtering:** Cobrador scope limits to relevant devices only

## UI/UX Patterns

- **Metrics Cards:** Dashboard uses card-based layout for metrics
- **Filtering Form:** Advanced filters with clear labels
- **Status Indicators:** Color-coded status badges (red, yellow, green)
- **Confirmation Workflow:** Multi-step process for critical actions
- **Responsive Tables:** Mobile-friendly with horizontal scroll
- **Warning Sections:** Highlighted warnings for blocking actions
- **Summary Cards:** Quick stats in dashboard header

## Performance Considerations

- **Database Queries:** Uses `select` to limit returned columns
- **Eager Loading:** Includes necessary associations to prevent N+1 queries
- **Scope Filtering:** Device scope filters at database level
- **Aggregations:** Uses `sum`, `count` at database level
- **Pagination:** Ready for pagination if dataset grows large

## Future Enhancements

1. **Real-Time Updates:** WebSocket updates for dashboard metrics
2. **Bulk Operations:** Block multiple devices at once
3. **Predictive Analytics:** Highlight at-risk devices before overdue
4. **SMS Integration:** Send payment reminders automatically
5. **Mobile App:** Native mobile app for field agents
6. **QR Code Scanning:** Quick device lookup via QR codes
7. **Payment Plans:** Allow customers to set up payment plans
8. **Dispute Resolution:** Allow customers to dispute blocks

## Deployment Notes

- Feature branch: `feature/phase4-cobrador-dashboard`
- Worktree location: `/Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase4-cobrador-dash`
- Routes already configured and ready
- Tests comprehensive and passing
- No database migrations required (uses existing schema)
