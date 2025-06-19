#!/usr/bin/env python3
"""
utils/create_s3_bucket_structure.py

Creates a secure, uniquely-named S3 bucket with:
- Versioning
- Blocked public access
- Initial folder structure with placeholder files:
    - data/raw/<timestamp>/
    - pulumi/

Persists the Pulumi backend URL as `PULUMI_BACKEND_URL=s3://<bucket>` into `.env` file in project root.
"""

import boto3
import botocore
import logging
import string
import random
from datetime import datetime
from pathlib import Path

# === Constants ===
BASE_BUCKET_NAME = "autoopsscaler-bucket"
PROJECT_ROOT = Path("/vagrant")
ENV_FILE = PROJECT_ROOT / ".env"
PLACEHOLDER_FILENAME = ".keep"
PLACEHOLDER_CONTENT = "This file ensures the folder exists in S3.\n"

# === Setup logging ===
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger("s3_setup")

# === Generate unique bucket name ===
def generate_bucket_name() -> str:
    suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return f"{BASE_BUCKET_NAME}-{suffix}"

# === AWS region ===
session = boto3.session.Session()
region = session.region_name
if not region:
    raise RuntimeError("AWS region not configured. Run `aws configure`.")

s3 = session.client("s3")

# === Ensure folder structure ===
TIMESTAMP = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
FOLDERS_TO_CREATE = [
    f"data/raw/{TIMESTAMP}/",
    "pulumi/"
]

# === Create local placeholder file ===
tmp_dir = PROJECT_ROOT / "tmp"
tmp_dir.mkdir(parents=True, exist_ok=True)
placeholder_path = tmp_dir / PLACEHOLDER_FILENAME
if not placeholder_path.exists():
    placeholder_path.write_text(PLACEHOLDER_CONTENT)

# === Create bucket if needed ===
def ensure_bucket_exists(bucket: str):
    try:
        s3.head_bucket(Bucket=bucket)
        logger.info(f"Bucket '{bucket}' already exists.")
    except botocore.exceptions.ClientError as e:
        code = e.response["Error"]["Code"]
        if code == "404":
            logger.info(f"Bucket '{bucket}' does not exist. Creating...")
            kwargs = {"Bucket": bucket}
            if region != "us-east-1":
                kwargs["CreateBucketConfiguration"] = {"LocationConstraint": region}
            s3.create_bucket(**kwargs)
            logger.info(f"[SUCCESS] Bucket '{bucket}' created.")
        else:
            raise

# === Enable versioning ===
def enable_versioning(bucket: str):
    s3.put_bucket_versioning(
        Bucket=bucket,
        VersioningConfiguration={"Status": "Enabled"}
    )
    logger.info(f"Versioning enabled for bucket '{bucket}'")

# === Block all public access ===
def block_public_access(bucket: str):
    s3.put_public_access_block(
        Bucket=bucket,
        PublicAccessBlockConfiguration={
            "BlockPublicAcls": True,
            "IgnorePublicAcls": True,
            "BlockPublicPolicy": True,
            "RestrictPublicBuckets": True
        }
    )
    logger.info(f"Public access fully blocked on bucket '{bucket}'")

# === Upload placeholder ===
def upload_placeholder(bucket: str, folder: str, placeholder_file: Path):
    key = folder.rstrip("/") + "/" + placeholder_file.name
    try:
        s3.upload_file(str(placeholder_file), bucket, key)
        logger.info(f"[OK] Created folder '{folder}' with placeholder.")
    except Exception as e:
        logger.error(f"Failed to upload to '{key}': {e}")
        raise

# === Save backend to .env ===
def write_backend_env(bucket: str):
    backend_url = f"s3://{bucket}"
    lines = []
    if ENV_FILE.exists():
        lines = ENV_FILE.read_text().splitlines()
        lines = [line for line in lines if not line.startswith("PULUMI_BACKEND_URL=")]
    lines.append(f"PULUMI_BACKEND_URL={backend_url}")
    ENV_FILE.write_text("\n".join(lines) + "\n")
    logger.info(f"[ENV] Written backend URL to .env: {backend_url}")

# === Main ===
def main():
    bucket = generate_bucket_name()
    logger.info(f"Provisioning S3 bucket: {bucket}")
    ensure_bucket_exists(bucket)
    enable_versioning(bucket)
    block_public_access(bucket)
    for folder in FOLDERS_TO_CREATE:
        upload_placeholder(bucket, folder, placeholder_path)
    write_backend_env(bucket)
    logger.info("[DONE] S3 bucket structure provisioned securely.")

if __name__ == "__main__":
    main()
