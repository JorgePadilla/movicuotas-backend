## Git Branching Strategy for Project Development

### Overview

This project will be built using a **feature branch workflow** where each major component is developed in isolation and then merged into `main`. This approach allows:
- Parallel development of independent features
- Clean commit history
- Easy code review
- Safe integration testing
- Ability to roll back specific features

### Branch Naming Convention

```
feature/[phase]-[component-name]
```

**Examples:**
- `feature/phase1-database-schema`
- `feature/phase2-vendor-customer-search`
- `feature/phase3-admin-dashboard`

### Project Phases and Branches

#### **Phase 1: Foundation (Database & Auth)**

These branches must be completed **in order** as they depend on each other:

```bash
# Branch 1: Database Schema & Models
feature/phase1-database-schema
  - Create all migrations (users, sessions, customers, devices, loans, etc.)
  - Generate all models
  - Add associations and validations
  - Create database indexes
  - Files: db/migrate/*, app/models/*

# Branch 2: Authentication System
feature/phase1-authentication
  - Depends on: phase1-database-schema
  - Setup bcrypt gem
  - Create Session model and controller
  - Create Current context
  - Add authentication helpers
  - Create login views
  - Files: app/controllers/sessions_controller.rb, app/models/session.rb, app/models/current.rb

# Branch 3: Authorization (Pundit)
feature/phase1-authorization
  - Depends on: phase1-authentication
  - Setup Pundit gem
  - Create policies for all models (User, Customer, Device, Loan, Payment)
  - Implement role-based permissions (admin/vendedor/cobrador)
  - Files: app/policies/*

# Branch 4: Seed Data
feature/phase1-seed-data
  - Depends on: phase1-database-schema, phase1-authentication
  - Create seed users (admin, vendedor, cobrador)
  - Create sample phone models
  - Create test customers and loans
  - Files: db/seeds.rb
```

#### **Phase 2: Vendor Workflow (18 Screens)**

These branches can be developed **in parallel** after Phase 1 is complete:

```bash
# Branch 5: Vendor - Customer Search (Steps 2-3)
feature/phase2-vendor-customer-search
  - Depends on: phase1-*
  - Step 2: Main search screen (search across ALL stores)
  - Step 3a: Cliente Bloqueado view
  - Step 3b: Cliente Disponible view
  - Business logic: Check active loans system-wide
  - Files: app/controllers/vendor/customer_search_controller.rb, app/views/vendor/customer_search/*

# Branch 6: Vendor - Credit Application (Steps 4-8)
feature/phase2-vendor-credit-application
  - Depends on: phase1-*
  - Step 4: Datos Generales (with date_of_birth)
  - Step 5: Fotografías (S3 upload)
  - Step 6: Datos Laborales
  - Step 7: Resumen Solicitud
  - Step 8a/8b: Approval/Rejection
  - Step 9: Recuperar Solicitud
  - Service: CreditApprovalService
  - Files: app/controllers/vendor/credit_applications_controller.rb, app/services/credit_approval_service.rb

# Branch 7: Vendor - Device Selection (Steps 10-11)
feature/phase2-vendor-device-selection
  - Depends on: phase1-*
  - Step 10: Phone catalog (no accessories)
  - Step 11: Confirmation
  - Validation: phone_price <= approved_amount
  - Files: app/controllers/vendor/device_selections_controller.rb

# Branch 8: Vendor - Payment Calculator (Step 12)
feature/phase2-vendor-payment-calculator
  - Depends on: phase1-*
  - Step 12: Bi-weekly calculator
  - Down payment options: 30%, 40%, 50%
  - Installment terms: 6, 8, 10, 12 periods
  - Service: BiweeklyCalculatorService
  - Files: app/controllers/vendor/payment_calculators_controller.rb, app/services/biweekly_calculator_service.rb

# Branch 9: Vendor - Contract & Signature (Steps 13-15)
feature/phase2-vendor-contract-signature
  - Depends on: phase1-*
  - Step 13: Contract display (PDF generation)
  - Step 14: Digital signature (S3 upload)
  - Step 15: Success confirmation
  - Service: ContractGeneratorService
  - Files: app/controllers/vendor/contracts_controller.rb, app/services/contract_generator_service.rb

# Branch 10: Vendor - MDM Configuration (Steps 16-17)
feature/phase2-vendor-mdm-configuration
  - Depends on: phase1-*
  - Step 16: QR code generation (BluePrint)
  - Step 17: Final checklist
  - Service: MdmService
  - Files: app/controllers/vendor/mdm_blueprints_controller.rb, app/services/mdm_service.rb

# Branch 11: Vendor - Loan Finalization
feature/phase2-vendor-loan-finalization
  - Depends on: phase1-*, phase2-vendor-payment-calculator, phase2-vendor-contract-signature
  - Create loan with contract_number
  - Generate bi-weekly installments
  - Assign device atomically
  - Service: LoanFinalizationService
  - Files: app/controllers/vendor/loans_controller.rb, app/services/loan_finalization_service.rb

# Branch 12: Vendor - Dashboard & Tracking (Step 18)
feature/phase2-vendor-dashboard
  - Depends on: phase1-*
  - Vendor dashboard (accessible from menu)
  - Step 18: Loan tracking
  - Display stats and recent activity
  - Files: app/controllers/vendor/dashboard_controller.rb
```

