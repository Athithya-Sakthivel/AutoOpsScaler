# Karpenter controller + provisioner configuration schema
from typing import List, Optional, Union, Literal, Dict
from pydantic import BaseModel, Field, validator

from .base_types import Architecture, CapacityType, InstanceType

class TaintConfig(BaseModel):
    key: str
    value: str
    effect: Literal["NoSchedule", "NoExecute", "PreferNoSchedule"]

class ConsolidationPolicy(BaseModel):
    enabled: bool = True
    policy_type: Literal["WhenUnderutilized", "WhenEmpty"] = "WhenUnderutilized"

class ProvisionerCommon(BaseModel):
    name: str
    capacity_type: CapacityType
    architecture: Architecture
    min_size: int = Field(..., ge=0)
    max_size: int = Field(..., ge=1)
    instance_types: List[InstanceType]
    subnets: Optional[List[str]] = None
    taints: Optional[List[TaintConfig]] = []
    consolidation: Optional[ConsolidationPolicy] = ConsolidationPolicy()
    labels: Optional[Dict[str, str]] = {}
    requirements: Optional[Dict[str, List[str]]] = {}

    @validator("max_size")
    def max_ge_min(cls, v, values):
        if values.get("min_size") is not None and v < values["min_size"]:
            raise ValueError("max_size cannot be less than min_size")
        return v

class CPUProvisionerConfig(ProvisionerCommon):
    type: Literal["cpu"] = "cpu"

class GPUProvisionerConfig(ProvisionerCommon):
    type: Literal["gpu"] = "gpu"

class SpotProvisionerConfig(ProvisionerCommon):
    type: Literal["spot"] = "spot"

class KarpenterControllerConfig(BaseModel):
    enabled: bool = Field(default=True)
    namespace: str = Field(default="karpenter")
    service_account: str = Field(default="karpenter-controller")
    irsa_role: Optional[str] = None
    replicas: int = Field(default=1, ge=1)
    version: str = Field(default="v0.36.1")

class KarpenterConfig(BaseModel):
    controller: KarpenterControllerConfig
    provisioners: List[Union[CPUProvisionerConfig, GPUProvisionerConfig, SpotProvisionerConfig]]
