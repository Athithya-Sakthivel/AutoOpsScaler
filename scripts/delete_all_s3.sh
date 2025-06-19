#!/usr/bin/env bash

# THIS SCRIPT IS FOR DEV PURPOSE ONLY DO NOT USE IN PRODUCTION




for bucket in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do
  echo "Processing bucket: $bucket"

  # Remove all object versions
  versions=$(aws s3api list-object-versions --bucket "$bucket" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text)
  if [ -n "$versions" ]; then
    echo "$versions" | while read key version; do
      aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$version" --output text
    done
  fi

  # Remove delete markers
  markers=$(aws s3api list-object-versions --bucket "$bucket" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text)
  if [ -n "$markers" ]; then
    echo "$markers" | while read key version; do
      aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$version" --output text
    done
  fi

  # Remove any remaining objects (non-versioned / unversioned case)
  aws s3 rm "s3://$bucket" --recursive --only-show-errors

  # Attempt to delete the bucket
  aws s3api delete-bucket --bucket "$bucket" --output text || echo "Failed to delete $bucket"
done
