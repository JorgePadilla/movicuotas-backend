## Permissions Matrix

### User Roles Hierarchy

| Role | Description | Scope |
|------|-------------|-------|
| **Master** | Highest privileges - can delete loans | All branches |
| **Admin** | Full system access | All branches |
| **Supervisor** | Payment verification, device blocking, collections | All branches |
| **Vendedor** | Sales, customer registration, loan creation | Own branch only |

### Permissions by Action

| Action | Master | Admin | Supervisor | Vendedor |
|--------|--------|-------|------------|----------|
| **Customer Management** |
| View customers | ✅ | ✅ | ✅ | ✅ |
| Create customers | ✅ | ✅ | ❌ | ✅ |
| Edit customers | ✅ | ✅ | ❌ | ✅ |
| Delete customers | ✅ | ✅ | ❌ | ❌ |
| **Credit & Loans** |
| Create credit application | ✅ | ✅ | ❌ | ✅ |
| Approve credit | ✅ | ✅ | ❌ | Automatic |
| View loans | ✅ All | ✅ All | ✅ All | ✅ Own branch |
| Edit loans | ✅ | ✅ | ❌ | ✅ Own only |
| **Delete loans** | ✅ | ❌ | ❌ | ❌ |
| **Payments** |
| View payments | ✅ | ✅ | ✅ | ✅ |
| Register payment | ✅ | ✅ | ❌ | ✅ |
| Verify payment | ✅ | ✅ | ✅ | ❌ |
| Delete payment | ✅ | ✅ | ❌ | ❌ |
| **Device Management** |
| View devices | ✅ | ✅ | ✅ | ✅ |
| Assign device | ✅ | ✅ | ❌ | ✅ |
| Block device (MDM) | ✅ | ✅ | ✅ | ✅ |
| Unblock device | ✅ | ✅ | ✅ | ✅ |
| Delete device | ✅ | ✅ | ❌ | ❌ |
| **Reports** |
| View all reports | ✅ | ✅ | ❌ | ❌ |
| View own sales | ✅ | ✅ | ❌ | ✅ |
| View collection reports | ✅ | ✅ | ✅ | ❌ |
| Export reports | ✅ | ✅ | ✅ Collection | ✅ Own only |
| **User Management** |
| View users | ✅ | ✅ | ❌ | ❌ |
| Create users | ✅ | ✅ | ❌ | ❌ |
| Edit users | ✅ | ✅ | ❌ | ❌ |
| Delete users | ✅ | ✅ | ❌ | ❌ |
| **System** |
| System configuration | ✅ | ✅ | ❌ | ❌ |
| View audit logs | ✅ | ✅ | ❌ | ❌ |
| Mission Control Jobs | ✅ | ✅ | ❌ | ❌ |
| Admin Dashboard | ✅ | ✅ | ❌ | ❌ |
| Supervisor Dashboard | ✅ | ✅ | ❌ | ❌ |
| Vendor Dashboard | ✅ | ✅ | ✅ | ✅ |

### Key Differences: Master vs Admin

| Capability | Master | Admin |
|------------|--------|-------|
| Delete loans | ✅ | ❌ |
| All other admin permissions | ✅ | ✅ |

The Master role was created specifically for situations where loan deletion is necessary (e.g., test data cleanup, data corrections). Regular admins cannot delete loans to prevent accidental data loss.

### Implementation Notes

**Policy Helper Methods** (in `ApplicationPolicy`):
```ruby
def master?
  user&.master?
end

def admin?
  # Master has all admin permissions
  user&.admin? || user&.master?
end
```

**User Model Helper**:
```ruby
def can_delete_loans?
  master?
end
```

### Audit Logging

All important actions are logged:
```ruby
AuditLog.create!(
  user: current_user,
  action: 'locked',
  resource: device,
  changes: device.previous_changes
)
```
