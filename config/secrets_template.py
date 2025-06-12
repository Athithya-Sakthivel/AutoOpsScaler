# Secrets scaffolding for Vault or CI-safe injection

# config/secrets_template.py

"""
WARNING:
- DO NOT PUT REAL SECRETS HERE.
- This is a static scaffold to document what secret keys are required per environment.
- Use Vault, AWS Secrets Manager, or CI-injected env vars for actual secrets.

Structure:
{
    "<env_name>": {
        "<secret_key>": "REQUIRED",  # Leave value as string 'REQUIRED' to indicate placeholders
        ...
    }
}
"""

SECRETS_TEMPLATE = {
    "dev": {
        "aws_access_key_id": "REQUIRED",
        "aws_secret_access_key": "REQUIRED",
        "s3_bucket_name": "REQUIRED",
        "github_token": "REQUIRED",
        "vault_token": "REQUIRED",
    },
    "prod": {
        "aws_access_key_id": "REQUIRED",
        "aws_secret_access_key": "REQUIRED",
        "s3_bucket_name": "REQUIRED",
        "github_token": "REQUIRED",
        "vault_token": "REQUIRED",
        "pagerduty_api_key": "REQUIRED",
    }
}
