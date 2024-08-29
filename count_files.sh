#!/bin/bash

# ANSI color codes and cursor control
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'

# Version of the script
VERSION="1.3.0"

# Function to print usage
print_usage() {
    echo -e "${YELLOW}Usage: $0 [-p <directory>] [-s] [-l <level>] [-e <exclude-path>] [-h] [-v]${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${GREEN}-p <directory>${NC}  Directory to count files and folders in (default: ./)"
    echo -e "  ${GREEN}-s${NC}            Display subfolders with file and folder counts"
    echo -e "  ${GREEN}-l <level>${NC}    Display subfolders up to a specific depth level (default: all levels)"
    echo -e "  ${GREEN}-e <exclude-path>${NC}  Exclude specific subdirectories or files (can be used multiple times)"
    echo -e "  ${GREEN}-h${NC}            Display this help message"
    echo -e "  ${GREEN}-v${NC}            Display version information"
}

# Function to display a progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local progress=$(( current * width / total ))
    local remainder=$(( width - progress ))

    printf "\r["
    for i in $(seq 1 $progress); do printf "#"; done
    for i in $(seq 1 $remainder); do printf " "; done
    printf "] %3d%%" $(( current * 100 / total ))
}

# Function to check if an item should be excluded
should_exclude() {
    local item="$1"
    for exclude in "${exclude_paths[@]}"; do
        if [[ "$item" == *"$exclude"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to count files and folders recursively within a given directory
count_recursive() {
    local directory="$1"
    local file_count=0
    local folder_count=0

    # Count files and folders
    while IFS= read -r item; do
        if [ -f "$item" ]; then
            file_count=$((file_count + 1))
        elif [ -d "$item" ]; then
            folder_count=$((folder_count + 1))
        fi
    done < <(find "$directory" -type f -o -type d)

    echo "$file_count,$folder_count"
}

# Function to count files and folders and list subfolders in the given directory
count_files_and_folders() {
    local directory="$1"
    local display_subfolders="$2"
    local level="$3"
    shift 3
    local excludes=("$@")

    # Get the total number of items (files + folders) for progress tracking
    local total_items=$(find "$directory" -maxdepth "$level" \( -type f -o -type d \) | wc -l)

    local file_count=0
    local folder_count=0
    local current_item=0

    # Temporary file to hold the list of subfolders
    local subfolder_list=$(mktemp)

    # Find all items within the specified depth
    while IFS= read -r item; do
        if should_exclude "$item"; then
            continue
        fi

        if [ -f "$item" ]; then
            file_count=$((file_count + 1))
        elif [ -d "$item" ]; then
            folder_count=$((folder_count + 1))
            if [ "$display_subfolders" -eq 1 ]; then
                # List subdirectories based on the specified depth level
                find "$item" -mindepth 1 -maxdepth "$level" -type d >> "$subfolder_list"
            fi
        fi

        current_item=$((current_item + 1))
        show_progress "$current_item" "$total_items"
    done < <(find "$directory" -maxdepth "$level" \( -type f -o -type d \))

    # Print a new line after the progress bar is complete
    printf "\r\033[K\n"

    # Print total counts
    echo -e "${GREEN}Total files: ${file_count}${NC}"
    echo -e "${GREEN}Total folders: ${folder_count}${NC}"

    # Print all subfolders with file and folder counts if the option is set
    if [ "$display_subfolders" -eq 1 ]; then
        echo -e "${GREEN}Subfolders:${NC}"

        # Print table header
        printf "%-50s %-10s %-10s\n" "Directory" "Files" "Folders"
        printf "%-50s %-10s %-10s\n" "---------" "-----" "-------"

        while IFS= read -r folder; do
            if should_exclude "$folder"; then
                continue
            fi
            # Count files and folders in each subfolder recursively
            local counts=$(count_recursive "$folder" "${exclude_paths[@]}")
            local num_files=$(echo "$counts" | cut -d',' -f1)
            local num_folders=$(echo "$counts" | cut -d',' -f2)
            # Print directory and counts
            printf "%-50s %-10d %-10d\n" "$folder" "$num_files" "$num_folders"
        done < "$subfolder_list"
    fi

    # Clean up temporary file
    rm "$subfolder_list"
}

# Parse command-line arguments
while getopts ":p:se:l:e:hv" opt; do
    case $opt in
        p)
            directory_path="$OPTARG"
            ;;
        s)
            display_subfolders=1
            ;;
        l)
            level="$OPTARG"
            ;;
        e)
            exclude_paths+=("$OPTARG")
            ;;
        h)
            print_usage
            exit 0
            ;;
        v)
            echo -e "${GREEN}Script Version: ${VERSION}${NC}"
            exit 0
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac
done

# Default directory path if not provided
directory_path=${directory_path:-./}

# Default value for display_subfolders if not set
display_subfolders=${display_subfolders:-0}

# Default value for level if not set
level=${level:-999} # A high number to include all levels if not specified

# Check if the directory exists
if [ ! -d "$directory_path" ]; then
    echo -e "${RED}Error: Directory '$directory_path' does not exist.${NC}"
    exit 1
fi

# Hide the cursor
echo -e "$HIDE_CURSOR"

# Trap to ensure cursor is shown when the script exits
trap 'echo -e "$SHOW_CURSOR"' EXIT

# Record the start time
start_time=$(date +%s)

# Call the function with the provided directory, display subfolders, and level
count_files_and_folders "$directory_path" "$display_subfolders" "$level" "${exclude_paths[@]}"

# Record the end time
end_time=$(date +%s)

# Calculate the elapsed time
elapsed_time=$((end_time - start_time))

# Print the execution time
echo -e "${GREEN}Execution time: ${elapsed_time} seconds${NC}"

# Restore the cursor at the end of the script
echo -e "$SHOW_CURSOR"
