#!/bin/bash
# Helper script for syncing Terraform state with GitHub Actions artifacts

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARTIFACT_NAME="terraform-state"
STATE_FILE="terraform.tfstate"
BACKUP_DIR=".state-backups"

# Create backup directory
mkdir -p "$BACKUP_DIR"

show_usage() {
    cat <<EOF
${BLUE}Terraform State Management Helper${NC}

Usage: $0 <command> [options]

${GREEN}Commands:${NC}
  pull [<run-id>]      Download state artifact from GitHub Actions
                       If no run-id specified, uses latest completed run
  
  backup               Create local backup of terraform.tfstate
  
  status               Show current state info and last 5 workflow runs
  
  help                 Show this help message

${YELLOW}Examples:${NC}
  $0 pull              # Download from latest run
  $0 pull r1234567890  # Download from specific run
  $0 backup            # Backup current state
  $0 status            # Show state status

${YELLOW}Note:${NC} Requires 'gh' CLI to be installed and authenticated
EOF
}

check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: 'gh' CLI not found. Install it from https://cli.github.com/${NC}"
        exit 1
    fi
}

backup_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo -e "${YELLOW}No current state file to backup${NC}"
        return
    fi
    
    BACKUP_FILE="$BACKUP_DIR/terraform.tfstate.$(date +%Y%m%d_%H%M%S).backup"
    cp "$STATE_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✓ State backed up to: $BACKUP_FILE${NC}"
}

pull_state() {
    local run_id=$1
    
    echo -e "${BLUE}Pulling Terraform state from GitHub Actions...${NC}"
    
    if [ -z "$run_id" ]; then
        echo -e "${YELLOW}Fetching latest completed workflow run...${NC}"
        local latest_run=$(gh run list \
            --limit 1 \
            --status completed \
            --workflow terraform-checks.yml \
            --json "databaseId" \
            --jq ".[0].databaseId")
        
        if [ -z "$latest_run" ]; then
            echo -e "${RED}Error: No completed workflow runs found${NC}"
            echo -e "${YELLOW}Tip: Run 'gh workflow run terraform-checks.yml' to trigger one${NC}"
            exit 1
        fi
        run_id=$latest_run
    fi
    
    echo -e "${BLUE}Downloading artifact from run: $run_id${NC}"
    
    # Backup current state before pulling
    if [ -f "$STATE_FILE" ]; then
        backup_state
    fi
    
    # Download the artifact
    gh run download "$run_id" \
        -n "$ARTIFACT_NAME" \
        -D /tmp/gh-tf-artifact 2>/dev/null || {
            echo -e "${RED}Error: Failed to download artifact${NC}"
            echo -e "${YELLOW}Make sure the workflow has completed and the artifact exists${NC}"
            exit 1
        }
    
    if [ -f "/tmp/gh-tf-artifact/$STATE_FILE" ]; then
        cp "/tmp/gh-tf-artifact/$STATE_FILE" "$STATE_FILE"
        rm -rf /tmp/gh-tf-artifact
        echo -e "${GREEN}✓ State file updated successfully${NC}"
        echo -e "${BLUE}Current state summary:${NC}"
        terraform state list 2>/dev/null || echo "  (Initialize Terraform to view state)"
    else
        echo -e "${RED}Error: State file not found in artifact${NC}"
        exit 1
    fi
}

show_status() {
    echo -e "${BLUE}=== Terraform State Status ===${NC}"
    
    if [ -f "$STATE_FILE" ]; then
        echo -e "${GREEN}✓ Local state file exists${NC}"
        local state_age=$(stat -f%Sa "$STATE_FILE" 2>/dev/null || stat --format=%y "$STATE_FILE" 2>/dev/null | cut -d' ' -f1-2)
        echo -e "  Modified: $state_age"
        local resource_count=$(grep -c '"type":' "$STATE_FILE" || echo "Unable to parse")
        echo -e "  Resources: ~$resource_count"
    else
        echo -e "${YELLOW}⚠ No local state file found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}=== Recent Workflow Runs ===${NC}"
    
    gh run list \
        --limit 5 \
        --workflow terraform-checks.yml \
        --json "name,status,conclusion,updatedAt" \
        --template '{{range .}}{{printf "%-10s %-8s %-12s %s\n" .status .conclusion .updatedAt .name}}{{end}}' || {
            echo -e "${RED}Error: Could not fetch run history${NC}"
        }
}

# Main script logic
check_gh_cli

if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    pull)
        pull_state "$2"
        ;;
    backup)
        backup_state
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac
