# MOVICUOTAS - Roles & Permissions

## Overview

The system has three user roles with different access levels:

| Role | Description | Primary Use |
|------|-------------|-------------|
| **Admin** | Full system access | System management, approvals, configuration |
| **Supervisor** | Sales operations (branch-limited) | Create loans, manage customers, verify payments |
| **Cobrador** | Collections (read-only + blocking) | View overdue accounts, block devices |

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
| Users | All | Yes | Yes | Yes | - |
| Down Payments | All | - | - | - | Collect, Verify deposits |
| Contracts | All | Yes | Yes | Yes | Download |
| Reports | All | - | - | - | Export all |
| System | - | - | - | - | Configuration, Audit logs |

### Dashboard Access
- Full analytics across all branches
- All metrics and reports

---

## Supervisor (Vendedor)

Sales operations limited to their assigned branch.

### Permissions

| Area | View | Create | Edit | Delete | Special |
|------|:----:|:------:|:----:|:------:|---------|
| Customers | All | Yes | Yes | No | - |
| Loans | Own branch | Yes | Own only | No | - |
| Payments | Own branch | Yes | Own only | No | Verify/Reject (own branch) |
| Devices | All | Yes | Yes | No | Assign only |
| Users | No | No | No | No | - |
| Down Payments | Own branch | - | - | - | Collect only |
| Contracts | Own branch | Yes | Yes | No | Download |
| Reports | Own sales | - | - | - | Export own only |
| System | No | - | - | - | - |

### Dashboard Access
- Sales analytics for own branch only
- Own performance metrics

### Restrictions
- Cannot view/manage other branches' loans or payments
- Cannot block/unblock devices via MDM
- Cannot verify down payment deposits (admin only)
- Cannot manage users
- Cannot access system configuration or audit logs

---

## Cobrador (Collector)

Read-only access focused on collections and device blocking.

### Permissions

| Area | View | Create | Edit | Delete | Special |
|------|:----:|:------:|:----:|:------:|---------|
| Customers | All (read-only) | No | No | No | - |
| Loans | All (read-only) | No | No | No | - |
| Payments | All (read-only) | No | No | No | - |
| Devices | Overdue only | No | No | No | Block (MDM) only |
| Users | No | No | No | No | - |
| Down Payments | No | - | - | - | - |
| Contracts | All (read-only) | No | No | No | - |
| Reports | Collection only | - | - | - | Export collection |
| System | No | - | - | - | - |

### Dashboard Access
- Collection analytics only
- Overdue metrics and device blocking status

### Restrictions
- Cannot create, edit, or delete any records
- Cannot register or verify payments
- Can only view devices with overdue installments
- Cannot unblock devices (admin only)
- Cannot manage users or system settings

---

## Quick Reference Matrix

### Customer Management

| Action | Admin | Supervisor | Cobrador |
|--------|:-----:|:----------:|:--------:|
| View all customers | Yes | Yes | Yes (read-only) |
| Create customer | Yes | Yes | No |
| Edit customer | Yes | Yes | No |
| Delete customer | Yes | No | No |
| Block customer | Yes | No | No |

### Loan Management

| Action | Admin | Supervisor | Cobrador |
|--------|:-----:|:----------:|:--------:|
| View loans | All | Own branch | All (read-only) |
| Create loan | Yes | Yes | No |
| Edit loan | Yes | Own only | No |
| Delete loan | Yes | No | No |
| Approve loan | Yes | Auto-approved | No |

### Payment Management

| Action | Admin | Supervisor | Cobrador |
|--------|:-----:|:----------:|:--------:|
| View payments | All | Own branch | All (read-only) |
| Register payment | Yes | Yes | No |
| Verify payment | Yes | Own branch | No |
| Reject payment | Yes | Own branch | No |
| Delete payment | Yes | No | No |

### Device Management

| Action | Admin | Supervisor | Cobrador |
|--------|:-----:|:----------:|:--------:|
| View devices | All | All | Overdue only |
| Assign device | Yes | Yes | No |
| Block device (MDM) | Yes | No | Yes |
| Unblock device | Yes | No | No |
| Delete device | Yes | No | No |

### User Management

| Action | Admin | Supervisor | Cobrador |
|--------|:-----:|:----------:|:--------:|
| View users | Yes | No | No |
| Create user | Yes | No | No |
| Edit user | Yes | No | No |
| Delete user | Yes | No | No |

### Reports & Analytics

| Action | Admin | Supervisor | Cobrador |
|--------|:-----:|:----------:|:--------:|
| View all reports | Yes | No | No |
| View own sales | Yes | Yes | No |
| View collection reports | Yes | No | Yes |
| Export reports | All | Own only | Collection only |

### System

| Action | Admin | Supervisor | Cobrador |
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
- **Loans**: Only sees loans from their assigned branch
- **Payments**: Only sees payments for loans in their branch
- **Can verify/reject**: Only payments from their branch
- **Customers**: Can see all (needed for new customer lookup)
- **Devices**: Can see all (needed for device assignment)

### Cobrador
- No branch restrictions
- Limited to overdue-related data
- Read-only access to most areas

---

## Implementation Notes

### Policy Files
All permissions are implemented in `/app/policies/`:
- `payment_policy.rb` - Payment permissions with branch filtering
- `loan_policy.rb` - Loan permissions with branch filtering
- `customer_policy.rb` - Customer permissions
- `device_policy.rb` - Device permissions with overdue filtering
- `user_policy.rb` - User management (admin only)

### Scope Filtering
Pundit scopes automatically filter data based on user role:
```ruby
# Example: Supervisor only sees own branch payments
policy_scope(Payment) # Returns filtered results
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
