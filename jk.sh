#!/bin/bash

# Define color variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display the current location
function display_location() {
    echo -e "${YELLOW}Current location:${NC} $(pwd)"
}

# Function to select an available branch or repository
function select_branch_repo() {
    display_location
    echo -e "${YELLOW}Available branches:${NC}"
    git branch -a
    echo -e "${YELLOW}Available repositories:${NC}"
    git remote -v

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

# Function to commit changes
function git_commit() {
    display_location
    git status
    read -p "Enter the commit message: " new_commit_message
    git commit -m "$new_commit_message"
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

# Function to display the git status
function git_status() {
    display_location
    git status
}

# Example function to add your script to a GitHub repository
function add_to_github() {
    # Make sure you are in the correct directory
    cd /path/to/your/repository/

    # Create a new branch (optional)
    git checkout -b feature/new-feature

    # Add your script to the repository
    cp /path/to/your/script.sh .

    # Add the script to the staging area
    git add script.sh

    # Commit the changes
    git commit -m "Add my awesome script"

    # Push the changes to the remote repository
    git push origin feature/new-feature
}

# Main menu loop
while true; do
    echo "Select an option:"
    echo "1) Select an available branch or repository"
    echo "2) Create a new branch or repository"
    echo "3) Search for a file"
    echo "4) Continue with the Git workflow"
    echo "5) Git Status"
    echo "6) Exit"
    echo "7) Add script to GitHub (Example)"

    read choice

    case $choice in
        1)
            select_branch_repo
            ;;
        2)
            create_branch_repo
            ;;
        3)
            search_file
            ;;
        4)
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
                            git_commit
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
                            add_to_github
                            ;;
                        8)
                            break
                            ;;
                        *)
                            echo "Invalid option. Please try again."
                            ;;
                    esac
                done
            fi
            ;;
        5)
            git_status
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

