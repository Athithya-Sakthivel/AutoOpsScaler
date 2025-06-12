"""
Shared enums and constants for AutoOpsScaler infra configuration.
Includes up-to-date AWS regions, region-agnostic types, and
comprehensive CPU/GPU instance types (including Free Tier).
"""

from enum import Enum
from functools import lru_cache
import boto3

# ----------------------------------------------------------------------
# 🌍 AWS Regions — dynamic, live from AWS
# ----------------------------------------------------------------------

@lru_cache()
def get_aws_regions(all_regions: bool = True) -> list[str]:
    ec2 = boto3.client("ec2")
    resp = ec2.describe_regions(AllRegions=all_regions)
    return sorted([r["RegionName"] for r in resp["Regions"]])

def enum_from_list(name: str, values: list[str]) -> Enum:
    members = {v.replace("-", "_").upper(): v for v in values}
    return Enum(name, members)

Region = enum_from_list("Region", get_aws_regions())

# ----------------------------------------------------------------------
# 🧬 Architecture Types
# ----------------------------------------------------------------------

class Architecture(str, Enum):
    X86_64 = "x86_64"
    ARM64 = "arm64"

# ----------------------------------------------------------------------
# ☁️ Capacity Types
# ----------------------------------------------------------------------

class CapacityType(str, Enum):
    ON_DEMAND = "on-demand"
    SPOT = "spot"

# ----------------------------------------------------------------------
# 🏷️ Instance Families
# Subset of common families
# ----------------------------------------------------------------------

class InstanceFamily(str, Enum):
    T2 = "t2"
    T3 = "t3"
    T3A = "t3a"
    M5 = "m5"
    M6I = "m6i"
    C5 = "c5"
    C6G = "c6g"
    R5 = "r5"
    G4DN = "g4dn"
    G5 = "g5"
    P2 = "p2"
    P3 = "p3"
    P4D = "p4d"
    P5 = "p5"
    INF1 = "inf1"
    INF2 = "inf2"
    TRN1 = "trn1"

# ----------------------------------------------------------------------
# 🧩 Instance Types (CPU/GPU/Free Tier)
# ----------------------------------------------------------------------

class InstanceType(str, Enum):
    # Free Tier eligible
    T2_MICRO = "t2.micro"
    T2_SMALL = "t2.small"
    T3_MICRO = "t3.micro"
    T3_SMALL = "t3.small"
    T3A_MICRO = "t3a.micro"
    T3A_SMALL = "t3a.small"

    # General and compute optimized
    M5_LARGE = "m5.large"
    M5_XLARGE = "m5.xlarge"
    M6I_LARGE = "m6i.large"
    M6I_XLARGE = "m6i.xlarge"
    C5_LARGE = "c5.large"
    C5_XLARGE = "c5.xlarge"
    C6G_MEDIUM = "c6g.medium"
    C6G_LARGE = "c6g.large"
    R5_LARGE = "r5.large"
    R5_XLARGE = "r5.xlarge"

    # GPU/accelerated
    G4DN_XLARGE = "g4dn.xlarge"
    G5_XLARGE = "g5.xlarge"
    G5_2XLARGE = "g5.2xlarge"
    P2_XLARGE = "p2.xlarge"
    P3_2XLARGE = "p3.2xlarge"
    P4D_24XLARGE = "p4d.24xlarge"
    P5_48XLARGE = "p5.48xlarge"

    # Inference / ML accelerators
    INF1_XLARGE = "inf1.xlarge"
    INF1_2XLARGE = "inf1.2xlarge"
    INF1_6XLARGE = "inf1.6xlarge"
    INF1_24XLARGE = "inf1.24xlarge"
    INF2_XLARGE = "inf2.xlarge"
    INF2_8XLARGE = "inf2.8xlarge"
    INF2_24XLARGE = "inf2.24xlarge"
    INF2_48XLARGE = "inf2.48xlarge"
    TRN1_2XLARGE = "trn1.2xlarge"

# ----------------------------------------------------------------------
# 🕸️ Subnet Topologies
# ----------------------------------------------------------------------

class SubnetLayout(str, Enum):
    PUBLIC_PRIVATE = "public-private"
    ISOLATED_ONLY = "isolated-only"
    PUBLIC_ONLY = "public-only"

# ----------------------------------------------------------------------
# 👷 Node Role Tags
# ----------------------------------------------------------------------

class NodeRole(str, Enum):
    SYSTEM = "system"
    APP = "app"
    GPU = "gpu"
    SPOT = "spot"