#### **Phase 3: Admin Interface**

These can be developed **in parallel** after Phase 1:

```bash
# Branch 13: Admin - Dashboard
feature/phase3-admin-dashboard
  - Depends on: phase1-*
  - Overview statistics
  - System-wide metrics
  - Files: app/controllers/admin/dashboard_controller.rb

# Branch 14: Admin - User Management
feature/phase3-admin-users
  - Depends on: phase1-authorization
  - CRUD for users (admin/vendedor/cobrador)
  - Only admins can access
  - Files: app/controllers/admin/users_controller.rb

# Branch 15: Admin - Customer Management
feature/phase3-admin-customers
  - Depends on: phase1-*
  - View all customers
  - Edit customer details
  - Block/unblock customers
  - Files: app/controllers/admin/customers_controller.rb

# Branch 16: Admin - Loan Management
feature/phase3-admin-loans
  - Depends on: phase1-*
  - View all loans (all branches)
  - Edit loan details
  - Manually adjust installments
  - Files: app/controllers/admin/loans_controller.rb

# Branch 17: Admin - Payment Verification
feature/phase3-admin-payments
  - Depends on: phase1-*
  - View all payments
  - Verify payment receipts (S3)
  - Approve/reject payments
  - Service: PaymentProcessorService
  - Files: app/controllers/admin/payments_controller.rb, app/services/payment_processor_service.rb

# Branch 18: Admin - Reports
feature/phase3-admin-reports
  - Depends on: phase1-*, phase3-admin-loans, phase3-admin-payments
  - Sales reports by branch
  - Payment collection reports
  - Overdue accounts reports
  - Export to PDF/Excel
  - Files: app/controllers/admin/reports_controller.rb
```

#### **Phase 4: Cobrador Interface**

These can be developed **in parallel** after Phase 1:

```bash
# Branch 19: Cobrador - Dashboard
feature/phase4-cobrador-dashboard
  - Depends on: phase1-*
  - Overdue devices summary
  - Blocked devices count
  - Collection metrics
  - Files: app/controllers/cobrador/dashboard_controller.rb

# Branch 20: Cobrador - Overdue Devices
feature/phase4-cobrador-overdue-devices
  - Depends on: phase1-*
  - List overdue devices
  - Filter by days/amount/branch
  - Device detail view (read-only)
  - Files: app/controllers/cobrador/overdue_devices_controller.rb

# Branch 21: Cobrador - MDM Blocking
feature/phase4-cobrador-mdm-blocking
  - Depends on: phase1-authorization, phase4-cobrador-overdue-devices
  - Block device functionality
  - Service: MdmBlockService
  - Background job: MdmBlockDeviceJob
  - Files: app/services/mdm_block_service.rb, app/jobs/mdm_block_device_job.rb

# Branch 22: Cobrador - Payment History (Read-Only)
feature/phase4-cobrador-payment-history
  - Depends on: phase1-*
  - View payment history (no edit/delete)
  - View installment schedule
  - Export to PDF
  - Files: app/controllers/cobrador/payment_history_controller.rb

# Branch 23: Cobrador - Collection Reports
feature/phase4-cobrador-collection-reports
  - Depends on: phase4-cobrador-overdue-devices
  - Overdue by days range
  - Overdue by branch
  - Recovery rate calculation
  - Files: app/controllers/cobrador/collection_reports_controller.rb
```

#### **Phase 5: Background Jobs**

Can be developed **in parallel** with Phases 2-4:

