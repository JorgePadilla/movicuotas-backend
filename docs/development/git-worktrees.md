### Git Worktree Setup for MOVICUOTAS

Git worktrees allow you to work on multiple branches simultaneously in separate directories. This is the **recommended approach** for this project.

#### Why Use Worktrees?

- ✅ Work on multiple phases in parallel without switching branches
- ✅ Run separate development servers for testing different features
- ✅ No risk of accidentally mixing changes from different branches
- ✅ Each worktree can have its own Claude Code instance
- ✅ Share the same Git history and commits

#### Initial Setup

```bash
# Navigate to main repository
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend

# Verify you're on main branch
git checkout main
git pull origin main

# Create parent directory for all worktrees (optional but recommended)
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas
mkdir worktrees
```

#### Creating Worktrees for Each Phase

**Phase 1: Foundation (Required First)**

```bash
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend

# Database Schema & Models
git worktree add ../worktrees/phase1-database feature/phase1-database-schema

# Authentication System
git worktree add ../worktrees/phase1-auth feature/phase1-authentication

# Authorization (Pundit)
git worktree add ../worktrees/phase1-authz feature/phase1-authorization

# Seed Data
git worktree add ../worktrees/phase1-seed feature/phase1-seed-data
```

**Phase 2: Vendor Workflow (Can work in parallel)**

```bash
# Customer Search (Steps 2-3)
git worktree add ../worktrees/phase2-customer-search feature/phase2-vendor-customer-search

# Credit Application (Steps 4-8)
git worktree add ../worktrees/phase2-credit-app feature/phase2-vendor-credit-application

# Device Selection (Steps 10-11)
git worktree add ../worktrees/phase2-device feature/phase2-vendor-device-selection

# Payment Calculator (Step 12)
git worktree add ../worktrees/phase2-calculator feature/phase2-vendor-payment-calculator

# Contract & Signature (Steps 13-15)
git worktree add ../worktrees/phase2-contract feature/phase2-vendor-contract-signature

# MDM Configuration (Steps 16-17)
git worktree add ../worktrees/phase2-mdm feature/phase2-vendor-mdm-configuration

# Loan Finalization
git worktree add ../worktrees/phase2-loan feature/phase2-vendor-loan-finalization

# Dashboard & Tracking (Step 18)
git worktree add ../worktrees/phase2-dashboard feature/phase2-vendor-dashboard
```

**Phase 3: Admin Interface (Can work in parallel)**

```bash
git worktree add ../worktrees/phase3-admin-dash feature/phase3-admin-dashboard
git worktree add ../worktrees/phase3-admin-users feature/phase3-admin-users
git worktree add ../worktrees/phase3-admin-customers feature/phase3-admin-customers
git worktree add ../worktrees/phase3-admin-loans feature/phase3-admin-loans
git worktree add ../worktrees/phase3-admin-payments feature/phase3-admin-payments
git worktree add ../worktrees/phase3-admin-reports feature/phase3-admin-reports
```

**Phase 4: Cobrador Interface (Can work in parallel)**

```bash
git worktree add ../worktrees/phase4-cobrador-dash feature/phase4-cobrador-dashboard
git worktree add ../worktrees/phase4-cobrador-overdue feature/phase4-cobrador-overdue-devices
git worktree add ../worktrees/phase4-cobrador-mdm feature/phase4-cobrador-mdm-blocking
git worktree add ../worktrees/phase4-cobrador-payments feature/phase4-cobrador-payment-history
git worktree add ../worktrees/phase4-cobrador-reports feature/phase4-cobrador-collection-reports
```

**Phase 5: Background Jobs**

```bash
git worktree add ../worktrees/phase5-jobs-notif feature/phase5-jobs-notifications
git worktree add ../worktrees/phase5-jobs-late feature/phase5-jobs-late-payments
git worktree add ../worktrees/phase5-jobs-block feature/phase5-jobs-auto-block
```

**Phase 6: Mobile API**

```bash
git worktree add ../worktrees/phase6-api-auth feature/phase6-api-authentication
git worktree add ../worktrees/phase6-api-dash feature/phase6-api-dashboard
git worktree add ../worktrees/phase6-api-payments feature/phase6-api-payments
git worktree add ../worktrees/phase6-api-notif feature/phase6-api-notifications
```

**Phase 7: UI Components**

