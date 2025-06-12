# EKS cluster and managed nodegroup configuration schema
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Literal

from .base_types import InstanceType, Architecture, CapacityType, NodeRole, get_aws_regions

class NodeGroupConfig(BaseModel):
    name: str = Field(..., description="Unique name for the node group")
    instance_type: InstanceType = Field(..., description="EC2 instance type")
    capacity_type: CapacityType = Field(..., description="on-demand or spot")
    min_size: int = Field(..., ge=0, description="Minimum number of nodes")
    max_size: int = Field(..., gt=0, description="Maximum number of nodes")
    desired_size: int = Field(..., ge=0, description="Desired starting node count")
    architecture: Architecture = Field(..., description="CPU architecture")
    role: NodeRole = Field(..., description="Logical node role")
    labels: Optional[Dict[str, str]] = Field(default_factory=dict)
    taints: Optional[List[Dict]]       = Field(default_factory=list)

    @validator("max_size")
    def max_gt_min(cls, v, values):
        if values.get("min_size") is not None and v <= values["min_size"]:
            raise ValueError("max_size must be greater than min_size")
        return v

    @validator("desired_size")
    def desired_in_range(cls, v, values):
        min_s = values.get("min_size"); max_s = values.get("max_size")
        if min_s is not None and max_s is not None and not (min_s <= v <= max_s):
            raise ValueError("desired_size must be between min_size and max_size")
        return v

class EKSConfig(BaseModel):
    name: str = Field(..., description="EKS cluster name")
    version: Literal["1.28", "1.29", "1.30"] = Field(..., description="Kubernetes version")
    region: str = Field(..., description="AWS region")
    enable_irsa: bool = Field(default=True)
    public_access: bool = Field(default=False)
    private_access: bool = Field(default=True)
    endpoint_whitelist: Optional[List[str]] = Field(default_factory=list)
    nodegroups: List[NodeGroupConfig] = Field(...)

    @validator("region")
    def validate_region(cls, v):
        allowed = get_aws_regions()
        if v not in allowed:
            raise ValueError(f"Region '{v}' not in {allowed}")
        return v
