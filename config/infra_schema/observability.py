# Prometheus scrape jobs and Grafana dashboard configuration schema
from typing import List, Optional, Literal, Dict
from pydantic import BaseModel, Field, validator
from enum import Enum

class MonitoringStack(str, Enum):
    PROMETHEUS = "prometheus"
    GRAFANA    = "grafana"

class PrometheusJob(BaseModel):
    name: str = Field(..., description="Identifier for scrape job")
    metrics_path: str = Field(default="/metrics")
    static_configs: List[str] = Field(..., description="Targets (host:port)")
    scheme: Literal["http", "https"] = Field(default="http")

    @validator("name")
    def valid_identifier(cls, v):
        if not v.isidentifier():
            raise ValueError("Job name must be a valid identifier")
        return v

    @validator("static_configs", each_item=True)
    def requires_port(cls, v):
        if ":" not in v:
            raise ValueError("Must include port (e.g. 10.0.0.5:9100)")
        return v

class GrafanaDashboard(BaseModel):
    name: str = Field(..., description="Dashboard title")
    uid: Optional[str]
    datasource: str = Field(..., description="Prometheus datasource name")
    json_path: Optional[str]

class ObservabilityConfig(BaseModel):
    namespace: str = Field(default="monitoring")
    enable_prometheus: bool = Field(default=True)
    prometheus_jobs: List[PrometheusJob] = Field(default_factory=list)
    enable_grafana: bool = Field(default=True)
    grafana_dashboards: List[GrafanaDashboard] = Field(default_factory=list)
    use_prometheus_operator: bool = Field(default=False)

    @validator("namespace")
    def namespace_is_valid(cls, v):
        if not v.isidentifier():
            raise ValueError("Namespace must be a valid identifier")
        return v
