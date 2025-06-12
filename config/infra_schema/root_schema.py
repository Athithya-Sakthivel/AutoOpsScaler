"""
Top-level schema for full infrastructure config:
- VPC
- EKS
- Karpenter (optional)
- Observability (optional)
"""

from typing import Optional
from pydantic import BaseModel, Field, root_validator

from .vpc import VPCConfig
from .eks import EKSConfig
from .karpenter import KarpenterConfig
from .observability import ObservabilityConfig

class InfraConfig(BaseModel):
    vpc: VPCConfig = Field(..., description="VPC configuration including subnets and routing")
    eks: EKSConfig = Field(..., description="Amazon EKS cluster and managed nodegroups")
    karpenter: Optional[KarpenterConfig] = Field(
        default=None, description="Karpenter controller and provisioner settings"
    )
    observability: Optional[ObservabilityConfig] = Field(
        default=None, description="Prometheus + Grafana observability stack"
    )

    class Config:
        extra = "forbid"
        validate_assignment = True

    @root_validator
    def enforce_dependency_rules(cls, values):
        eks_cfg = values.get("eks")
        karp_cfg = values.get("karpenter")
        if karp_cfg and not eks_cfg.enable_irsa:
            raise ValueError("Karpenter requires IRSA (IAM Roles for Service Accounts) to be enabled in EKS config")
        return values
