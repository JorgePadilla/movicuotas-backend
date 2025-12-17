#!/bin/bash

# MOVICUOTAS - Git Worktree Creation Script
# This script helps create worktrees for parallel development

set -e  # Exit on error

MAIN_REPO="/Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend"
WORKTREE_DIR="/Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MOVICUOTAS Worktree Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Ensure we're in the main repo
cd "$MAIN_REPO"

# Function to create worktree
create_worktree() {
    local worktree_name=$1
    local branch_name=$2

    echo -e "${YELLOW}Creating worktree: $worktree_name${NC}"

    # Check if worktree already exists
    if [ -d "$WORKTREE_DIR/$worktree_name" ]; then
        echo -e "${BLUE}Worktree already exists: $WORKTREE_DIR/$worktree_name${NC}"
        echo -e "${BLUE}Skipping...${NC}\n"
        return 0
    fi

    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Branch $branch_name already exists"
    else
        echo "Creating new branch: $branch_name"
        git branch "$branch_name"
    fi

    # Create worktree
    git worktree add "$WORKTREE_DIR/$worktree_name" "$branch_name"

    # Push branch to remote
    git push -u origin "$branch_name" 2>/dev/null || echo "Branch already on remote"

    echo -e "${GREEN}✓ Worktree created: $WORKTREE_DIR/$worktree_name${NC}\n"
}

# Parse command line arguments
PHASE=$1

if [ -z "$PHASE" ]; then
    echo "Usage: ./scripts/create-worktrees.sh [phase]"
    echo ""
    echo "Available phases:"
    echo "  1  - Foundation (database, auth, authz, seed)"
    echo "  2  - Vendor Workflow (8 worktrees)"
    echo "  3  - Admin Interface (6 worktrees)"
    echo "  4  - Cobrador Interface (5 worktrees)"
    echo "  5  - Background Jobs (3 worktrees)"
    echo "  6  - Mobile API (4 worktrees)"
    echo "  7  - UI Components (5 worktrees)"
    echo "  8  - Testing (4 worktrees)"
    echo "  all - Create all worktrees"
    exit 1
fi

# Create worktrees based on phase
case $PHASE in
    1)
        echo "Creating Phase 1 worktrees (Foundation)..."
        create_worktree "phase1-database" "feature/phase1-database-schema"
        create_worktree "phase1-auth" "feature/phase1-authentication"
        create_worktree "phase1-authz" "feature/phase1-authorization"
        create_worktree "phase1-seed" "feature/phase1-seed-data"
        ;;

    2)
        echo "Creating Phase 2 worktrees (Vendor Workflow)..."
        create_worktree "phase2-customer-search" "feature/phase2-vendor-customer-search"
        create_worktree "phase2-credit-app" "feature/phase2-vendor-credit-application"
        create_worktree "phase2-device" "feature/phase2-vendor-device-selection"
        create_worktree "phase2-calculator" "feature/phase2-vendor-payment-calculator"
        create_worktree "phase2-contract" "feature/phase2-vendor-contract-signature"
        create_worktree "phase2-mdm" "feature/phase2-vendor-mdm-configuration"
        create_worktree "phase2-loan" "feature/phase2-vendor-loan-finalization"
        create_worktree "phase2-dashboard" "feature/phase2-vendor-dashboard"
        ;;

    3)
        echo "Creating Phase 3 worktrees (Admin Interface)..."
        create_worktree "phase3-admin-dash" "feature/phase3-admin-dashboard"
        create_worktree "phase3-admin-users" "feature/phase3-admin-users"
        create_worktree "phase3-admin-customers" "feature/phase3-admin-customers"
        create_worktree "phase3-admin-loans" "feature/phase3-admin-loans"
        create_worktree "phase3-admin-payments" "feature/phase3-admin-payments"
        create_worktree "phase3-admin-reports" "feature/phase3-admin-reports"
        ;;

    4)
        echo "Creating Phase 4 worktrees (Cobrador Interface)..."
        create_worktree "phase4-cobrador-dash" "feature/phase4-cobrador-dashboard"
        create_worktree "phase4-cobrador-overdue" "feature/phase4-cobrador-overdue-devices"
        create_worktree "phase4-cobrador-mdm" "feature/phase4-cobrador-mdm-blocking"
        create_worktree "phase4-cobrador-payments" "feature/phase4-cobrador-payment-history"
        create_worktree "phase4-cobrador-reports" "feature/phase4-cobrador-collection-reports"
        ;;

    5)
        echo "Creating Phase 5 worktrees (Background Jobs)..."
        create_worktree "phase5-jobs-notif" "feature/phase5-jobs-notifications"
        create_worktree "phase5-jobs-late" "feature/phase5-jobs-late-payments"
        create_worktree "phase5-jobs-block" "feature/phase5-jobs-auto-block"
        ;;

    6)
        echo "Creating Phase 6 worktrees (Mobile API)..."
        create_worktree "phase6-api-auth" "feature/phase6-api-authentication"
        create_worktree "phase6-api-dash" "feature/phase6-api-dashboard"
        create_worktree "phase6-api-payments" "feature/phase6-api-payments"
        create_worktree "phase6-api-notif" "feature/phase6-api-notifications"
        ;;

    7)
        echo "Creating Phase 7 worktrees (UI Components)..."
        create_worktree "phase7-ui-shared" "feature/phase7-components-shared"
        create_worktree "phase7-ui-admin" "feature/phase7-components-admin"
        create_worktree "phase7-ui-vendor" "feature/phase7-components-vendor"
        create_worktree "phase7-ui-cobrador" "feature/phase7-components-cobrador"
        create_worktree "phase7-tailwind" "feature/phase7-tailwind-config"
        ;;

    8)
        echo "Creating Phase 8 worktrees (Testing)..."
        create_worktree "phase8-tests-models" "feature/phase8-tests-models"
        create_worktree "phase8-tests-services" "feature/phase8-tests-services"
        create_worktree "phase8-tests-controllers" "feature/phase8-tests-controllers"
        create_worktree "phase8-tests-system" "feature/phase8-tests-system"
        ;;

    all)
        echo "Creating ALL worktrees..."
        $0 1
        $0 2
        $0 3
        $0 4
        $0 5
        $0 6
        $0 7
        $0 8
        ;;

    *)
        echo "Invalid phase: $PHASE"
        exit 1
        ;;
esac

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Worktree setup complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

# List all worktrees
echo -e "${BLUE}Current worktrees:${NC}"
git worktree list

echo -e "\n${YELLOW}To start working:${NC}"
echo "  cd $WORKTREE_DIR/[worktree-name]"
echo "  claude"
