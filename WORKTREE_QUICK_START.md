# Git Worktree Quick Start Guide

## 🚀 Start Working NOW

### Open Claude Code in a Worktree

```bash
# Choose one:
./scripts/worktree-manager.sh open phase1-database
./scripts/worktree-manager.sh open phase1-auth
./scripts/worktree-manager.sh open phase1-authz
./scripts/worktree-manager.sh open phase1-seed
```

This opens a new Terminal window with Claude Code running!

---

## 📋 Common Commands

```bash
# List all worktrees
./scripts/worktree-manager.sh list

# Check status
./scripts/worktree-manager.sh status

# Create Phase 2 worktrees (Vendor Workflow)
./scripts/create-worktrees.sh 2

# Sync with main
./scripts/worktree-manager.sh sync phase1-database
```

---

## ✅ Phase 1 Tasks (Do These First)

| Worktree | Branch | Task |
|----------|--------|------|
| **phase1-database** | feature/phase1-database-schema | Create all models & migrations |
| **phase1-auth** | feature/phase1-authentication | Rails 8 authentication |
| **phase1-authz** | feature/phase1-authorization | Pundit policies |
| **phase1-seed** | feature/phase1-seed-data | Seed data |

---

## 🔄 Workflow: Complete a Feature

```bash
# 1. Open worktree
./scripts/worktree-manager.sh open phase1-database

# 2. Work on feature (in new terminal)
# ... make changes, commit ...

# 3. From main repo, merge when done
cd /Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend
git checkout main
git merge --no-ff feature/phase1-database-schema
git push origin main

# 4. Cleanup worktree
./scripts/worktree-manager.sh cleanup phase1-database
```

---

## 🎯 Create More Worktrees

```bash
# Phase 2: Vendor Workflow (8 worktrees)
./scripts/create-worktrees.sh 2

# Phase 3: Admin Interface (6 worktrees)
./scripts/create-worktrees.sh 3

# All remaining phases
./scripts/create-worktrees.sh all
```

---

## 📖 Full Documentation

- **Complete Guide**: [scripts/README.md](scripts/README.md)
- **Full Project Docs**: [CLAUDE.md](CLAUDE.md)
- **Git Branching Strategy**: CLAUDE.md (search: "Git Branching Strategy")
- **Worktree Setup**: CLAUDE.md (search: "Git Worktree Setup")

---

## 🆘 Help

```bash
# Script help
./scripts/worktree-manager.sh

# Or read the docs
cat scripts/README.md
```

---

**Happy coding! 🎉**
