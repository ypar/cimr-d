#!/bin/bash
#
# This script is executed at the end of data crunching to save downloaded and
# decompressed files in a temporary location in private S3 bucket.

set -e -x

# Error if any change in "processed/" directory is detected.
git diff origin/master --name-only | grep "^processed/" || PROCESSED_UNCHANGED=true
if [ -z "$PROCESSED_UNCHANGED" ]; then
    echo "Error: Commits in 'processed' directory not allowed!"
    exit 1
fi

# Exit if no yaml files in "submitted/" directory
shopt -s nullglob dotglob

yml_files=(submitted/*.yml submitted/*.yaml)
if [ ${#yml_files[@]} -eq 0 ]; then
    exit 0
fi

# Extract all values in 7th column ("submitted_data_md5") from cimr-d_catalog.txt
# (The first line is skipped because it is the header.)
MD5_IN_CATALOG=""
if [ -f cimr-d_catalog.txt ]; then
    MD5_IN_CATALOG=$(awk -F'\t' '{ if (NR > 1) print $7 }' cimr-d_catalog.txt)
fi

# Use the latest "pip"
sudo pip install --upgrade pip

# Install "shyaml" to parse yaml files in shell ("yq" is another alternative).
sudo pip install shyaml

# Check each yaml file's data_file.location.md5 to ensure that it was not processed before.
# If it was, report the error and quit immediately.
for f in ${yml_files[*]}; do
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
for f in ${yml_files[*]}; do
    cimr processor -process -yaml-file $f
done

# Create the flag file at the end
touch $INDICATOR_FILENAME
