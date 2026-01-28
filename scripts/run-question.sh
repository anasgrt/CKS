#!/bin/bash

# CKS Simulator - Inspired by killer.sh
# Run practice questions for CKS exam preparation

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    CKS Exam Simulator 2026                       ║"
    echo "║            Certified Kubernetes Security Specialist              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: $0 <question> [command]"
    echo ""
    echo "Commands:"
    echo "  list              - List all available questions"
    echo "  exam              - Start a full exam simulation (2 hours)"
    echo ""
    echo "Question Commands (default: setup):"
    echo "  setup             - Setup environment for question"
    echo "  verify            - Verify your solution for question"
    echo "  solution          - Show solution for question"
    echo "  reset             - Reset environment for question"
    echo "  question          - Display question text only"
    echo ""
    echo "Examples:"
    echo "  $0 1                        - Setup question 1 (default)"
    echo "  $0 Question-01-Falco verify - Verify question 1 solution"
    echo "  $0 6 solution               - Show solution for question 6"
    echo "  $0 list                     - List all questions"
    echo "  $0 exam                     - Start full 2-hour exam"
}

get_question_dir() {
    local input=$1

    # If it's a number, find matching question
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        local padded=$(printf "%02d" $input)
        for dir in $BASE_DIR/Question-${padded}-*; do
            if [ -d "$dir" ]; then
                echo "$dir"
                return
            fi
        done
    fi

    # If it's a full directory name
    if [ -d "$BASE_DIR/$input" ]; then
        echo "$BASE_DIR/$input"
        return
    fi

    # Try partial match
    for dir in $BASE_DIR/Question-*${input}*; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return
        fi
    done
}

list_questions() {
    print_header
    echo -e "${YELLOW}Available Questions:${NC}"
    echo ""

    for dir in $BASE_DIR/Question-*; do
        if [ -d "$dir" ]; then
            local name=$(basename "$dir")
            local num=$(echo "$name" | grep -oE '[0-9]+' | head -1)
            local title=$(echo "$name" | sed 's/Question-[0-9]*-//')

            if [ -f "$dir/question.txt" ]; then
                local weight=$(grep -i "weight\|domain" "$dir/question.txt" | head -1 || echo "")
                local domain=$(grep -i "domain" "$dir/question.txt" | head -1 | sed 's/Domain: //' || echo "")
                echo -e "  ${GREEN}Q$num${NC} - $title"
                echo -e "       ${BLUE}${domain:-N/A}${NC}"
            else
                echo -e "  ${GREEN}Q$num${NC} - $title"
            fi
        fi
    done
    echo ""
}

run_setup() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/setup.sh" ]; then
        echo -e "${RED}Error: setup.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Setting up $question_name...${NC}"
    echo ""

    bash "$dir/setup.sh"

    echo ""
    echo -e "${GREEN}✓ Setup complete!${NC}"
    echo ""
    echo -e "${CYAN}Question:${NC}"
    echo "─────────────────────────────────────────────────────────────────────"
    cat "$dir/question.txt"
    echo "─────────────────────────────────────────────────────────────────────"
    echo ""
    echo -e "Run ${YELLOW}./scripts/run-question.sh $question_id verify${NC} when you're done."
}

run_verify() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/verify.sh" ]; then
        echo -e "${RED}Error: verify.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Verifying $question_name...${NC}"
    echo ""

    if bash "$dir/verify.sh"; then
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}                    ✓ $question_name: PASSED!                      ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
    else
        echo ""
        echo -e "${RED}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}                    ✗ $question_name: FAILED                       ${NC}"
        echo -e "${RED}══════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "Run ${YELLOW}./scripts/run-question.sh $question_id solution${NC} to see the solution."
    fi
}

run_solution() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/solution.sh" ]; then
        echo -e "${RED}Error: solution.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Solution for $question_name:${NC}"
    echo ""

    bash "$dir/solution.sh"
}

run_reset() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/reset.sh" ]; then
        echo -e "${RED}Error: reset.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Resetting $question_name...${NC}"
    echo ""

    bash "$dir/reset.sh"

    echo ""
    echo -e "${GREEN}✓ Reset complete!${NC}"
}

show_question() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/question.txt" ]; then
        echo -e "${RED}Error: question.txt not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${CYAN}$question_name:${NC}"
    echo "─────────────────────────────────────────────────────────────────────"
    cat "$dir/question.txt"
    echo "─────────────────────────────────────────────────────────────────────"
}

run_exam() {
    print_header
    echo -e "${RED}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                    FULL EXAM SIMULATION                            ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}This will set up ALL questions and start a 2-hour timer.${NC}"
    echo ""
    echo "Rules:"
    echo "  - 14 questions total"
    echo "  - 2 hours to complete"
    echo "  - Use kubectl documentation: https://kubernetes.io/docs/"
    echo "  - No external resources"
    echo ""
    read -p "Press ENTER to start or CTRL+C to cancel..."

    echo ""
    echo -e "${GREEN}Setting up all questions...${NC}"

    for dir in $BASE_DIR/Question-*; do
        if [ -d "$dir" ] && [ -f "$dir/setup.sh" ]; then
            local name=$(basename "$dir")
            echo -n "  Setting up $name... "
            bash "$dir/setup.sh" > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}All questions ready!${NC}"
    echo ""
    echo -e "${CYAN}Your 2-hour exam starts NOW!${NC}"
    echo -e "${YELLOW}Good luck!${NC}"
    echo ""

    # Start timer in background
    (sleep 7200 && echo -e "\n${RED}TIME'S UP! Exam ended.${NC}") &

    list_questions
}

# Main
case "${1:-}" in
    list)
        list_questions
        ;;
    exam)
        run_exam
        ;;
    "")
        print_header
        print_usage
        ;;
    *)
        # First argument is the question identifier
        QUESTION_ID="$1"
        COMMAND="${2:-setup}"  # Default to setup if no command specified

        case "$COMMAND" in
            setup)
                run_setup "$QUESTION_ID"
                ;;
            verify)
                run_verify "$QUESTION_ID"
                ;;
            solution)
                run_solution "$QUESTION_ID"
                ;;
            reset)
                run_reset "$QUESTION_ID"
                ;;
            question)
                show_question "$QUESTION_ID"
                ;;
            *)
                echo -e "${RED}Error: Unknown command '$COMMAND'${NC}"
                echo -e "Valid commands: setup, verify, solution, reset, question"
                exit 1
                ;;
        esac
        ;;
esac
