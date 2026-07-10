#!/bin/bash

set -e

# Git username
git_user="thecodefactory"

# Get list of project repos
projects=$(cat projects)

# Git master/main branch name
branch="master"

if [ ! -z "$1" ]; then
    branch=$1
fi

source=$branch/source

if [ ! -d "${source}" ]; then
    mkdir -p "${source}"
fi

pushd "${source}"

for project in ${projects}; do
    if [ ! -d "${project}" ]; then
	echo "Processing ${project}"
        git clone git@github.com:${git_user}/"${project}".git
	pushd "${project}" > /dev/null
	git remote add official https://github.com/libbitcoin/"${project}".git
	git fetch official
        if [ "${branch}" == "master" ]; then
            git reset --hard official/"${branch}"
        else
            git checkout -b "${branch}" official/"${branch}"
        fi
	popd > /dev/null # project
    else
	echo "SKIPPING ${project}"
    fi
done

popd > /dev/null # source
