# MOVICUOTAS - Roles & Permissions

## Overview

The system has three user roles with different access levels:

| Role | Description | Branch Scope |
|------|-------------|--------------|
| **Admin** | Full system access | All branches |
| **Supervisor** | Payment verification, device blocking | All branches |
| **Vendedor** | Customer registration, loan creation | Own branch only |

---

## Admin (Administrador)

Full access to all system features.

### Permissions

| Area | View | Create | Edit | Delete | Special |
|------|:----:|:------:|:----:|:------:|---------|
| Customers | All | Yes | Yes | Yes | Block customers |
| Loans | All | Yes | Yes | Yes | Approve manually |
| Payments | All | Yes | Yes | Yes | Verify, Reject |
| Devices | All | Yes | Yes | Yes | Block (MDM), Unblock |
| Users | All | Yes | Yes | Yes | Manage all roles |
| Down Payments | All | - | - | - | Collect, Verify deposits |
| Contracts | All | Yes | Yes | Yes | Download |
| Reports | All | - | - | - | Export all |
| System | - | - | - | - | Configuration, Audit logs |

### Dashboard Access
- Full analytics across all branches
- All metrics and reports

---

## Supervisor

Payment management, verification, and reporting. **Not limited by branch. Does NOT do sales.**

### Permissions

| Area | View | Create | Edit | Delete | Special |
|------|:----:|:------:|:----:|:------:|---------|
| Customers | All | No | No | No | - |
| Loans | All | No | No | No | - |
| Payments | All | Yes | Yes | No | Verify, Reject |
| Devices | All | No | No | No | Block (MDM) |
| Users | No | No | No | No | - |
| Down Payments | All | - | - | - | Verify deposits |
| Contracts | All | No | No | No | Download |
| Reports | All | - | - | - | Export collection reports |
| System | No | - | - | - | - |

### Dashboard Access
- Collection analytics
- Payment verification queue
- Device blocking status
- Overdue metrics

### Key Responsibilities
- **Create payments**: Register payments directly (without customer receipt)
- **Update payments**: Modify payment details, add reference numbers
- **Verify payments**: Review receipt, add reference number, bank source, optional verification image
- **Reject payments**: Add rejection reason (required)
- **Block devices**: Block overdue devices via MDM (30+ days overdue)
- **Monitor collections**: View collection reports and overdue metrics

### Restrictions
- **Does NOT do sales** - no credit applications, no customer registration
- Cannot create, edit, or delete customers
- Cannot create, edit, or delete loans
- Cannot unblock devices (admin only)
- Cannot manage users
- Cannot access system configuration

---

## Vendedor (Sales)

Sales operations limited to their assigned branch.

### Permissions

| Area | View | Create | Edit | Delete | Special |
|------|:----:|:------:|:----:|:------:|---------|
| Customers | All | Yes | Yes | No | - |
| Loans | Own branch | Yes | Own only | No | - |
| Payments | Own branch | Yes | No | No | - |
| Devices | All | Yes | Yes | No | Assign only |
| Users | No | No | No | No | - |
| Down Payments | Own branch | - | - | - | Collect only |
| Contracts | Own branch | Yes | Yes | No | Download |
| Reports | Own sales | - | - | - | Export own only |
| System | No | - | - | - | - |

### Dashboard Access
- Sales analytics for own branch only
- Own performance metrics
- Pending credit applications

### Key Responsibilities
- **Customer registration**: Register new customers with ID verification
- **Credit applications**: Create and process credit applications (18-screen flow)
- **Loan contracts**: Generate and process loan contracts
- **Down payments**: Collect down payments at point of sale
- **Payment registration**: Register customer payments (creates pending record for verification)
- **Device assignment**: Assign devices to customers after loan approval

### Restrictions
- Cannot view/manage other branches' loans or payments
- Cannot verify or reject payments (only registers them)
- Cannot update payments after creation
- Cannot block/unblock devices via MDM
- Cannot verify down payment deposits (admin/supervisor only)
- Cannot manage users
- Cannot access system configuration or audit logs

