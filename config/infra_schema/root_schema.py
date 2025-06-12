# Top-level InfraConfig combining VPC, EKS, Karpenter, and Observability
from pydantic import BaseModel, Field, root_validator
from typing import Optional

from .vpc import VPCConfig
from .eks import EKSConfig
from .karpenter import KarpenterConfig
from .observability import ObservabilityConfig

class InfraConfig(BaseModel):
    vpc: VPCConfig = Field(..., description="VPC and subnet settings")
    eks: EKSConfig = Field(..., description="EKS cluster and nodegroups")
    karpenter: Optional[KarpenterConfig] = Field(None, description="Karpenter settings")
    observability: Optional[ObservabilityConfig] = Field(None, description="Monitoring settings")

    class Config:
        extra = "forbid"
        validate_assignment = True

    @root_validator
    def enforce_dependencies(cls, values):
        eks_cfg = values.get("eks")
        karp_cfg = values.get("karpenter")
        if karp_cfg and not eks_cfg.enable_irsa:
            raise ValueError("Karpenter requires EKS IRSA to be enabled")
        return values
