"""
Schema for Karpenter controller and provisioner configuration.
Aligns with Karpenter v1beta1 CRD: Provisioner (or NodePool) spec,
using AWS instance types, capacity types, and CPU/GPU distinguishers.
"""

from typing import List, Optional, Union, Dict
from pydantic import BaseModel, Field, validator
from typing_extensions import Literal

from .base_types import Architecture, CapacityType, InstanceType

class TaintConfig(BaseModel):
    key: str = Field(..., description="Taint key")
    value: str = Field(..., description="Taint value")
    effect: Literal["NoSchedule", "NoExecute", "PreferNoSchedule"] = Field(
        ..., description="Kubernetes taint effect"
    )

class ConsolidationPolicy(BaseModel):
    enabled: bool = Field(default=True, description="Enable consolidation of underutilized nodes")
    policy_type: Literal["WhenUnderutilized", "WhenEmpty"] = Field(
        default="WhenUnderutilized",
        description="Consolidation strategy"
    )

class ProvisionerCommon(BaseModel):
    name: str = Field(..., description="Provisioner name")
    capacity_type: CapacityType = Field(..., description="on-demand or spot instances")
    architecture: Architecture = Field(..., description="CPU architecture")
    min_size: int = Field(..., ge=0, description="Minimum number of nodes")
    max_size: int = Field(..., ge=1, description="Maximum number of nodes")
    instance_types: List[InstanceType] = Field(..., description="Allowed EC2 instance types")
    subnets: Optional[List[str]] = Field(
        default=None,
        description="Subnet IDs or tags where nodes may be launched"
    )
    taints: Optional[List[TaintConfig]] = Field(
        default_factory=list,
        description="Kubernetes taints to apply to provisioned nodes"
    )
    consolidation: Optional[ConsolidationPolicy] = Field(
        default=ConsolidationPolicy(),
        description="Node consolidation policy"
    )
    labels: Optional[Dict[str, str]] = Field(
        default_factory=dict,
        description="Kubernetes labels for provisioned nodes"
    )
    requirements: Optional[Dict[str, List[str]]] = Field(
        default_factory=dict,
        description="Additional Affinity/Requirement key-value lists"
    )

    @validator("max_size")
    def max_not_less_than_min(cls, v, values):
        if "min_size" in values and v < values["min_size"]:
            raise ValueError("max_size cannot be less than min_size")
        return v

class CPUProvisionerConfig(ProvisionerCommon):
    type: Literal["cpu"] = Field("cpu", description="Provisioner type: CPU workload")

class GPUProvisionerConfig(ProvisionerCommon):
    type: Literal["gpu"] = Field("gpu", description="Provisioner type: GPU workloads")

class SpotProvisionerConfig(ProvisionerCommon):
    type: Literal["spot"] = Field("spot", description="Provisioner type: Spot-only pool")

class KarpenterControllerConfig(BaseModel):
    enabled: bool = Field(default=True, description="Install the Karpenter controller")
    namespace: str = Field(default="karpenter", description="Controller namespace")
    service_account: str = Field(default="karpenter-controller", description="Service account name")
    irsa_role: Optional[str] = Field(
        default=None,
        description="IAM role (ARN) for IRSA integration"
    )
    replicas: int = Field(default=1, ge=1, description="Karpenter controller replicas")
    version: str = Field(
        default="v0.36.5",
        regex=r"^v\d+\.\d+\.\d+$",
        description="Helm chart version tag (e.g. v0.36.5+)"
    )

class KarpenterConfig(BaseModel):
    controller: KarpenterControllerConfig = Field(..., description="Karpenter controller settings")
    provisioners: List[Union[CPUProvisionerConfig, GPUProvisionerConfig, SpotProvisionerConfig]] = Field(
        ...,
        description="List of Karpenter provisioners (now NodePools)"
    )
