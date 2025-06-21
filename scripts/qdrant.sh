#!/bin/bash
# Create a 10GiB gp2 EBS volume for Qdrant in $AWS_REGION and export vars to .env

set -euo pipefail

export $(grep -v '^#' .env | xargs)


if [[ -z "${AWS_REGION:-}" ]]; then
  echo "Error: AWS_REGION is not set in the environment."
  exit 1
fi


QDRANT_EBS_AZ=$(aws ec2 describe-availability-zones \
  --region "$AWS_REGION" \
  --query "AvailabilityZones[?State=='available'].[ZoneName]" \
  --output text | head -n 1)

QDRANT_EBS_VOLUME_ID=$(aws ec2 create-volume \
  --size 10 \
  --volume-type gp2 \
  --availability-zone "$QDRANT_EBS_AZ" \
  --region "$AWS_REGION" \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=qdrant-staging}]' \
  --query "VolumeId" --output text)

echo "Created Qdrant EBS volume: $QDRANT_EBS_VOLUME_ID in $QDRANT_EBS_AZ"

# Export to .env file
cat <<EOF >> .env
QDRANT_EBS_VOLUME_ID=$QDRANT_EBS_VOLUME_ID
QDRANT_EBS_AVAILABILITY_ZONE=$QDRANT_EBS_AZ
AWS_REGION=$AWS_REGION
EOF

echo "Exported configs to .env"

