#!/bin/bash
#
# This script will be triggered when "master" branch is updated.
# It copies "submitted_data" and "processed_data" to permanent locations in S3
# buckets, cleans up everything in "submitted/" sub-directory and commits the
# changes back to remote repo.

set -e -x

function delete_requests() {
    if [ -f submitted/*.yml ] || [ -f submitted/*.yaml ]; then
	git rm --ignore-unmatch submitted/*.yml submitted/*.yaml
	git commit -m "CircleCI: Delete requests in submitted/ dir [skip ci]"
	git push --force --quiet origin master
    fi
}

# Git config
git config --global user.email "cimrroot@gmail.com"
git config --global user.name "cimrroot"
git config --global push.default simple

cd ~/cimr-d/
git lfs install

# Find the PR number of the latest commit
LATEST_COMMIT_HASH=$(git log -1 --pretty=format:%H)
GITHUB_SEARCH_URL="https://api.github.com/search/issues?q=sha:${LATEST_COMMIT_HASH}"
PR_NUMBER=$(curl -s $GITHUB_SEARCH_URL | jq '.items[0].number')

# If we're not merging a PR, clean up "submitted/" dir and exit.
if [ $PR_NUMBER == 'null' ]; then
    delete_requests
    exit 0
fi

# If we are merging a PR, but the indicator object is not found in S3 bucket,
# data processing must either fail or not start at all, so we exit too.
INDICATOR_FIELNAME="submitted_data/request.handled"
if [ ! -f ${INDICATOR_FIELNAME} ]; then
    delete_requests
    exit 0
fi

# Install awscli to make "aws" command available
sudo pip install awscli

# Move files in S3 buckets from temporary to permanent locations.
aws s3 sync submitted_data/  s3://cimr-root/PR-${PR_NUMBER}/
aws s3 sync processed_data/  s3://cimr-d/

# Move submitted YAML files to "processed/" sub-dir
mkdir -p processed/PR-${PR_NUMBER}/
git mv -k submitted/*.yml submitted/*.yaml processed/PR-${PR_NUMBER}/
git commit -m "CircleCI: Save requests to processed/ dir [skip ci]"

# Update README.md, which lists all files in "cimr-d" S3 bucket
aws s3 ls cimr-d --recursive --human-readable > processed/s3_list.txt
python3 .circleci/txt2md.py
git add processed/README.md
git commit -m "Update REAME.md [skip ci]"

# Push new commits to remote "master" branch
ssh-keyscan github.com >> ~/.ssh/known_hosts
git push --force --quiet origin master
