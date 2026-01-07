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

Payment verification and device blocking operations. **Not limited by branch.**

### Permissions

| Area | View | Create | Edit | Delete | Special |
|------|:----:|:------:|:----:|:------:|---------|
| Customers | All | No | No | No | - |
| Loans | All | No | No | No | - |
| Payments | All | No | No | No | Verify, Reject |
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
- Verify customer payments
- Reject invalid payments (with reason)
- Block overdue devices via MDM
- Monitor collection reports

### Restrictions
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
- Register new customers
- Create credit applications
- Process loan contracts
- Collect down payments
- Register customer payments
- Assign devices to customers

### Restrictions
- Cannot view/manage other branches' loans or payments
- Cannot verify or reject payments
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
| Register payment | Yes | No | Yes |
| Verify payment | Yes | Yes | No |
| Reject payment | Yes | Yes | No |
| Delete payment | Yes | No | No |

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

## Summary Table

| Capability | Admin | Supervisor | Vendedor |
|------------|:-----:|:----------:|:--------:|
| Full system access | Yes | No | No |
| Verify/reject payments | Yes | Yes | No |
| Block devices (MDM) | Yes | Yes | No |
| Unblock devices | Yes | No | No |
| Create customers/loans | Yes | No | Yes |
| Register payments | Yes | No | Yes |
| Branch-limited | No | No | Yes |
| User management | Yes | No | No |
| System configuration | Yes | No | No |
