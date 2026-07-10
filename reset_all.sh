#!/bin/bash

set -e

# Get list of project repos
projects=$(cat projects)

# Git master/main branch name
branch="master"

if [ ! -z "$1" ]; then
    branch=$1
fi

source="${branch}"/source

pushd "${source}"

for project in ${projects}; do
    echo "Resetting $branch/$project"
    pushd "${project}" > /dev/null
    current_branch=$(git branch | grep "\*" | cut -d' ' -f2)
    if [ ! "$current_branch" = "$branch" ]; then
        echo "BRANCH $current_branch IS NOT $branch: Skipping!"
        echo "BRANCH $current_branch IS NOT $branch: Skipping!"
        echo "BRANCH $current_branch IS NOT $branch: Skipping!"
        echo "BRANCH $current_branch IS NOT $branch: Skipping!"
        echo "BRANCH $current_branch IS NOT $branch: Skipping!"
    else
        git fetch official
        git reset --hard official/"${branch}"
    fi
    popd > /dev/null
done
