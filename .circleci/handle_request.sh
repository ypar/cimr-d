#!/bin/bash
#
# This script is executed at the end of data crunching to save downloaded and
# decompressed files in a temporary location in private S3 bucket.

set -e -x

# Error if the PR includes any files in "processed/" directory.
if [ -n "${CIRCLE_PULL_REQUEST}" ]; then
    PR_NUMBER=$(echo ${CIRCLE_PULL_REQUEST} | awk -F'/cimr-d/pull/' '{print $2}')
else
    git config --global user.email "cimrroot@gmail.com"
    git config --global user.name "cimrroot"
    git config --global push.default simple

    # Add SSH keys to make "git pull/push" work
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    # Find the PR number of the latest commit
    LATEST_COMMIT_HASH=$(git log -1 --pretty=format:%H)
    GITHUB_SEARCH_URL="https://api.github.com/search/issues?q=sha:${LATEST_COMMIT_HASH}"
    PR_NUMBER=$(curl -s $GITHUB_SEARCH_URL | jq '.items[0].number')
fi

if [ -z "$PR_NUMBER" ] || [ $PR_NUMBER == 'null' ]; then
    exit 0
fi

GH_PR_API="https://api.github.com/repos/greenelab/cimr-d/pulls/${PR_NUMBER}/files"
PR_FILES=$(curl -s ${GH_PR_API} | jq -r '.[].filename')
echo "${PR_FILES}" | grep "^processed/" || PROCESSED_UNCHANGED=true
if [ -z "${PROCESSED_UNCHANGED}" ]; then
    echo "Error: Changes in 'processed' directory not allowed!"
    exit 1
fi

# Exit if no yaml files in "submitted/" directory
shopt -s nullglob dotglob

SUBMITTED_YAMLS=$(echo "${PR_FILES}" | grep -E "^submitted/.*\.(yml|yaml)$") || true
if [ -z "${SUBMITTED_YAMLS}" ]; then
    exit 0
fi

# Extract all values in 7th column ("submitted_data_md5") from catalog.txt
# (The first line is skipped because it is the header.)
MD5_IN_CATALOG=""
if [ -f catalog.txt ]; then
    MD5_IN_CATALOG=$(awk -F'\t' '{ if (NR > 1) print $7 }' catalog.txt)
fi

# Use the latest "pip"
sudo pip install --upgrade pip

# Install "shyaml" to parse yaml files in shell ("yq" is another alternative).
sudo pip install shyaml

# Check each yaml file's data_file.location.md5 to ensure that it was not processed before.
# If it was, report the error and quit immediately.
for f in ${SUBMITTED_YAMLS}; do
    f_url=$(cat $f | shyaml get-value data_file.location.url)
    f_md5=$(cat $f | shyaml get-value data_file.location.md5)

    unset MD5_NOT_FOUND
    echo ${MD5_IN_CATALOG} | grep --quiet "${f_md5}" || MD5_NOT_FOUND=true

    if [ -z "${MD5_NOT_FOUND}" ]; then
	echo "Error in $f: ${f_url} has already been processed!"
	exit 1
    fi
done

# Name of flag file, whose existence indicates that request has been handled correctly.
INDICATOR_FILENAME="submitted_data/request.handled"

# Remove flag file before data processing
rm -rf $INDICATOR_FILENAME

# For each yaml file, download and process data
for f in ${SUBMITTED_YAMLS}; do
    cimr processor -process -yaml-file $f -catalog-name PR_catalog.txt
done

# Create the flag file at the end
touch $INDICATOR_FILENAME
