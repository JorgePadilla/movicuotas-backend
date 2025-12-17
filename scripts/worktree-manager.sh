#!/bin/bash

# MOVICUOTAS - Worktree Management Script
# Helpers for working with git worktrees

set -e

MAIN_REPO="/Users/jorgepadilla/Documents/TAPHN/movicuotas/movicuotas-backend"
WORKTREE_DIR="/Users/jorgepadilla/Documents/TAPHN/movicuotas/worktrees"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd "$MAIN_REPO"

# Function to list all worktrees
list_worktrees() {
    echo -e "${BLUE}Current worktrees:${NC}\n"
    git worktree list
}

# Function to open worktree in new terminal with Claude Code
open_claude() {
    local worktree_name=$1

    if [ -z "$worktree_name" ]; then
        echo "Available worktrees:"
        ls "$WORKTREE_DIR"
        echo ""
        echo "Usage: $0 open [worktree-name]"
        exit 1
    fi

    local worktree_path="$WORKTREE_DIR/$worktree_name"

    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}Error: Worktree not found: $worktree_path${NC}"
        exit 1
    fi

    echo -e "${GREEN}Opening Claude Code in: $worktree_path${NC}"

    # Open new terminal and run claude
    osascript <<EOF
tell application "Terminal"
    do script "cd '$worktree_path' && echo 'Working on: $worktree_name' && claude"
    activate
end tell
EOF
}

# Function to sync worktree with main
sync_with_main() {
    local worktree_name=$1

    if [ -z "$worktree_name" ]; then
        echo "Usage: $0 sync [worktree-name]"
        exit 1
    fi

    local worktree_path="$WORKTREE_DIR/$worktree_name"

    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}Error: Worktree not found: $worktree_path${NC}"
        exit 1
    fi

    cd "$worktree_path"

    echo -e "${YELLOW}Syncing $worktree_name with main...${NC}"

    # Fetch latest main
    git fetch origin main

    # Merge main into current branch
    git merge origin/main

    echo -e "${GREEN}✓ Sync complete${NC}"
}

# Function to remove worktree after merge
cleanup_worktree() {
    local worktree_name=$1

    if [ -z "$worktree_name" ]; then
        echo "Usage: $0 cleanup [worktree-name]"
        exit 1
    fi

    local worktree_path="$WORKTREE_DIR/$worktree_name"

    if [ ! -d "$worktree_path" ]; then
        echo -e "${RED}Error: Worktree not found: $worktree_path${NC}"
        exit 1
    fi

    # Get branch name
    cd "$worktree_path"
    local branch_name=$(git branch --show-current)

    cd "$MAIN_REPO"

    echo -e "${YELLOW}Removing worktree: $worktree_name${NC}"
    echo -e "${YELLOW}Branch: $branch_name${NC}"

    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 1
    fi

    # Remove worktree
    git worktree remove "$worktree_path"

    # Ask to delete branch
    read -p "Delete branch $branch_name? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -D "$branch_name"
        git push origin --delete "$branch_name" 2>/dev/null || echo "Branch not on remote"
        echo -e "${GREEN}✓ Branch deleted${NC}"
    fi

    echo -e "${GREEN}✓ Worktree removed${NC}"
}

# Function to show worktree status
status() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}MOVICUOTAS Worktree Status${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    # Count worktrees
    local total=$(git worktree list | wc -l)
    local active=$((total - 1))  # Exclude main repo

    echo -e "${YELLOW}Total worktrees: $active${NC}\n"

    # List with status
    for dir in "$WORKTREE_DIR"/*; do
        if [ -d "$dir" ]; then
            local name=$(basename "$dir")
            cd "$dir"
            local branch=$(git branch --show-current)
            local commits_ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")

            echo -e "${GREEN}$name${NC}"
            echo "  Branch: $branch"
            echo "  Commits ahead of main: $commits_ahead"
            echo ""
        fi
    done

    cd "$MAIN_REPO"
}

# Main command dispatcher
COMMAND=$1
shift || true

case $COMMAND in
    list|ls)
        list_worktrees
        ;;

    open)
        open_claude "$@"
        ;;

    sync)
        sync_with_main "$@"
        ;;

    cleanup|remove)
        cleanup_worktree "$@"
        ;;

    status|st)
        status
        ;;

    *)
        echo "MOVICUOTAS Worktree Manager"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  list              - List all worktrees"
        echo "  open [name]       - Open worktree in new terminal with Claude Code"
        echo "  sync [name]       - Sync worktree with main branch"
        echo "  cleanup [name]    - Remove worktree and optionally delete branch"
        echo "  status            - Show status of all worktrees"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 open phase1-database"
        echo "  $0 sync phase2-customer-search"
        echo "  $0 cleanup phase1-database"
        exit 1
        ;;
esac
