import os
import logging
import boto3
import botocore.exceptions
from botocore.config import Config
from typing import Optional
from time import sleep
from pydantic import BaseModel, root_validator


MAX_RETRIES = 5
BACKOFF_FACTOR = 2  # exponential


class S3Config(BaseModel):
    bucket_name: Optional[str] = None
    region_name: Optional[str] = "us-east-1"

    @root_validator(pre=True)
    def populate_defaults(cls, values):
        values['bucket_name'] = values.get('bucket_name') or os.getenv("AWS_S3_BUCKET")
        values['region_name'] = values.get('region_name') or os.getenv("AWS_REGION", "us-east-1")
        if not values['bucket_name']:
            raise ValueError("S3 bucket name must be provided via argument or AWS_S3_BUCKET env var")
        return values


class S3Util:
    """
    Utility class for S3 operations with retry, backoff, multipart uploads,
    configurable bucket via env var or parameter.
    """

    def __init__(self, config: S3Config):
        self.bucket_name = config.bucket_name
        self.region_name = config.region_name

        boto_config = Config(
            retries={"max_attempts": MAX_RETRIES, "mode": "standard"},
            region_name=self.region_name,
        )
        self.s3 = boto3.client("s3", config=boto_config)
        self.logger = logging.getLogger(__name__)

    def upload_file(self, file_path: str, key: str, multipart_threshold: int = 8 * 1024 * 1024) -> None:
        file_size = os.path.getsize(file_path)
        self.logger.info(f"Uploading {file_path} to s3://{self.bucket_name}/{key} (size={file_size} bytes)")

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                if file_size > multipart_threshold:
                    self._multipart_upload(file_path, key)
                else:
                    self.s3.upload_file(file_path, self.bucket_name, key)
                self.logger.info(f"Upload succeeded for {key}")
                return
            except botocore.exceptions.ClientError as e:
                self.logger.warning(f"Attempt {attempt} failed for upload of {key}: {e}")
                if attempt == MAX_RETRIES:
                    self.logger.error(f"All {MAX_RETRIES} upload attempts failed for {key}")
                    raise
                backoff = BACKOFF_FACTOR ** attempt
                self.logger.info(f"Retrying after {backoff}s...")
                sleep(backoff)

    def _multipart_upload(self, file_path: str, key: str, chunk_size: int = 8 * 1024 * 1024) -> None:
        self.logger.info(f"Starting multipart upload for {key} with chunk size {chunk_size} bytes")
        try:
            transfer_config = boto3.s3.transfer.TransferConfig(
                multipart_threshold=chunk_size,
                multipart_chunksize=chunk_size,
                use_threads=True,
            )
            self.s3.upload_file(file_path, self.bucket_name, key, Config=transfer_config)
            self.logger.info(f"Multipart upload completed for {key}")
        except Exception as e:
            self.logger.error(f"Multipart upload failed for {key}: {e}")
            raise

    def download_file(self, key: str, dest_path: str) -> None:
        self.logger.info(f"Downloading s3://{self.bucket_name}/{key} to {dest_path}")
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                self.s3.download_file(self.bucket_name, key, dest_path)
                self.logger.info(f"Download succeeded for {key}")
                return
            except botocore.exceptions.ClientError as e:
                self.logger.warning(f"Attempt {attempt} failed for download of {key}: {e}")
                if attempt == MAX_RETRIES:
                    self.logger.error(f"All {MAX_RETRIES} download attempts failed for {key}")
                    raise
                backoff = BACKOFF_FACTOR ** attempt
                self.logger.info(f"Retrying after {backoff}s...")
                sleep(backoff)
