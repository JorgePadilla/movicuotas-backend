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

**Recent Changes (v1.4 - 2025-12-16):**
- ✅ Migrated from Devise to **Rails 8 built-in authentication**
- ✅ Using `has_secure_password` with bcrypt
- ✅ Session-based authentication with signed cookies
- ✅ Custom `Session` model for tracking user sessions
- ✅ `Current` context for thread-safe user access
- ✅ Role-based redirects after login (admin/vendedor/cobrador)
- ✅ Database migrations for `users` and `sessions` tables
- ✅ Authentication controller patterns and helpers
- ✅ Updated all documentation to reflect Rails 8 auth

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
