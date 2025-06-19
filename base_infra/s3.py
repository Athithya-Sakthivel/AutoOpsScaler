#!/usr/bin/env python3
"""
utils/create_s3_bucket_structure.py

Creates an S3 bucket with folder structure:
 - data/raw/<timestamp>/
 - pulumi/

Uses the default region from `aws configure`.
Persists the structure with placeholder files uploaded from vagrant/tmp/.

"""

# ignore Import "boto3" could not be resolvedPylancereportMissingImports warnings

import boto3
import botocore
from datetime import datetime
from pathlib import Path

# === Config ===
BUCKET_NAME = "autoopsscaler-bucket"  # Replace with your desired S3 bucket name
TMP_DIR = Path("vagrant/tmp/")
FOLDERS_TO_CREATE = [
    f"data/raw/{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}/",
    "pulumi/"
]
PLACEHOLDER_FILENAME = ".keep"  # Placeholder file to force folder persistence in S3

# === Ensure local tmp dir exists ===
TMP_DIR.mkdir(parents=True, exist_ok=True)

# === Create placeholder file ===
placeholder_path = TMP_DIR / PLACEHOLDER_FILENAME
if not placeholder_path.exists():
    placeholder_path.write_text("This file ensures the folder exists in S3.\n")

# === Use session region configured with `aws configure` ===
session = boto3.session.Session()
region = session.region_name

if not region:
    raise RuntimeError("AWS region not configured. Run `aws configure` first.")

s3_client = session.client("s3")

# === Ensure bucket exists or create it ===
def ensure_bucket_exists(bucket_name: str, region: str):
    try:
        s3_client.head_bucket(Bucket=bucket_name)
        print(f"[INFO] Bucket '{bucket_name}' already exists.")
    except botocore.exceptions.ClientError as e:
        error_code = int(e.response["Error"]["Code"])
        if error_code == 404:
            print(f"[INFO] Bucket '{bucket_name}' does not exist. Creating...")
            if region == "us-east-1":
                s3_client.create_bucket(Bucket=bucket_name)
            else:
                s3_client.create_bucket(
                    Bucket=bucket_name,
                    CreateBucketConfiguration={"LocationConstraint": region}
                )
            print(f"[SUCCESS] Bucket '{bucket_name}' created.")
        else:
            raise

# === Upload placeholder files ===
def upload_placeholder(bucket_name: str, folder_path: str, placeholder_file: Path):
    key = folder_path.rstrip("/") + "/" + placeholder_file.name
    try:
        s3_client.upload_file(str(placeholder_file), bucket_name, key)
        print(f"[OK] Created folder '{folder_path}' with placeholder.")
    except Exception as e:
        print(f"[ERROR] Failed to upload placeholder to '{folder_path}': {e}")
        raise

# === Main ===
def main():
    ensure_bucket_exists(BUCKET_NAME, region)
    for folder in FOLDERS_TO_CREATE:
        upload_placeholder(BUCKET_NAME, folder, placeholder_path)

if __name__ == "__main__":
    main()
