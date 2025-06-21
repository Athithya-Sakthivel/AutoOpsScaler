"""
utils/create_s3_backend_bucket.py

Creates a secure, uniquely-named S3 bucket for Terraform backend with:
- Versioning
- Blocked public access
- A terraform/ folder with placeholder
- Persists TF_BACKEND_URL=s3://<bucket> into .env
"""

import boto3
import botocore
import logging
import string
import random
from pathlib import Path

BASE_BUCKET_NAME = "autoopsscaler-tf-backend"
PROJECT_ROOT = Path("/vagrant")
ENV_FILE = PROJECT_ROOT / ".env"
PLACEHOLDER_FILENAME = ".keep"
PLACEHOLDER_CONTENT = "This file ensures the folder exists in S3.\n"

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger("tf_backend_s3_setup")

def generate_bucket_name() -> str:
    suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return f"{BASE_BUCKET_NAME}-{suffix}"

session = boto3.session.Session()
region = session.region_name
if not region:
    raise RuntimeError("AWS region not configured. Run `aws configure`.")

s3 = session.client("s3")

tmp_dir = PROJECT_ROOT / "tmp"
tmp_dir.mkdir(parents=True, exist_ok=True)
placeholder_path = tmp_dir / PLACEHOLDER_FILENAME
if not placeholder_path.exists():
    placeholder_path.write_text(PLACEHOLDER_CONTENT)

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
            logger.info(f"Bucket '{bucket}' created.")
        else:
            raise

def enable_versioning(bucket: str):
    s3.put_bucket_versioning(
        Bucket=bucket,
        VersioningConfiguration={"Status": "Enabled"}
    )
    logger.info(f"Versioning enabled on '{bucket}'")

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
    logger.info(f"Public access blocked on '{bucket}'")

def upload_placeholder(bucket: str, folder: str, placeholder_file: Path):
    key = folder.rstrip("/") + "/" + placeholder_file.name
    s3.upload_file(str(placeholder_file), bucket, key)
    logger.info(f"Created folder '{folder}' with placeholder.")

def write_backend_env(bucket: str):
    backend_url = f"s3://{bucket}"
    lines = []
    if ENV_FILE.exists():
        lines = ENV_FILE.read_text().splitlines()
        lines = [line for line in lines if not line.startswith("TF_BACKEND_URL=")]
    lines.append(f"TF_BACKEND_URL={backend_url}")
    ENV_FILE.write_text("\n".join(lines) + "\n")
    logger.info(f"Written TF_BACKEND_URL to .env: {backend_url}")

def main():
    bucket = generate_bucket_name()
    logger.info(f"Provisioning S3 bucket: {bucket}")
    ensure_bucket_exists(bucket)
    enable_versioning(bucket)
    block_public_access(bucket)
    upload_placeholder(bucket, "terraform/", placeholder_path)
    write_backend_env(bucket)
    logger.info("S3 bucket ready for Terraform backend.")

if __name__ == "__main__":
    main()
