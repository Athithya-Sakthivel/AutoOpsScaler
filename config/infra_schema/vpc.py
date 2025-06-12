# VPC, subnets, and routing configuration schema
from typing import List, Optional
from pydantic import BaseModel, Field, IPvAnyNetwork, validator
from enum import Enum

class SubnetType(str, Enum):
    PUBLIC = "public"
    PRIVATE = "private"

class RoutingStrategy(str, Enum):
    INTERNET_GATEWAY = "igw"
    NAT_GATEWAY = "nat"
    NONE = "none"

class SubnetConfig(BaseModel):
    name: str = Field(..., description="Logical subnet name")
    cidr_block: IPvAnyNetwork = Field(..., description="CIDR block, e.g. 10.0.1.0/24")
    az: str = Field(..., description="Availability Zone, e.g. us-east-1a")
    type: SubnetType = Field(..., description="Subnet visibility: public vs private")

    @validator("cidr_block")
    def check_prefix(cls, v: IPvAnyNetwork) -> IPvAnyNetwork:
        if not 16 <= v.prefixlen <= 28:
            raise ValueError("CIDR prefix length must be between /16 and /28")
        return v

class VPCConfig(BaseModel):
    name: str = Field(..., description="VPC Name tag")
    cidr_block: IPvAnyNetwork = Field(default="10.0.0.0/16", description="Primary VPC CIDR")
    enable_dns_support: bool = Field(default=True)
    enable_dns_hostnames: bool = Field(default=True)
    enable_nat_gateway: bool = Field(default=True, description="Deploy NAT Gateway for private subnet egress")
    subnets: List[SubnetConfig] = Field(..., description="List of subnets in the VPC")
    routing_strategy: RoutingStrategy = Field(default=RoutingStrategy.NAT_GATEWAY, description="Default routing strategy")

    @validator("subnets")
    def require_multi_az(cls, subs: List[SubnetConfig]) -> List[SubnetConfig]:
        azs = {s.az for s in subs}
        if len(azs) < 2:
            raise ValueError("At least two different AZs required")
        return subs

    @validator("subnets")
    def require_public_and_private(cls, subs: List[SubnetConfig]) -> List[SubnetConfig]:
        types = {s.type for s in subs}
        if not ({SubnetType.PUBLIC, SubnetType.PRIVATE} <= types):
            raise ValueError("Subnets must include both PUBLIC and PRIVATE types")
        return subs

    @validator("routing_strategy")
    def validate_nat_gateway_condition(cls, strat: RoutingStrategy, values):
        en_nat = values.get("enable_nat_gateway")
        if strat == RoutingStrategy.NAT_GATEWAY and not en_nat:
            raise ValueError("routing_strategy 'nat' requires enable_nat_gateway=True")
        return strat
