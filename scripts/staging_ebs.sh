#!/bin/bash
# Create a 10GiB gp2 EBS volume in the region from $AWS_REGION

set -euo pipefail

if [[ -z "${AWS_REGION:-}" ]]; then
  echo "Error: AWS_REGION is not set in the environment."
  exit 1
fi

AZ=$(aws ec2 describe-availability-zones \
  --region "$AWS_REGION" \
  --query "AvailabilityZones[?State=='available'].[ZoneName]" \
  --output text | head -n 1)

VOLUME_ID=$(aws ec2 create-volume \
  --size 10 \
  --volume-type gp2 \
  --availability-zone "$AZ" \
  --region "$AWS_REGION" \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=qdrant-staging}]' \
  --query "VolumeId" --output text)

echo "EBS volume created: $VOLUME_ID in $AZ"