```bash
# Branch 24: Background Jobs - Notifications
feature/phase5-jobs-notifications
  - Depends on: phase1-database-schema
  - SendPaymentReminderJob
  - NotifyCollectionAgentJob
  - FCM notification integration
  - Files: app/jobs/*_job.rb

# Branch 25: Background Jobs - Late Payments
feature/phase5-jobs-late-payments
  - Depends on: phase1-database-schema
  - MarkOverdueInstallmentsJob (daily)
  - CalculateLateFeeJob
  - Files: app/jobs/mark_overdue_installments_job.rb

# Branch 26: Background Jobs - Auto Block
feature/phase5-jobs-auto-block
  - Depends on: phase4-cobrador-mdm-blocking
  - AutoBlockDeviceJob (30+ days overdue)
  - Files: app/jobs/auto_block_device_job.rb
```

#### **Phase 6: API for Mobile App**

Can be developed **in parallel** after Phase 1:

```bash
# Branch 27: API - Authentication
feature/phase6-api-authentication
  - Depends on: phase1-authentication
  - Token-based auth (JWT or similar)
  - Login with identification_number
  - Files: app/controllers/api/v1/auth_controller.rb

# Branch 28: API - Customer Dashboard
feature/phase6-api-dashboard
  - Depends on: phase1-database-schema
  - GET /api/v1/dashboard (loan info, next payment)
  - Files: app/controllers/api/v1/dashboard_controller.rb

# Branch 29: API - Payments
feature/phase6-api-payments
  - Depends on: phase1-database-schema
  - POST /api/v1/payments (with receipt upload to S3)
  - GET /api/v1/installments
  - Files: app/controllers/api/v1/payments_controller.rb

# Branch 30: API - Notifications
feature/phase6-api-notifications
  - Depends on: phase1-database-schema
  - GET /api/v1/notifications
  - Mark as read
  - Files: app/controllers/api/v1/notifications_controller.rb
```

#### **Phase 7: UI Components & Styling**

Can be developed **in parallel** throughout:

```bash
# Branch 31: ViewComponents - Shared
feature/phase7-components-shared
  - Depends on: None (can start anytime)
  - Status badges (with color palette)
  - Alert banners (success/error/warning)
  - Card components
  - Button components
  - Files: app/components/shared/*

# Branch 32: ViewComponents - Admin
feature/phase7-components-admin
  - Depends on: phase7-components-shared
  - Admin-specific UI components
  - Files: app/components/admin/*

# Branch 33: ViewComponents - Vendor
feature/phase7-components-vendor
  - Depends on: phase7-components-shared
  - Vendor workflow components
  - Files: app/components/vendor/*

# Branch 34: ViewComponents - Cobrador
feature/phase7-components-cobrador
  - Depends on: phase7-components-shared
  - Collection agent components
  - Files: app/components/cobrador/*

# Branch 35: Tailwind Configuration
feature/phase7-tailwind-config
  - Depends on: None
  - Configure corporate colors (#125282, etc.)
  - Custom utility classes
  - Files: config/tailwind.config.js, app/assets/stylesheets/*
```

#### **Phase 8: Testing**

Develop **in parallel** with features:

```bash
# Branch 36: Tests - Models
feature/phase8-tests-models
  - Depends on: phase1-database-schema
  - Unit tests for all models
  - Validation tests
  - Association tests
  - Files: test/models/*

# Branch 37: Tests - Services
feature/phase8-tests-services
  - Depends on: Service branches (phase2-*, phase3-*, phase4-*)
  - Unit tests for all services
  - Business logic tests
  - Files: test/services/*

# Branch 38: Tests - Controllers
feature/phase8-tests-controllers
  - Depends on: Controller branches
  - Integration tests for all controllers
  - Authorization tests
  - Files: test/controllers/*

# Branch 39: Tests - System
feature/phase8-tests-system
  - Depends on: All phases complete
  - End-to-end workflow tests
  - Vendor 18-step workflow test
  - Files: test/system/*
```

---

### Git Workflow Commands

#### 1. Starting a New Feature Branch

```bash
# Make sure main is up to date
git checkout main
git pull origin main

# Create and switch to new feature branch
git checkout -b feature/phase1-database-schema

# Start working on your feature
# ... make changes ...
```

#### 2. Working on a Feature

```bash
# Check status
git status

# Stage changes
git add app/models/user.rb
git add db/migrate/

# Or stage all changes
git add .

# Commit with descriptive message
git commit -m "Add User model with has_secure_password and role enum"

# Push to remote (first time)
git push -u origin feature/phase1-database-schema

# Push subsequent commits
git push
```

#### 3. Keeping Feature Branch Updated

