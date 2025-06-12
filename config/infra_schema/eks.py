# EKS cluster and managed nodegroup configuration schema

from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict
from enum import Enum

from .base_types import (
    InstanceType,
    Architecture,
    CapacityType,
    NodeRole,
    Region,
    get_aws_regions,
)

class KubernetesVersion(str, Enum):
    """Supported Kubernetes minor versions in Amazon EKS (standard & extended)."""
    V1_29 = "1.29"
    V1_30 = "1.30"
    V1_31 = "1.31"
    V1_32 = "1.32"

class NodeGroupConfig(BaseModel):
    name: str = Field(..., description="Unique name for the node group")
    instance_type: InstanceType = Field(..., description="EC2 instance type")
    capacity_type: CapacityType = Field(..., description="on‑demand or spot")
    min_size: int = Field(..., ge=0, description="Minimum number of nodes")
    max_size: int = Field(..., gt=0, description="Maximum number of nodes")
    desired_size: int = Field(..., ge=0, description="Desired starting node count")
    architecture: Architecture = Field(..., description="CPU architecture")
    role: NodeRole = Field(..., description="Logical node role")
    labels: Optional[Dict[str, str]] = Field(default_factory=dict)
    taints: Optional[List[Dict]] = Field(default_factory=list)

    @validator("max_size")
    def max_gt_min(cls, v, values):
        if "min_size" in values and v <= values["min_size"]:
            raise ValueError("max_size must be greater than min_size")
        return v

    @validator("desired_size")
    def desired_in_range(cls, v, values):
        min_s = values.get("min_size")
        max_s = values.get("max_size")
        if min_s is not None and max_s is not None and not (min_s <= v <= max_s):
            raise ValueError("desired_size must be between min_size and max_size")
        return v

class EKSConfig(BaseModel):
    name: str = Field(..., description="EKS cluster name")
    version: KubernetesVersion = Field(..., description="Kubernetes minor version (EKS-supported)")
    region: Region = Field(..., description="AWS region for your cluster")
    enable_irsa: bool = Field(default=True, description="Enable IAM Roles for Service Accounts")
    public_access: bool = Field(default=False, description="EKS public endpoint access enabled")
    private_access: bool = Field(default=True, description="EKS private endpoint access enabled")
    endpoint_whitelist: Optional[List[str]] = Field(
        default_factory=list,
        description="CIDR list allowed access to public API endpoint"
    )
    nodegroups: List[NodeGroupConfig] = Field(..., description="Managed node groups configuration")

    @validator("region")
    def validate_region(cls, v):
        table = get_aws_regions()
        if v.value not in table:
            raise ValueError(f"Region '{v.value}' not supported by AWS account")
        return v
