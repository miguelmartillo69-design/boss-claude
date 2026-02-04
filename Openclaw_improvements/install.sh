#!/bin/bash
# OpenClaw Improvements Installer
# Applies improvements from analysis reports to a fresh OpenClaw installation
#
# Usage: ./install.sh [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="${HOME}/.openclaw"
WORKSPACE="${OPENCLAW_DIR}/workspace"
DRY_RUN=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    log_info "Dry run mode - no changes will be made"
fi

# Check prerequisites
if [[ ! -d "$OPENCLAW_DIR" ]]; then
    log_error "OpenClaw not found at $OPENCLAW_DIR"
    log_error "Please install OpenClaw first: npm install -g openclaw"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed"
    log_error "Install with: sudo apt install jq"
    exit 1
fi

log_info "OpenClaw found at $OPENCLAW_DIR"
log_info "Starting installation..."

# Backup config
BACKUP_FILE="${OPENCLAW_DIR}/openclaw.json.backup.$(date +%Y%m%d%H%M%S)"
if [[ "$DRY_RUN" == false ]]; then
    cp "${OPENCLAW_DIR}/openclaw.json" "$BACKUP_FILE"
    log_info "Config backed up to $BACKUP_FILE"
else
    log_info "[DRY RUN] Would backup config to $BACKUP_FILE"
fi

# Apply config patches
log_info "Applying configuration patches..."
if [[ "$DRY_RUN" == false ]]; then
    jq '.agents.defaults.subagents.maxConcurrent = 4 |
        .diagnostics.enabled = true |
        .diagnostics.cacheTrace.enabled = true' \
        "${OPENCLAW_DIR}/openclaw.json" > /tmp/openclaw.json.tmp && \
        mv /tmp/openclaw.json.tmp "${OPENCLAW_DIR}/openclaw.json"
    log_info "Config patches applied (maxConcurrent=4, diagnostics=true)"
else
    log_info "[DRY RUN] Would set subagents.maxConcurrent=4, diagnostics.enabled=true"
fi

# Create directories
log_info "Creating directories..."
DIRS=(
    "${WORKSPACE}/skills/config-validate"
    "${WORKSPACE}/skills/cost-report"
    "${WORKSPACE}/scripts"
    "${WORKSPACE}/agents/researcher"
    "${WORKSPACE}/agents/coder"
    "${WORKSPACE}/agents/reviewer"
    "${WORKSPACE}/.claude/commands"
)

for dir in "${DIRS[@]}"; do
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dir"
    else
        log_info "[DRY RUN] Would create $dir"
    fi
done

# Copy files
log_info "Installing files..."

copy_file() {
    local src="$1"
    local dest="$2"
    if [[ "$DRY_RUN" == false ]]; then
        cp "$src" "$dest"
        log_info "Installed: $dest"
    else
        log_info "[DRY RUN] Would copy $src -> $dest"
    fi
}

# Skills
copy_file "${SCRIPT_DIR}/workspace/skills/config-validate/SKILL.md" "${WORKSPACE}/skills/config-validate/SKILL.md"
copy_file "${SCRIPT_DIR}/workspace/skills/cost-report/SKILL.md" "${WORKSPACE}/skills/cost-report/SKILL.md"

# Scripts
copy_file "${SCRIPT_DIR}/workspace/scripts/validate-skills.sh" "${WORKSPACE}/scripts/validate-skills.sh"
if [[ "$DRY_RUN" == false ]]; then
    chmod +x "${WORKSPACE}/scripts/validate-skills.sh"
fi

# Agent roles
copy_file "${SCRIPT_DIR}/workspace/agents/researcher/IDENTITY.md" "${WORKSPACE}/agents/researcher/IDENTITY.md"
copy_file "${SCRIPT_DIR}/workspace/agents/coder/IDENTITY.md" "${WORKSPACE}/agents/coder/IDENTITY.md"
copy_file "${SCRIPT_DIR}/workspace/agents/reviewer/IDENTITY.md" "${WORKSPACE}/agents/reviewer/IDENTITY.md"

# Reference docs
copy_file "${SCRIPT_DIR}/workspace/CAPABILITIES.md" "${WORKSPACE}/CAPABILITIES.md"

# Commands
copy_file "${SCRIPT_DIR}/workspace/.claude/commands/openclaw-status.md" "${WORKSPACE}/.claude/commands/openclaw-status.md"

# Onboard Forge via MEMORY.md
log_info "Adding onboarding note to Forge's memory..."
MEMORY_FILE="${WORKSPACE}/MEMORY.md"
ONBOARDING_MARKER="## 🆕 Workspace Improvements"

if [[ -f "$MEMORY_FILE" ]]; then
    # Check if already onboarded
    if grep -q "$ONBOARDING_MARKER" "$MEMORY_FILE" 2>/dev/null; then
        log_info "Forge already onboarded (marker found in MEMORY.md)"
    else
        if [[ "$DRY_RUN" == false ]]; then
            cat "${SCRIPT_DIR}/forge-onboarding.md" >> "$MEMORY_FILE"
            log_info "Onboarding note appended to MEMORY.md"
        else
            log_info "[DRY RUN] Would append onboarding note to MEMORY.md"
        fi
    fi
else
    log_warn "MEMORY.md not found - Forge will discover capabilities via CAPABILITIES.md"
fi

# Remind about manual patches
echo ""
log_warn "Manual patches required:"
log_warn "  1. Apply agents-patch.md to ${WORKSPACE}/AGENTS.md"
log_warn "  2. Apply tools-patch.md to ${WORKSPACE}/TOOLS.md"
echo ""

# Restart gateway
if [[ "$DRY_RUN" == false ]]; then
    log_info "Restarting gateway..."
    if systemctl --user restart openclaw-gateway 2>/dev/null; then
        log_info "Gateway restarted successfully"
    else
        log_warn "Could not restart gateway (may not be running as systemd service)"
        log_warn "Restart manually: openclaw gateway restart"
    fi
fi

echo ""
log_info "Installation complete!"
echo ""
echo "Installed components:"
echo "  - Config: maxConcurrent=4, diagnostics=true"
echo "  - Skills: config-validate, cost-report"
echo "  - Scripts: validate-skills.sh"
echo "  - Agent roles: researcher, coder, reviewer"
echo "  - Docs: CAPABILITIES.md"
echo "  - Commands: openclaw-status.md"
echo ""
echo "Test with:"
echo "  - Ask Forge: 'validate config'"
echo "  - Ask Forge: 'cost report'"
echo "  - Run: ~/.openclaw/workspace/scripts/validate-skills.sh"
