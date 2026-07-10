#!/bin/bash

set -e

# Get list of project repos
projects=$(cat projects)

# Git master/main branch name
branch="master"

if [ ! -z "$1" ]; then
    branch=$1
fi

source=${branch}/source

pushd "${source}"

for project in ${projects}; do
    echo "Running diff for $branch/$project"
    pushd "${project}" > /dev/null
    git diff official/"${branch}"
    popd > /dev/null
done

popd > /dev/null # source
