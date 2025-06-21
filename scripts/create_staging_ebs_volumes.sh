#!/bin/bash
# Idempotently create 3 gp2 EBS volumes with task-specific tags and print their IDs/AZs

set -euo pipefail

export $(grep -v '^#' .env | xargs)

if [[ -z "${AWS_REGION:-}" ]]; then
  echo "Error: AWS_REGION is not set in the environment."
  exit 1
fi

AZ=$(aws ec2 describe-availability-zones \
  --region "$AWS_REGION" \
  --query "AvailabilityZones[?State=='available'].[ZoneName]" \
  --output text | head -n 1)

declare -A VOLUME_SUMMARY

create_if_missing() {
  local name=$1
  local var_prefix=$2

  echo "[CHECK] Looking for existing EBS volume with tag Name=$name in $AWS_REGION"

  existing_volume_id=$(aws ec2 describe-volumes \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=$name" \
    --query "Volumes[0].VolumeId" \
    --output text 2>/dev/null || echo "none")

  if [[ "$existing_volume_id" != "none" && "$existing_volume_id" != "None" ]]; then
    echo "[SKIP] $name already exists: $existing_volume_id"
  else
    new_volume_id=$(aws ec2 create-volume \
      --size 5 \
      --volume-type gp2 \
      --availability-zone "$AZ" \
      --region "$AWS_REGION" \
      --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=$name}]" \
      --query "VolumeId" --output text)

    echo "[CREATE] Created $name ($new_volume_id) in $AZ"
    existing_volume_id=$new_volume_id
  fi

  # Append to .env only if not already defined
  if ! grep -q "^${var_prefix}_EBS_VOLUME_ID=" .env; then
    {
      echo ""
      echo "# $name EBS volume"
      echo "${var_prefix}_EBS_VOLUME_ID=$existing_volume_id"
      echo "${var_prefix}_EBS_AVAILABILITY_ZONE=$AZ"
    } >> .env
    echo "[EXPORT] Added $var_prefix vars to .env"
  else
    echo "[SKIP] $var_prefix already defined in .env"
  fi

  VOLUME_SUMMARY["$name"]="VolumeID=$existing_volume_id | AZ=$AZ"
}

echo "[START] Idempotent EBS volume provisioning in region: $AWS_REGION"

create_if_missing "qdrant-staging"       "QDRANT"
create_if_missing "postgres-staging"     "POSTGRES"
create_if_missing "pipeline-tmp-storage" "PIPELINE_TMP"

echo ""
echo "[DONE] All volumes are provisioned and .env is synced"
echo "========================================================"
echo "Summary:"
for key in "${!VOLUME_SUMMARY[@]}"; do
  printf "  - %-24s => %s\n" "$key" "${VOLUME_SUMMARY[$key]}"
done
echo "========================================================"