---

## Quick Reference Matrix

### Customer Management

| Action | Admin | Supervisor | Vendedor |
|--------|:-----:|:----------:|:--------:|
| View all customers | Yes | Yes | Yes |
| Create customer | Yes | No | Yes |
| Edit customer | Yes | No | Yes |
| Delete customer | Yes | No | No |
| Block customer | Yes | No | No |

### Loan Management

| Action | Admin | Supervisor | Vendedor |
|--------|:-----:|:----------:|:--------:|
| View loans | All | All | Own branch |
| Create loan | Yes | No | Yes |
| Edit loan | Yes | No | Own only |
| Delete loan | Yes | No | No |
| Approve loan | Yes | No | Auto-approved |

### Payment Management

| Action | Admin | Supervisor | Vendedor |
|--------|:-----:|:----------:|:--------:|
| View payments | All | All | Own branch |
| Register payment | Yes | Yes | Yes |
| Update payment | Yes | Yes | No |
| Verify payment | Yes | Yes | No |
| Reject payment | Yes | Yes | No |
| Delete payment | Yes | No | No |

> **Note**:
> - **Supervisor** can create/update payments directly without customer receipt
> - **Vendedor** can register payments but cannot modify them after creation

### Device Management

| Action | Admin | Supervisor | Vendedor |
|--------|:-----:|:----------:|:--------:|
| View devices | All | All | All |
| Assign device | Yes | No | Yes |
| Block device (MDM) | Yes | Yes | No |
| Unblock device | Yes | No | No |
| Delete device | Yes | No | No |

### User Management

| Action | Admin | Supervisor | Vendedor |
|--------|:-----:|:----------:|:--------:|
| View users | Yes | No | No |
| Create user | Yes | No | No |
| Edit user | Yes | No | No |
| Delete user | Yes | No | No |

### Reports & Analytics

| Action | Admin | Supervisor | Vendedor |
|--------|:-----:|:----------:|:--------:|
| View all reports | Yes | Yes | No |
| View own sales | Yes | No | Yes |
| View collection reports | Yes | Yes | No |
| Export reports | All | Collection | Own only |

### System

| Action | Admin | Supervisor | Vendedor |
|--------|:-----:|:----------:|:--------:|
| System configuration | Yes | No | No |
| View audit logs | Yes | No | No |
| Manage QR codes | Yes | No | No |

---

## Branch Scope Rules

### Admin
- Can access all branches
- No restrictions on data visibility

### Supervisor
- Can access all branches
- No branch restrictions
- Focuses on payment verification and device blocking

### Vendedor
- **Loans**: Only sees loans from their assigned branch
- **Payments**: Only sees payments for loans in their branch
- **Can register**: Only payments for their branch's loans
- **Customers**: Can see all (needed for customer lookup)
- **Devices**: Can see all (needed for device assignment)

---

## Implementation Notes

### Role Values in Database
```ruby
# User model enum
enum :role, { admin: "admin", supervisor: "supervisor", vendedor: "vendedor" }
```

### Policy Files
All permissions are implemented in `/app/policies/`:
- `payment_policy.rb` - Payment permissions with branch filtering for vendedor
- `loan_policy.rb` - Loan permissions with branch filtering for vendedor
- `customer_policy.rb` - Customer permissions
- `device_policy.rb` - Device permissions with MDM blocking
- `user_policy.rb` - User management (admin only)

### Scope Filtering
Pundit scopes automatically filter data based on user role:
```ruby
# Example: Vendedor only sees own branch payments
policy_scope(Payment) # Returns filtered results for vendedor
```

### Checking Permissions
```ruby
# In controllers
authorize @payment, :verify?

# In views
<% if policy(@payment).verify? %>
  <%= button_to "Verify", ... %>
<% end %>
```

---

## Payment Verification Workflow

