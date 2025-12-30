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

**Phase**: Phase 2 (Vendor Workflow Implementation) - 18-screen workflow in progress
**Current Milestone**: Vendor Workflow Implementation (18 Screens)
**Last Updated**: 2025-12-28

### Recent Highlights (Phase 2 Progress)
- ✅ Contract & Digital Signature implementation (Steps 13-14)
- ✅ Loan Tracking Dashboard (Step 18) with status filtering
- ✅ Vendor root set to Customer Search (Step 2 main screen)
- ✅ Complete navigation menu with Dashboard access
- ✅ Credit application form with debugging and validation
- ✅ Phase 1 foundation: Rails 8 auth, 3 roles, permissions matrix

**Completed Screens**: Step 1 (Login), Step 13-14 (Contract & Signature), Step 18 (Loan Tracking)
**In Progress**: Step 2 (Customer Search), Step 4-9 (Credit Application)

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