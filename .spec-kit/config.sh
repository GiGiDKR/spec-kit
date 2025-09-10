#!/usr/bin/env bash
# Spec-Kit Configuration - Centralized Path Management
# This file provides consistent path variables for all Spec-Kit scripts and templates
# Source this file in other scripts: source "$(dirname "$0")/../config.sh"

# Get repository root automatically
get_repo_root() {
    # Try git first
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$git_root" ]; then
        echo "$git_root"
        return 0
    fi
    
    # Fallback: find .git directory going up
    local current_dir="$(pwd)"
    while [ "$current_dir" != "/" ] && [ "$current_dir" != "C:\\" ]; do
        if [ -d "$current_dir/.git" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Final fallback: use current directory if it contains expected files
    if [ -f "pyproject.toml" ] && [ -f "README.md" ]; then
        echo "$(pwd)"
        return 0
    fi
    
    return 1
}

# Initialize repository root
REPO_ROOT=$(get_repo_root)
if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: Cannot find repository root. Please run from within the project directory."
    return 1 2>/dev/null || exit 1
fi

# Spec-Kit Core Directories (after migration)
export SPEC_KIT_DIR="$REPO_ROOT/.spec-kit"
export SCRIPTS_DIR="$SPEC_KIT_DIR/scripts"
export TEMPLATES_DIR="$SPEC_KIT_DIR/templates"

# Documentation and Project Directories
export DOCS_DIR="$REPO_ROOT/docs"
export MEMORY_DIR="$DOCS_DIR/memory"
export SPECS_DIR="$REPO_ROOT/specs"

# Legacy paths (for transition period only)
export LEGACY_SCRIPTS_DIR="$REPO_ROOT/scripts"
export LEGACY_TEMPLATES_DIR="$REPO_ROOT/templates"
export LEGACY_MEMORY_DIR="$REPO_ROOT/memory"

# Function to source this configuration easily
source_spec_kit_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_file="$script_dir/../config.sh"
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        return 0
    else
        echo "ERROR: Spec-Kit config not found at $config_file"
        return 1
    fi
}

# Function to get current branch (used by other scripts)
get_current_branch() {
    # Try git first
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        echo "$branch"
        return 0
    fi
    
    # Fallback: read from .git/HEAD
    if [ -f "$REPO_ROOT/.git/HEAD" ]; then
        local head_content=$(cat "$REPO_ROOT/.git/HEAD")
        if [[ "$head_content" =~ ^ref:\ refs/heads/(.+)$ ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    fi
    
    # Final fallback
    echo "main"
}

# Function to get feature directory path
get_feature_dir() {
    local branch="${1:-$(get_current_branch)}"
    echo "$SPECS_DIR/$branch"
}

# Function to check if current structure is migrated
is_migrated() {
    [ -d "$SPEC_KIT_DIR" ] && [ -d "$SCRIPTS_DIR" ] && [ -d "$TEMPLATES_DIR" ]
}

# Function to get the correct paths (legacy or migrated)
get_current_scripts_dir() {
    if is_migrated; then
        echo "$SCRIPTS_DIR"
    else
        echo "$LEGACY_SCRIPTS_DIR"
    fi
}

get_current_templates_dir() {
    if is_migrated; then
        echo "$TEMPLATES_DIR"
    else
        echo "$LEGACY_TEMPLATES_DIR"
    fi
}

get_current_memory_dir() {
    if is_migrated; then
        echo "$MEMORY_DIR"
    else
        echo "$LEGACY_MEMORY_DIR"
    fi
}

# Debug function to display all paths
debug_paths() {
    echo "=== Spec-Kit Configuration ==="
    echo "REPO_ROOT: $REPO_ROOT"
    echo "SPEC_KIT_DIR: $SPEC_KIT_DIR"
    echo "SCRIPTS_DIR: $SCRIPTS_DIR"
    echo "TEMPLATES_DIR: $TEMPLATES_DIR"
    echo "DOCS_DIR: $DOCS_DIR"
    echo "MEMORY_DIR: $MEMORY_DIR"
    echo "SPECS_DIR: $SPECS_DIR"
    echo "Current branch: $(get_current_branch)"
    echo "Feature dir: $(get_feature_dir)"
    echo "Is migrated: $(is_migrated && echo "YES" || echo "NO")"
    echo "=========================="
}

# Export functions for use in other scripts
export -f get_repo_root
export -f get_current_branch
export -f get_feature_dir
export -f is_migrated
export -f get_current_scripts_dir
export -f get_current_templates_dir
export -f get_current_memory_dir
export -f debug_paths

# Optional: Auto-detect and warn about migration status
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # Script is being sourced, not executed directly
    if ! is_migrated; then
        echo "INFO: Using legacy structure. Migration to .spec-kit/ recommended."
    fi
fi