### Flow Overview

There are two ways payments can be created:

#### Flow A: Customer-Initiated (via App)
```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Cliente   │ --> │ Pago Pendiente  │ --> │ Admin/Supervisor│
│  (App Móvil)│     │  (Backend)      │     │   (Verificar)   │
└─────────────┘     └─────────────────┘     └─────────────────┘
                                                    │
                                    ┌───────────────┴───────────────┐
                                    ▼                               ▼
                            ┌───────────────┐               ┌───────────────┐
                            │   Verificado  │               │   Rechazado   │
                            │ (Cuota=Pagado)│               │  (Con Razón)  │
                            └───────────────┘               └───────────────┘
```

#### Flow B: Supervisor-Initiated (Direct)
```
┌─────────────────┐     ┌─────────────────┐
│ Admin/Supervisor│ --> │   Verificado    │
│ (Crear Pago)    │     │ (Cuota=Pagado)  │
└─────────────────┘     └─────────────────┘
```
> **Supervisor puede crear pagos directamente** sin necesidad de que el cliente envíe comprobante.

### Step 1: Payment Creation

#### Option A: Customer Submits (App)
- Customer uses mobile app to report payment
- Uploads receipt image (comprobante)
- **Does NOT update installment status** - only creates pending payment record

#### Option B: Supervisor Creates Directly
- Supervisor creates payment in admin panel
- No customer receipt required
- Can add reference number, bank source, and verification image immediately

### Step 2: Payment Queue
- Admin/Supervisor sees pending payments in `/admin/payments?status=pending`
- Can view receipt image uploaded by customer
- Can see loan and customer details

### Step 3: Verification Decision

#### Option A: Verify Payment
Admin or Supervisor confirms the payment with optional details:

| Field | Description | Required |
|-------|-------------|:--------:|
| **Número de Referencia** | Bank/Tigo Money transaction reference | No |
| **Banco / Fuente** | BAC, Banpais, Atlántida, Ficohsa, Tigo Money, etc. | No |
| **Imagen de Verificación** | Bank confirmation image (separate from customer's receipt) | No |

When verified:
- Payment status → `verified`
- Associated installments → `paid`
- Audit log created with verifier info

#### Option B: Reject Payment
Admin or Supervisor rejects with required reason:

| Field | Description | Required |
|-------|-------------|:--------:|
| **Razón del Rechazo** | Why payment is being rejected | Yes |

Common rejection reasons:
- Comprobante ilegible
- Monto incorrecto
- Fecha no coincide
- Referencia inválida
- Pago duplicado

When rejected:
- Payment status → `rejected`
- Installments remain unpaid
- Audit log created with rejection reason

### Database Fields

```ruby
# Payment model
belongs_to :verified_by, class_name: "User", optional: true

# Fields
reference_number    # Bank/Tigo Money reference
bank_source         # Bank name or "Tigo Money"
verified_by_id      # Who verified/rejected
verified_at         # When verified/rejected
notes               # Rejection reason (if rejected)

# Attachments
has_one_attached :receipt_image        # From customer (app)
has_one_attached :verification_image   # From supervisor (verification)
```

### Bank Sources Available
- BAC Honduras
- Banpais
- Banco Atlántida
- Banco Ficohsa
- Banco de Occidente
- Banco Promerica
- Tigo Money
- Efectivo en Tienda
- Otro

---

## Summary Table

| Capability | Admin | Supervisor | Vendedor |
|------------|:-----:|:----------:|:--------:|
| Full system access | Yes | No | No |
| Create/update payments | Yes | Yes | Create only |
| Verify/reject payments | Yes | Yes | No |
| Block devices (MDM) | Yes | Yes | No |
| Unblock devices | Yes | No | No |
| Create customers/loans | Yes | No | Yes |
| Sales operations | Yes | No | Yes |
| Branch-limited | No | No | Yes |
| User management | Yes | No | No |
| System configuration | Yes | No | No |
