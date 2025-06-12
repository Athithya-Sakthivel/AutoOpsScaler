# VPC, subnets, and routing configuration schema
from typing import List, Optional, Literal
from pydantic import BaseModel, Field, IPvAnyNetwork, validator
from enum import Enum

class SubnetType(str, Enum):
    PUBLIC  = "public"
    PRIVATE = "private"

class RoutingStrategy(str, Enum):
    INTERNET_GATEWAY = "igw"
    NAT_GATEWAY      = "nat"
    NONE             = "none"

class SubnetConfig(BaseModel):
    name: str = Field(..., description="Subnet logical name")
    cidr_block: IPvAnyNetwork = Field(..., description="CIDR block")
    az: str = Field(..., description="Availability Zone")
    type: SubnetType = Field(...)

    @validator("cidr_block")
    def check_prefix(cls, v):
        if v.prefixlen < 16 or v.prefixlen > 28:
            raise ValueError("CIDR prefix must be between /16 and /28")
        return v

class VPCConfig(BaseModel):
    name: str = Field(..., description="VPC name tag")
    cidr_block: IPvAnyNetwork = Field(default="10.0.0.0/16")
    enable_dns_support: bool = Field(default=True)
    enable_dns_hostnames: bool = Field(default=True)
    enable_nat_gateway: bool = Field(default=True)
    subnets: List[SubnetConfig] = Field(...)
    routing_strategy: RoutingStrategy = Field(default=RoutingStrategy.NAT_GATEWAY)

    @validator("subnets")
    def require_multi_az(cls, subs):
        azs = {s.az for s in subs}
        if len(azs) < 2:
            raise ValueError("At least two AZs required")
        return subs

    @validator("subnets")
    def require_public_and_private(cls, subs):
        types = {s.type for s in subs}
        if not ({SubnetType.PUBLIC, SubnetType.PRIVATE} <= types):
            raise ValueError("Must include both public and private subnets")
        return subs