```bash
git worktree add ../worktrees/phase7-ui-shared feature/phase7-components-shared
git worktree add ../worktrees/phase7-ui-admin feature/phase7-components-admin
git worktree add ../worktrees/phase7-ui-vendor feature/phase7-components-vendor
git worktree add ../worktrees/phase7-ui-cobrador feature/phase7-components-cobrador
git worktree add ../worktrees/phase7-tailwind feature/phase7-tailwind-config
```

**Phase 8: Testing**

```bash
git worktree add ../worktrees/phase8-tests-models feature/phase8-tests-models
git worktree add ../worktrees/phase8-tests-services feature/phase8-tests-services
git worktree add ../worktrees/phase8-tests-controllers feature/phase8-tests-controllers
git worktree add ../worktrees/phase8-tests-system feature/phase8-tests-system
```

#### Working with Worktrees

**Start working on a feature:**

```bash
# Navigate to worktree
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase1-database

# Verify branch
git branch
# Should show: * feature/phase1-database-schema

# Start Claude Code
claude

# Or open in VS Code
code .
```

**Open multiple Claude Code instances:**

```bash
# Terminal Tab 1: Database work
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase1-database
claude

# Terminal Tab 2: Authentication work
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase1-auth
claude

# Terminal Tab 3: UI Components work
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase7-ui-shared
claude
```

**Commit and push from worktree:**

```bash
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase1-database

# Make changes, then commit
git add .
git commit -m "Add Customer and Device models with validations"
git push -u origin feature/phase1-database-schema
```

**Keep worktree updated with main:**

```bash
# From within worktree
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase2-customer-search

# Pull latest main
git fetch origin main

# Merge main into your feature branch
git merge origin/main

# Or rebase for cleaner history
git rebase origin/main
```

#### Merging Completed Features

```bash
# After feature is complete and tested
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend

# Switch to main
git checkout main
git pull origin main

# Merge feature branch
git merge --no-ff feature/phase1-database-schema

# Push to remote
git push origin main

# Remove worktree (after merge)
git worktree remove ../worktrees/phase1-database

# Delete remote branch
git push origin --delete feature/phase1-database-schema

# Delete local branch
git branch -d feature/phase1-database-schema
```

#### List All Worktrees

```bash
# See all active worktrees
git worktree list

# Example output:
# /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend    27c276d [main]
# /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase1-database    abc1234 [feature/phase1-database-schema]
# /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees/phase1-auth        def5678 [feature/phase1-authentication]
```

#### Cleanup All Worktrees (After Project Complete)

```bash
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend

# List all worktrees
git worktree list

# Remove each worktree
git worktree remove ../worktrees/phase1-database
git worktree remove ../worktrees/phase1-auth
# ... etc

# Or prune all removed worktrees
git worktree prune

# Remove worktrees directory
rm -rf /Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees
```

#### Recommended Workflow for Team Development

1. **Week 1**: Set up Phase 1 worktrees (database, auth, authz, seed)
2. **Week 2-3**: Set up Phase 2 worktrees (all vendor workflow)
3. **Week 3-4**: Set up Phase 3 worktrees (admin interface) + Phase 7 (UI)
4. **Week 4-5**: Set up Phase 4 worktrees (cobrador interface)
5. **Week 5**: Set up Phase 5 worktrees (background jobs)
6. **Week 6**: Set up Phase 6 worktrees (mobile API) + Phase 8 (testing)

**Parallel Development Example:**

```bash
# Developer 1: Database + Models
cd worktrees/phase1-database

# Developer 2: Tailwind Config (independent)
cd worktrees/phase7-tailwind

# Developer 3: Shared UI Components (independent)
cd worktrees/phase7-ui-shared
```

#### Troubleshooting

**Error: "fatal: 'feature/phase1-database-schema' is already checked out"**
```bash
# Branch is already checked out in another worktree or main repo
# List worktrees to find where
git worktree list

# Remove old worktree first
git worktree remove ../worktrees/phase1-database
```

**Error: "fatal: invalid reference: feature/phase1-database-schema"**
```bash
# Branch doesn't exist yet - create it first
git checkout -b feature/phase1-database-schema
git checkout main
git worktree add ../worktrees/phase1-database feature/phase1-database-schema
```

**Clean up orphaned worktrees:**
```bash
# If worktree directory was deleted manually
git worktree prune
```

---

