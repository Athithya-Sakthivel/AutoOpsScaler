#!/bin/bash
# Delete all gp2 EBS volumes in the AWS region defined in .env

set -euo pipefail

# Load env vars from .env
export $(grep -v '^#' .env | xargs)

if [[ -z "${AWS_REGION:-}" ]]; then
  echo "[ERROR] AWS_REGION is not set in the environment."
  exit 1
fi

echo "[INFO] Scanning for gp2 EBS volumes in region: $AWS_REGION"

# Fetch volume list as JSON
volumes=$(aws ec2 describe-volumes \
  --region "$AWS_REGION" \
  --filters "Name=volume-type,Values=gp2" \
  --query "Volumes[].{ID:VolumeId,AZ:AvailabilityZone,Size:Size,State:State}" \
  --output json)

volume_count=$(echo "$volumes" | jq length)

if [[ $volume_count -eq 0 ]]; then
  echo "[OK] No gp2 volumes found in $AWS_REGION"
  exit 0
fi

echo "[INFO] Found $volume_count gp2 volume(s) to delete:"
echo "$volumes" | jq -r '.[] | "  Deleting: \(.ID) | Size: \(.Size)GiB | AZ: \(.AZ) | State: \(.State)"'

# Delete all found gp2 volumes
for volume_id in $(echo "$volumes" | jq -r '.[].ID'); do
  aws ec2 delete-volume --region "$AWS_REGION" --volume-id "$volume_id" > /dev/null
done

echo "[DONE] Successfully deleted all gp2 volumes in $AWS_REGION"

aws ec2 describe-volumes \
  --query "Volumes[*].{ID:VolumeId,Size:Size,AZ:AvailabilityZone,State:State,Type:VolumeType}" \
  --output table
