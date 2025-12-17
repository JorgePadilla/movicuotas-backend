# MOVICUOTAS Development Scripts

Helper scripts for managing git worktrees and parallel development.

## Quick Start

### 1. Create Worktrees for a Phase

```bash
# Create Phase 1 worktrees (Foundation)
./scripts/create-worktrees.sh 1

# Create Phase 2 worktrees (Vendor Workflow)
./scripts/create-worktrees.sh 2

# Create all worktrees at once
./scripts/create-worktrees.sh all
```

### 2. List All Worktrees

```bash
./scripts/worktree-manager.sh list
```

### 3. Open Worktree in New Terminal with Claude Code

```bash
./scripts/worktree-manager.sh open phase1-database
```

### 4. Check Worktree Status

```bash
./scripts/worktree-manager.sh status
```

### 5. Sync Worktree with Main

```bash
./scripts/worktree-manager.sh sync phase2-customer-search
```

### 6. Cleanup Completed Worktree

```bash
./scripts/worktree-manager.sh cleanup phase1-database
```

---

## Available Scripts

### `create-worktrees.sh` - Create New Worktrees

Creates worktrees for each development phase.

**Usage:**
```bash
./scripts/create-worktrees.sh [phase]
```

**Phases:**
- `1` - Foundation (database, auth, authz, seed) - **4 worktrees**
- `2` - Vendor Workflow - **8 worktrees**
- `3` - Admin Interface - **6 worktrees**
- `4` - Cobrador Interface - **5 worktrees**
- `5` - Background Jobs - **3 worktrees**
- `6` - Mobile API - **4 worktrees**
- `7` - UI Components - **5 worktrees**
- `8` - Testing - **4 worktrees**
- `all` - Create all 39 worktrees

**Examples:**
```bash
# Create Phase 1 worktrees
./scripts/create-worktrees.sh 1

# Create Phase 2 worktrees
./scripts/create-worktrees.sh 2

# Create all worktrees
./scripts/create-worktrees.sh all
```

---

### `worktree-manager.sh` - Manage Existing Worktrees

Manage and interact with existing worktrees.

**Commands:**

#### List Worktrees
```bash
./scripts/worktree-manager.sh list
# or
./scripts/worktree-manager.sh ls
```

Shows all active worktrees with their paths and branches.

#### Open in Claude Code
```bash
./scripts/worktree-manager.sh open phase1-database
```

Opens a new terminal window and starts Claude Code in the specified worktree.

**Available worktrees:**
- `phase1-database`
- `phase1-auth`
- `phase1-authz`
- `phase1-seed`
- `phase2-customer-search`
- `phase2-credit-app`
- `phase2-device`
- `phase2-calculator`
- `phase2-contract`
- `phase2-mdm`
- `phase2-loan`
- `phase2-dashboard`
- ... (and more)

#### Check Status
```bash
./scripts/worktree-manager.sh status
# or
./scripts/worktree-manager.sh st
```

Shows detailed status of all worktrees including:
- Branch name
- Commits ahead of main
- Total worktree count

#### Sync with Main
```bash
./scripts/worktree-manager.sh sync phase2-customer-search
```

Fetches latest main and merges it into the worktree's branch. Use this to keep your feature branch up to date.

#### Cleanup Worktree
```bash
./scripts/worktree-manager.sh cleanup phase1-database
# or
./scripts/worktree-manager.sh remove phase1-database
```

Removes the worktree after feature is merged. Optionally deletes the branch (local and remote).

---

## Typical Workflow

### Start Working on a New Feature

```bash
# 1. Create worktree for your phase
./scripts/create-worktrees.sh 2  # Phase 2: Vendor Workflow

# 2. Open Claude Code in the worktree
./scripts/worktree-manager.sh open phase2-customer-search

# 3. In the new terminal, start developing
# Claude Code is already running in the worktree directory
```

### Work on Multiple Features in Parallel

```bash
# Open Terminal Tab 1
./scripts/worktree-manager.sh open phase1-database

# Open Terminal Tab 2 (⌘+T)
./scripts/worktree-manager.sh open phase1-auth

# Open Terminal Tab 3 (⌘+T)
./scripts/worktree-manager.sh open phase7-tailwind
```

Now you have 3 Claude Code instances running in parallel!

### Keep Your Branch Updated

```bash
# Periodically sync with main
./scripts/worktree-manager.sh sync phase2-customer-search
```

### After Feature is Complete

```bash
# 1. From main repo, merge the feature
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend
git checkout main
git merge --no-ff feature/phase2-customer-search
git push origin main

# 2. Clean up the worktree
./scripts/worktree-manager.sh cleanup phase2-customer-search
# This will prompt to delete the branch as well
```

---

## Manual Commands (Alternative)

If you prefer manual git commands:

### Create Worktree Manually
```bash
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend
git worktree add ../worktrees/phase2-new feature/phase2-new
```

### List Worktrees Manually
```bash
git worktree list
```

### Remove Worktree Manually
```bash
git worktree remove ../worktrees/phase2-new
git branch -d feature/phase2-new
```

---

## Directory Structure

```
/Users/jorgepadilla/Documents/TAPHN/movicuotas/
├── movicuotas-backend/          # Main repository (main branch)
│   ├── scripts/
│   │   ├── create-worktrees.sh
│   │   ├── worktree-manager.sh
│   │   └── README.md
│   └── ...
└── worktrees/                    # All worktrees
    ├── phase1-database/          # feature/phase1-database-schema
    ├── phase1-auth/              # feature/phase1-authentication
    ├── phase1-authz/             # feature/phase1-authorization
    ├── phase1-seed/              # feature/phase1-seed-data
    ├── phase2-customer-search/   # feature/phase2-vendor-customer-search
    └── ...
```

---

## Tips

1. **Always sync before merging**: Run `sync` to update your branch with latest main before merging
2. **One feature at a time**: Focus on completing one feature before starting another
3. **Clean up regularly**: Remove merged worktrees to keep directory clean
4. **Check status often**: Use `status` command to see what you're working on
5. **Use descriptive commits**: Each worktree is isolated, so commit frequently

---

## Troubleshooting

### Worktree already exists
```bash
# List worktrees to find it
./scripts/worktree-manager.sh list

# Remove the old one
./scripts/worktree-manager.sh cleanup [name]

# Recreate it
./scripts/create-worktrees.sh [phase]
```

### Branch already checked out
```bash
# A branch can only be checked out once
# Either remove the existing worktree or use a different branch name
git worktree list  # Find where it's checked out
```

### Lost worktree directory
```bash
# If worktree directory was deleted manually
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend
git worktree prune
```

---

## See Also

- [CLAUDE.md](../CLAUDE.md) - Full project documentation
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
