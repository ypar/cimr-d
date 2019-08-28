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

# Find the PR number of the latest commit
LATEST_COMMIT_HASH=$(git log -1 --pretty=format:%H)
GITHUB_SEARCH_URL="https://api.github.com/search/issues?q=sha:${LATEST_COMMIT_HASH}"
PR_NUMBER=$(curl -s $GITHUB_SEARCH_URL | jq '.items[0].number')

# If we're not merging a PR, clean up "submitted/" dir and exit.
if [ $PR_NUMBER == 'null' ]; then
    delete_requests
    exit 0
fi

PR_STR="PR-${PR_NUMBER}"

# If we are merging a PR, but the indicator object is not found in S3 bucket,
# data processing must either fail or not start at all, so we exit too.
INDICATOR_FIELNAME="submitted_data/request.handled"
if [ ! -f ${INDICATOR_FIELNAME} ]; then
    delete_requests
    exit 0
fi

# Use the latest "pip"
sudo pip install --upgrade pip

# Install awscli to make "aws" command available
sudo pip install awscli

# Copy "processed_data" to "cimr-d" bucket (public).
# "PR-<n>" is inserted in filenames to avoid duplicates.
OUTPUT_FILES=$(find processed_data -type f)
for f in ${OUTPUT_FILES}; do
    g=$(echo $f | cut -d'/' -f'2-')    # strip "processed_data/" from $f
    S3DIR=$(dirname $g)                # S3 object's dir name

    g_base=$(basename $g)              # base filename
    tokens=(${g_base//./ })            # split $g_base into an array using '/'
    LEN="${#tokens[@]}"                # number of items in tokens

    if [ $LEN -eq 1 ]; then
	# "foo" will become "foo-PR-n"
	S3BASE="${g_base}-${PR_STR}"
    elif [ $LEN -eq 2 ]; then
	# "foo.ext1" will become "foo-PR-n.ext1"
	S3BASE="${tokens[0]}-${PR_STR}.${tokens[1]}"
    else
	# "foo.ext2.ext1" will become "foo-PR-n.ext2.ext1"
	S3BASE="${tokens[0]}"
	for ((i = 1; i < $LEN - 2; i++)); do
	    S3BASE="${S3BASE}.${tokens[$i]}"
	done

	LEN_m2=$(expr $LEN - 2)        # $LEN - 2
	LEN_m1=$(expr $LEN - 1)        # $LEN - 1
	S3BASE="$S3BASE-${PR_STR}.${tokens[$LEN_m2]}.${tokens[$LEN_m1]}"
    fi

    S3NAME="${S3DIR}/$S3BASE"
    aws s3 cp $f s3://cimr-d/${S3NAME}
done

# Copy "submitted_data" to "cimr-root" bucket (private)
aws s3 sync submitted_data/ s3://cimr-root/${PR_STR}/ --exclude "request.handled"

# Move submitted YAML files to "processed/" sub-dir
mkdir -p processed/${PR_STR}/
git mv -k submitted/*.yml submitted/*.yaml processed/${PR_STR}/

# Update "processed/README.md", which lists all files in "cimr-d" S3 bucket
aws s3 ls cimr-d --recursive --human-readable > processed/s3_list.txt
python3 .circleci/txt2md.py
git add processed/README.md

# Update "catalog.txt"
git add catalog.txt

# Commit changes and push them to remote "master" branch
git commit -m "CircleCI: Save processed request ${PR_STR} [skip ci]"
ssh-keyscan github.com >> ~/.ssh/known_hosts
git push --force --quiet origin master
