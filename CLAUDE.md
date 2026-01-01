# CLAUDE.md - AI Assistant Context

This file provides context for AI assistants (like Claude Code) working on this project. This is a concise overview - detailed documentation is split into focused files in the `docs/` directory.

## Project Identity

**Name**: MOVICUOTAS Backend
**Full Brand**: MOVICUOTAS - Tu Crédito, Tu Móvil
**Type**: Rails 8 Admin Platform + REST API
**Purpose**: Credit management system for mobile phone sales
**Brand Color**: #125282 (RGB: 18, 82, 130)

## Tech Stack ([details](docs/architecture/tech-stack.md))

- Ruby on Rails 8, PostgreSQL
- Turbo (Hotwire) + ViewComponent 4 + Stimulus
- Solid Queue (background jobs)
- ActiveStorage with AWS S3
- Rails 8 built-in auth (`has_secure_password`) + Pundit
- REST API (`/api/v1`) for Flutter mobile app

## Project Structure ([details](docs/architecture/project-structure.md))

```
movicuotas-backend/
├── app/components/        # ViewComponent 4
├── app/controllers/       # Admin, Vendor, API
├── app/models/           # Core domain models
├── app/policies/         # Pundit
├── app/services/         # Business logic
├── app/jobs/            # Solid Queue
├── db/                  # Migrations, seeds
└── test/                # Minitest
```

## Core Domain Models ([details](docs/business-rules/domain-models.md))

**Three User Types**: Admin (full access), Vendedor (sales), Cobrador (collections, read-only)

**Main Entities**: Customer, Device, Loan, Installment, Payment, CreditApplication, PhoneModel, Contract, MdmBlueprint

## Documentation Index

Detailed documentation is organized into focused files:

### Architecture
- [Tech Stack](docs/architecture/tech-stack.md)
- [Project Structure](docs/architecture/project-structure.md)
- [Coding Conventions](docs/architecture/coding-conventions.md)
- [Authentication](docs/architecture/authentication.md)
- [API Endpoints](docs/architecture/api-endpoints.md)
- [Environment Configuration](docs/architecture/environment-config.md)
- [Security Checklist](docs/architecture/security-checklist.md)

### Business Rules
- [Vendor Workflow (18 screens)](docs/business-rules/vendor-workflow.md)
- [Cobrador Workflow](docs/business-rules/cobrador-workflow.md)
- [Domain Models](docs/business-rules/domain-models.md)
- [Permissions Matrix](docs/business-rules/permissions-matrix.md)
- [Vendor Reminders](docs/business-rules/vendor-reminders.md)

### Development
- [Git Workflow](docs/development/git-workflow.md)
- [Git Worktrees](docs/development/git-worktrees.md)
- [Turbo Patterns](docs/development/turbo-patterns.md)
- [Testing Guidelines](docs/development/testing-guidelines.md)
- [Background Jobs](docs/development/background-jobs.md)
- [Common Tasks & Commands](docs/development/common-tasks.md)
- [Common Pitfalls](docs/development/common-pitfalls.md)
- [Vendor Implementation Notes](docs/development/vendor-implementation-notes.md)
- [Development Philosophy](docs/development/philosophy.md)
- [Questions Guide](docs/development/questions-guide.md)
- [Useful References](docs/development/useful-references.md)

### UI & Design
- [Color Palette & Visual Style](docs/ui/color-palette.md)

### Project Status
- [Current Phase](docs/development/current-phase.md)
- [Project Status](docs/development/project-status.md)

## Current Status (Summary)

**Phase**: Phase 4 (Cobrador Interface Implementation) - COMPLETED ✅
**Current Milestone**: All Core Features Implemented - Ready for Deployment
**Last Updated**: 2026-01-01

### Phase 3 Completion (COMPLETED - 2025-12-28)
✅ **Admin Dashboard** - Comprehensive analytics and reporting
✅ **Admin Customers Management** - Full CRUD with filtering
✅ **Admin Loans Management** - View, edit, and manage all loans
✅ **Admin Payments Management** - Register and verify payments
✅ **Admin Reports** - Data export with CSV functionality
✅ **Admin Users Management** - User role and permissions management

### Phase 4 Completion (COMPLETED - 2026-01-01) ✅

**All Features Implemented:**
- ✅ Cobrador Dashboard with real-time metrics (overdue count, blocked devices, breakdown by days)
- ✅ Overdue Devices List with advanced filtering, pagination, sorting, CSV export
- ✅ Device Detail Page with complete overdue and customer information
- ✅ Device Blocking Service (MdmBlockService) with authorization checks
- ✅ Block Confirmation UI with multi-step safety warnings
- ✅ Bulk Device Selection & Blocking Operations
- ✅ Database Query Optimization with Strategic Indices
- ✅ Payment History Read-Only View
- ✅ Collection Reports with Analytics
- ✅ MDM API Integration Ready

**Recent Fixes (v1.9):**
- 🔧 Fixed Pundit authorization verification error in ReportsController
- 🔧 Fixed PostgreSQL GROUP BY error in revenue_report query
- 🔧 Fixed route helper names in admin reports (4 instances)
- 🔧 Fixed undefined method 'completed?' in admin customers view
- 🔧 Fixed broken vendor dashboard buttons (4 links)
- 🔧 Merged all Phase 4 worktrees to main
- 🔧 Fixed vendor dashboard monetary value formatting (BigDecimal precision)
- 🔧 All monetary values display with exactly 2 decimal places

**Previous Fixes:**
- Fixed vendor dashboard monetary value formatting (BigDecimal precision with format_currency helper)
- All monetary values now display with exactly 2 decimal places (L. 14,166.67)

*Detailed status: [docs/development/project-status.md](docs/development/project-status.md)*

## Key Principles

- **Security first**: Always authorize with Pundit, never bypass
- **Business logic in services**: Keep controllers thin
- **Use Rails conventions**: Don't fight the framework
- **Test the important stuff**: Business logic, calculations, authorization
- **Document as you go**: Update documentation when patterns change

*See [docs/development/philosophy.md](docs/development/philosophy.md) for full development philosophy.*

---

**Note for AI Assistants**: When working on this project, always check the relevant documentation files for detailed specifications. The vendor workflow (18 screens) is particularly important to understand before implementing features.