#!/bin/bash
# GuDaStudio Subagents Installer
# https://github.com/GuDaStudio/subagents

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Available subagents
AVAILABLE_AGENTS=("code-implementer" "code-reviewer" "plan-completion-checker" "project-planner")

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo -e "${BLUE}GuDaStudio Subagents Installer${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --user              Install to user-level (~/.claude/agents/)"
    echo "  -p, --project           Install to project-level (./.claude/agents/)"
    echo "  -t, --target <path>     Install to custom target path"
    echo "  -a, --all               Install all available subagents"
    echo "  -s, --agent <name>      Install specific subagent (can be used multiple times)"
    echo "  -l, --list              List available subagents"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --user --all                    # Install all subagents to user-level"
    echo "  $0 --project --all                 # Install all subagents to current project"
    echo "  $0 --user -s project-planner"
    echo "  $0 --target /custom/path --all"
    echo ""
    echo "Available subagents:"
    for agent in "${AVAILABLE_AGENTS[@]}"; do
        echo "  - $agent"
    done
}

list_agents() {
    echo -e "${BLUE}Available Subagents:${NC}"
    echo ""
    for agent in "${AVAILABLE_AGENTS[@]}"; do
        if [ -f "$SCRIPT_DIR/agents/$agent.md" ]; then
            echo -e "  ${GREEN}✓${NC} $agent"
        else
            echo -e "  ${RED}✗${NC} $agent (not found in source)"
        fi
    done
}

install_agent() {
    local agent=$1
    local target_dir=$2
    local source_file="$SCRIPT_DIR/agents/$agent.md"
    local dest_file="$target_dir/$agent.md"

    if [ ! -f "$source_file" ]; then
        echo -e "${RED}Error: Subagent '$agent' not found in source directory${NC}"
        return 1
    fi

    echo -e "${BLUE}Installing${NC} $agent -> $dest_file"

    # Create target directory
    mkdir -p "$target_dir"

    # Remove existing installation
    if [ -f "$dest_file" ]; then
        echo -e "${YELLOW}  Removing existing installation...${NC}"
        rm -f "$dest_file"
    fi

    # Copy agent file
    cp "$source_file" "$dest_file"

    echo -e "${GREEN}  ✓ Installed${NC}"
}

# Parse arguments
TARGET_PATH=""
INSTALL_ALL=false
SELECTED_AGENTS=()
SCOPE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            SCOPE="user"
            TARGET_PATH="$HOME/.claude/agents"
            shift
            ;;
        -p|--project)
            SCOPE="project"
            TARGET_PATH="./.claude/agents"
            shift
            ;;
        -t|--target)
            TARGET_PATH="$2"
            shift 2
            ;;
        -a|--all)
            INSTALL_ALL=true
            shift
            ;;
        -s|--agent)
            SELECTED_AGENTS+=("$2")
            shift 2
            ;;
        -l|--list)
            list_agents
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [ -z "$TARGET_PATH" ]; then
    echo -e "${RED}Error: Please specify installation target (-u, -p, or -t)${NC}"
    echo ""
    usage
    exit 1
fi

if [ "$INSTALL_ALL" = false ] && [ ${#SELECTED_AGENTS[@]} -eq 0 ]; then
    echo -e "${RED}Error: Please specify subagents to install (-a or -s)${NC}"
    echo ""
    usage
    exit 1
fi

# Determine agents to install
if [ "$INSTALL_ALL" = true ]; then
    AGENTS_TO_INSTALL=("${AVAILABLE_AGENTS[@]}")
else
    AGENTS_TO_INSTALL=("${SELECTED_AGENTS[@]}")
fi

# Validate selected agents
for agent in "${AGENTS_TO_INSTALL[@]}"; do
    valid=false
    for available in "${AVAILABLE_AGENTS[@]}"; do
        if [ "$agent" = "$available" ]; then
            valid=true
            break
        fi
    done
    if [ "$valid" = false ]; then
        echo -e "${RED}Error: Unknown subagent '$agent'${NC}"
        echo "Available subagents: ${AVAILABLE_AGENTS[*]}"
        exit 1
    fi
done

# Install
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}GuDaStudio Subagents Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Target: ${GREEN}$TARGET_PATH${NC}"
echo -e "Subagents: ${GREEN}${AGENTS_TO_INSTALL[*]}${NC}"
echo ""

for agent in "${AGENTS_TO_INSTALL[@]}"; do
    install_agent "$agent" "$TARGET_PATH"
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
