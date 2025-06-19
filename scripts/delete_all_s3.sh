#!/usr/bin/env bash

# THIS SCRIPT IS FOR DEV PURPOSE ONLY DO NOT USE IN PRODUCTION


#!/bin/bash
set -euo pipefail

echo "Starting S3 buckets deletion process..."

# List all buckets
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

for bucket in $buckets; do
  echo "Processing bucket: $bucket"

  # Remove all object versions (if any)
  aws s3api list-object-versions --bucket "$bucket" --output json | jq -c '.Versions[]?, .DeleteMarkers[]?' | while read -r obj; do
    key=$(echo "$obj" | jq -r '.Key')
    versionId=$(echo "$obj" | jq -r '.VersionId')

    if [[ -n "$key" && -n "$versionId" && "$versionId" != "null" ]]; then
      echo "Deleting object: $key (version: $versionId)"
      aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$versionId" --only-show-errors
    fi
  done

  # Remove any remaining unversioned objects
  echo "Removing remaining unversioned objects (if any)..."
  aws s3 rm "s3://$bucket" --recursive --only-show-errors || true

  # Try deleting the bucket
  echo "Deleting bucket: $bucket"
  if aws s3api delete-bucket --bucket "$bucket" --only-show-errors; then
    echo "Bucket $bucket deleted successfully."
  else
    echo "Failed to delete bucket $bucket (may still contain objects or versions)."
  fi
done

echo "S3 buckets deletion process completed."
