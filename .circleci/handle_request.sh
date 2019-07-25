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
if [ ! -f submitted/*.yml ] && [ ! -f submitted/*.yaml ]; then
    exit 0
fi

# Name of flag file, whose existence indicates that request has been handled correctly.
INDICATOR_FILENAME="submitted_data/request.handled"

# Remove flag file before data processing
rm -rf $INDICATOR_FILENAME

# Parse user request, download data (and extract archive file, if available)
python3 .circleci/parse_yaml.py

# Process submitted data
python3 .circleci/process_submitted_data.py

# Create the flag file at the end
touch $INDICATOR_FILENAME
