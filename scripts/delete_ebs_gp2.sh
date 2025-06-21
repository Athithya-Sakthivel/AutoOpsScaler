#!/bin/bash
# Delete only gp2 EBS volumes in the current AWS_REGION

set -euo pipefail

export $(grep -v '^#' .env | xargs)

if [[ -z "${AWS_REGION:-}" ]]; then
  echo "[ERROR] AWS_REGION is not set"
  exit 1
fi

echo "[INFO] Looking for gp2 EBS volumes in region: $AWS_REGION"

volumes=$(aws ec2 describe-volumes \
  --region "$AWS_REGION" \
  --filters "Name=volume-type,Values=gp2" \
  --query "Volumes[].{ID:VolumeId,AZ:AvailabilityZone,Size:Size,State:State}" \
  --output json)

if [[ $(echo "$volumes" | jq length) -eq 0 ]]; then
  echo "  No gp2 volumes found in $AWS_REGION"
  exit 0
fi

echo "$volumes" | jq -r '.[] | "  Deleting: \(.ID) | Size: \(.Size)GiB | AZ: \(.AZ) | State: \(.State)"'

for volume_id in $(echo "$volumes" | jq -r '.[].ID'); do
  aws ec2 delete-volume --region "$AWS_REGION" --volume-id "$volume_id" > /dev/null
done

echo "[DONE] Deleted all gp2 volumes in $AWS_REGION"