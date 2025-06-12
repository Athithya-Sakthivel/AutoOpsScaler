"""
Schema for Observability stack:
- Prometheus scrape jobs
- Grafana dashboards
- Optional Prometheus Operator integration
"""

from typing import List, Optional, Literal
from pydantic import BaseModel, Field, validator
from enum import Enum

class MonitoringStack(str, Enum):
    PROMETHEUS = "prometheus"
    GRAFANA    = "grafana"

class PrometheusJob(BaseModel):
    name: str = Field(..., description="Unique identifier for the scrape job")
    metrics_path: str = Field(default="/metrics", description="Metrics endpoint path")
    static_configs: List[str] = Field(
        ..., description="List of targets (host:port format)"
    )
    scheme: Literal["http", "https"] = Field(default="http", description="Scrape protocol scheme")

    @validator("name")
    def name_is_valid(cls, v):
        if not v.isidentifier():
            raise ValueError("Prometheus job name must be a valid Python identifier")
        return v

    @validator("static_configs", each_item=True)
    def validate_target_format(cls, v):
        if ":" not in v or not v.split(":")[1].isdigit():
            raise ValueError("Each target must be in host:port format (e.g. 10.0.1.10:9100)")
        return v

class GrafanaDashboard(BaseModel):
    name: str = Field(..., description="Grafana dashboard display name")
    uid: Optional[str] = Field(
        default=None,
        description="Optional unique ID to prevent overwrite conflicts"
    )
    datasource: str = Field(..., description="Name of the Prometheus datasource")
    json_path: Optional[str] = Field(
        default=None,
        description="Path to local dashboard JSON file"
    )

    @validator("uid")
    def uid_is_safe(cls, v):
        if v and not v.isalnum():
            raise ValueError("UID must be alphanumeric if specified")
        return v

class ObservabilityConfig(BaseModel):
    namespace: str = Field(
        default="monitoring",
        description="Kubernetes namespace for monitoring stack"
    )
    enable_prometheus: bool = Field(default=True, description="Deploy Prometheus")
    prometheus_jobs: List[PrometheusJob] = Field(
        default_factory=list,
        description="Static scrape job list for Prometheus"
    )
    enable_grafana: bool = Field(default=True, description="Deploy Grafana")
    grafana_dashboards: List[GrafanaDashboard] = Field(
        default_factory=list,
        description="List of dashboards to pre-provision"
    )
    use_prometheus_operator: bool = Field(
        default=False,
        description="Enable Prometheus Operator CRD-based config"
    )

    @validator("namespace")
    def validate_namespace(cls, v):
        if not v.isidentifier():
            raise ValueError("Namespace must be a valid Python identifier")
        return v
