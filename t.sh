#!/bin/bash

# Define color variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display the current location
function display_location() {
    echo -e "${YELLOW}Current location:${NC} $(pwd)"
}

# Function to list available branches and repositories
function list_branches_repos() {
    display_location
    echo -e "${YELLOW}Available branches:${NC}"
    git branch -a
    echo -e "${YELLOW}Available repositories:${NC}"
    git remote -v
}

# Function to create a new branch or repository
function create_branch_repo() {
    display_location
    read -p "Do you want to create a new branch or repository? (branch/repo) " create_choice

    if [ "$create_choice" = "branch" ]; then
        read -p "Enter the name of the new branch: " new_branch_name
        git checkout -b "$new_branch_name"
    elif [ "$create_choice" = "repo" ]; then
        read -p "Enter the name of the new repository: " new_repo_name
        git init "$new_repo_name"
    else
        echo "Invalid choice. Exiting..."
        exit 1
    fi

    read -p "Do you want to select the newly created branch/repository? (y/n) " select_choice

    if [ "$select_choice" = "y" ] || [ "$select_choice" = "Y" ]; then
        select_branch_repo
    fi
}

# Function to search for a file in the system
function search_file() {
    display_location
    read -p "Do you want to search for a file? (y/n) " search_choice

    if [ "$search_choice" = "y" ] || [ "$search_choice" = "Y" ]; then
        read -p "Enter the file name: " file_name
        read -p "Do you want to search with sudo? (y/n) " sudo_choice

        if [ "$sudo_choice" = "y" ] || [ "$sudo_choice" = "Y" ] && command -v sudo &>/dev/null; then
            sudo -v
            echo -e "${YELLOW}Searching with sudo...${NC}"
            sudo find / -type f -name "$file_name" 2>/dev/null
        else
            echo -e "${YELLOW}Searching without sudo...${NC}"
            find / -type f -name "$file_name" 2>/dev/null
        fi
    else
        echo "No search requested."
    fi
}

# Function to select an available branch or repository
function select_branch_repo() {
    display_location
    read -p "Do you want to select an available branch or repository? (y/n) " select_choice

    if [ "$select_choice" = "y" ] || [ "$select_choice" = "Y" ]; then
        read -p "Do you want to select a branch or repository? (branch/repo) " select_branch_repo_choice

        if [ "$select_branch_repo_choice" = "branch" ]; then
            read -p "Enter the name of the branch: " branch_repo_name
            git checkout "$branch_repo_name"
        elif [ "$select_branch_repo_choice" = "repo" ]; then
            read -p "Enter the name of the repository: " branch_repo_name
            echo -e "${GREEN}Selected repository: $branch_repo_name${NC}"
        else
            echo "Invalid choice. Exiting..."
            exit 1
        fi
    else
        echo "No selection requested."
    fi
}

# Function to handle adding a file or directory
function handle_add_file_directory() {
    display_location
    git status -s | cat -n
    read -p "Enter the numbers of the files/directories you want to add (separated by spaces): " add_numbers

    IFS=' ' read -ra numbers_arr <<< "$add_numbers"
    for number in "${numbers_arr[@]}"; do
        file_path=$(git status -s | awk -v num="$number" 'NR==num {print $2}')
        if [ -n "$file_path" ]; then
            git add "$file_path"
            echo -e "${GREEN}Added: $file_path${NC}"
        else
            echo "Invalid number: $number. Skipping..."
        fi
    done

    # Check if there are any changes to commit
    if git diff --cached --exit-code &>/dev/null; then
        echo "No changes to commit."
        return 1
    fi

    # The commit message is not needed here as it will be provided later in select_commit function

    # Show git status after adding files
    git status
}

# Function to display all commits with associated file changes and prompt for selection
function select_commit() {
    display_location
    git log --oneline --name-status | cat -n
    read -p "Enter the numbers of the commits you want to include in the new commit (separated by spaces): " commit_numbers

    commit_message=""
    IFS=' ' read -ra numbers_arr <<< "$commit_numbers"
    for number in "${numbers_arr[@]}"; do
        commit_hash=$(git log --oneline --name-status | awk -v num="$number" '{if(NR==num) print $1}')
        if [ -n "$commit_hash" ]; then
            commit_message="$commit_message $commit_hash"
        else
            echo "Invalid commit number: $number. Skipping..."
        fi
    done

    if [ -n "$commit_message" ]; then
        read -p "Enter the commit message: " new_commit_message
        git reset --soft HEAD
        git commit -c "$commit_message" -m "$new_commit_message"
    else
        echo "No valid commits selected. Aborting commit creation."
    fi

    # Show git status after committing changes
    git status
}

# Function to push changes to the remote repository
function push_changes() {
    display_location
    read -p "Enter the name of the remote branch to push to: " remote_branch
    git push -u origin "$remote_branch"

    # Show git status after pushing changes
    git status
}

# Function to configure the remote repository URL
function configure_remote_url() {
    display_location
    read -p "Enter the URL of the remote repository: " remote_url
    git remote add origin "$remote_url"
    echo -e "${GREEN}Remote repository URL configured.${NC}"
}

# Main menu loop
while true; do
    echo "Select an option:"
    echo "1) List available branches and repositories"
    echo "2) Create a new branch or repository"
    echo "3) Search for a file"
    echo "4) Select an available branch or repository"
    echo "5) Continue with the Git workflow"
    echo "6) Exit"

    read choice

    case $choice in
        1)
            list_branches_repos
            ;;
        2)
            create_branch_repo
            ;;
        3)
            search_file
            ;;
        4)
            select_branch_repo
            ;;
        5)
            if ! git config --get remote.origin.url &>/dev/null; then
                echo -e "${YELLOW}Remote repository URL is not configured.${NC}"
                read -p "Do you want to configure it now? (y/n) " configure_remote
                if [ "$configure_remote" = "y" ] || [ "$configure_remote" = "Y" ]; then
                    configure_remote_url
                else
                    echo "Git workflow skipped."
                fi
            fi

            if git config --get remote.origin.url &>/dev/null; then
                while true; do
                    echo "Select an option:"
                    echo "1) Add files or directories"
                    echo "2) Commit"
                    echo "3) Push"
                    echo "4) Commit and Push"
                    echo "5) Pull"
                    echo "6) Select a commit"
                    echo "7) Go back to the previous menu"

                    read git_choice

                    case $git_choice in
                        1)
                            handle_add_file_directory
                            ;;
                        2)
                            select_commit
                            ;;
                        3)
                            push_changes
                            ;;
                        4)
                            handle_add_file_directory
                            push_changes
                            ;;
                        5)
                            read -p "Enter the branch to pull from: " pull_branch
                            git pull origin "$pull_branch"
                            ;;
                        6)
                            select_commit
                            ;;
                        7)
                            break
                            ;;
                        *)
                            echo "Invalid option. Please try again."
                            ;;
                    esac
                done
            fi
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done

