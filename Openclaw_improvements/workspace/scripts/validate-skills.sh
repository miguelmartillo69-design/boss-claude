#!/bin/bash
# validate-skills.sh - Validate OpenClaw skill configurations
# Usage: ./validate-skills.sh [skill-name]

set -e

SKILLS_DIR="${HOME}/.openclaw/workspace/skills"
BUILTIN_SKILLS="${HOME}/.npm-global/lib/node_modules/openclaw/skills"

echo "=== OpenClaw Skills Validator ==="
echo ""

validate_skill() {
    local skill_path="$1"
    local skill_name=$(basename "$skill_path")
    local errors=0

    echo "Checking: $skill_name"

    # Check for SKILL.md
    if [ ! -f "$skill_path/SKILL.md" ]; then
        echo "  FAIL: Missing SKILL.md"
        ((errors++))
    else
        # Check frontmatter
        if ! head -1 "$skill_path/SKILL.md" | grep -q "^---"; then
            echo "  WARN: Missing YAML frontmatter"
        fi

        # Check for name field
        if ! grep -q "^name:" "$skill_path/SKILL.md"; then
            echo "  WARN: Missing 'name' in frontmatter"
        fi

        # Check for description
        if ! grep -q "^description:" "$skill_path/SKILL.md"; then
            echo "  WARN: Missing 'description' in frontmatter"
        fi
    fi

    # Check for package.json if node skill
    if [ -f "$skill_path/package.json" ]; then
        if ! jq empty "$skill_path/package.json" 2>/dev/null; then
            echo "  FAIL: Invalid package.json"
            ((errors++))
        fi

        # Check if dependencies are installed
        if [ -d "$skill_path/node_modules" ]; then
            echo "  OK: Dependencies installed"
        else
            echo "  WARN: node_modules missing - run 'npm install'"
        fi
    fi

    # Check for required binaries
    if grep -q "requires:" "$skill_path/SKILL.md" 2>/dev/null; then
        echo "  INFO: Has binary requirements"
    fi

    if [ $errors -eq 0 ]; then
        echo "  PASS"
    fi

    return $errors
}

# Validate specific skill or all
if [ -n "$1" ]; then
    if [ -d "$SKILLS_DIR/$1" ]; then
        validate_skill "$SKILLS_DIR/$1"
    elif [ -d "$BUILTIN_SKILLS/$1" ]; then
        validate_skill "$BUILTIN_SKILLS/$1"
    else
        echo "Skill not found: $1"
        exit 1
    fi
else
    echo "Custom Skills ($SKILLS_DIR):"
    echo "---"
    if [ -d "$SKILLS_DIR" ]; then
        for skill in "$SKILLS_DIR"/*/; do
            [ -d "$skill" ] && validate_skill "$skill"
        done
    else
        echo "  No custom skills directory"
    fi

    echo ""
    echo "Built-in Skills (sample):"
    echo "---"
    ls "$BUILTIN_SKILLS" 2>/dev/null | head -10 | while read skill; do
        echo "  $skill"
    done
    echo "  ... ($(ls "$BUILTIN_SKILLS" 2>/dev/null | wc -l) total)"
fi

echo ""
echo "Validation complete."
