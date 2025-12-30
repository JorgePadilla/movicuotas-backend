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

