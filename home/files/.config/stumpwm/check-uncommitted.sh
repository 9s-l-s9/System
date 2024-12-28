#!/bin/sh

# Base directory to search for git projects
BASE_DIR="/home/samuel/Projects"

# Find all .git directories, check for uncommitted changes, and output results
find "$BASE_DIR" -type d -name ".git" | while read -r gitdir; do
    repo_dir=$(dirname "$gitdir")
    status=$(git -C "$repo_dir" status --porcelain)
    if [[ -n $status ]]; then
        echo "Uncommitted changes in: $repo_dir"
    fi
done