```bash
# While working on feature branch, periodically sync with main
git checkout main
git pull origin main

git checkout feature/phase1-database-schema
git merge main

# Or use rebase for cleaner history (advanced)
git rebase main
```

#### 4. Completing a Feature (Ready to Merge)

```bash
# Make sure all changes are committed
git status

# Push latest changes
git push

# Switch to main and update
git checkout main
git pull origin main

# Merge feature branch (--no-ff keeps branch history)
git merge --no-ff feature/phase1-database-schema

# Or use GitHub/GitLab Pull Request for code review (recommended)
# Push to remote and create PR on GitHub
```

#### 5. Handling Merge Conflicts

```bash
# If merge has conflicts
git merge feature/phase2-vendor-customer-search

# Git will show conflicts. Open conflicted files and resolve.
# Look for markers: <<<<<<<, =======, >>>>>>>

# After resolving, stage resolved files
git add app/controllers/vendor/customer_search_controller.rb

# Complete the merge
git commit -m "Merge feature/phase2-vendor-customer-search into main"
```

#### 6. Deleting Merged Branches

```bash
# After successful merge, delete local branch
git branch -d feature/phase1-database-schema

# Delete remote branch
git push origin --delete feature/phase1-database-schema
```

---

### Merge Order and Dependencies

Follow this order to avoid dependency issues:

**Week 1: Foundation**
1. `feature/phase1-database-schema` → merge to main
2. `feature/phase1-authentication` → merge to main
3. `feature/phase1-authorization` → merge to main
4. `feature/phase1-seed-data` → merge to main

**Week 2-3: Vendor Workflow** (can work in parallel, merge when ready)
5. `feature/phase2-vendor-customer-search`
6. `feature/phase2-vendor-credit-application`
7. `feature/phase2-vendor-device-selection`
8. `feature/phase2-vendor-payment-calculator`
9. `feature/phase2-vendor-contract-signature`
10. `feature/phase2-vendor-mdm-configuration`
11. `feature/phase2-vendor-loan-finalization` (merge after calculator & contract)
12. `feature/phase2-vendor-dashboard`

**Week 3-4: Admin Interface** (can work in parallel)
13. `feature/phase3-admin-dashboard`
14. `feature/phase3-admin-users`
15. `feature/phase3-admin-customers`
16. `feature/phase3-admin-loans`
17. `feature/phase3-admin-payments`
18. `feature/phase3-admin-reports` (merge after loans & payments)

**Week 4-5: Cobrador Interface** (can work in parallel)
19. `feature/phase4-cobrador-dashboard`
20. `feature/phase4-cobrador-overdue-devices`
21. `feature/phase4-cobrador-mdm-blocking` (merge after overdue-devices)
22. `feature/phase4-cobrador-payment-history`
23. `feature/phase4-cobrador-collection-reports`

**Week 5: Background Jobs** (can work in parallel)
24. `feature/phase5-jobs-notifications`
25. `feature/phase5-jobs-late-payments`
26. `feature/phase5-jobs-auto-block` (merge after cobrador-mdm-blocking)

**Week 6: Mobile API** (can work in parallel)
27. `feature/phase6-api-authentication`
28. `feature/phase6-api-dashboard`
29. `feature/phase6-api-payments`
30. `feature/phase6-api-notifications`

**Throughout: UI & Testing** (merge as features complete)
31-35. UI Components (merge as needed by features)
36-39. Tests (merge alongside corresponding features)

---

### Integration Testing After Merges

After merging each branch:

```bash
# Run migrations
bin/rails db:migrate

# Run tests
bin/rails test

# Check for conflicts
bin/rails db:test:prepare
bin/rails test

# Start server and manually test
bin/dev
```

---

### Emergency Rollback

If a merge causes critical issues:

```bash
# Find the commit hash before the merge
git log --oneline

# Revert to previous commit (creates new commit)
git revert <commit-hash>

# Or hard reset (dangerous, only if not pushed)
git reset --hard <commit-hash-before-merge>
```

---

### Best Practices

1. **Commit Often**: Small, focused commits are easier to review and merge
2. **Descriptive Messages**: Use clear commit messages (e.g., "Add Customer model validation for email uniqueness")
3. **Test Before Merge**: Always run tests before merging to main
4. **Code Review**: Use Pull Requests for team review before merging
5. **One Feature Per Branch**: Don't mix unrelated changes
6. **Delete Merged Branches**: Keep repository clean
7. **Sync Regularly**: Pull from main frequently to avoid large conflicts

---

