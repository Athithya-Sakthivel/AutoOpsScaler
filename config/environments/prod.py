# Prod environment overrides with resource limits

from config.infra_schema import InfraConfig
from config.infra_schema.base_types import CapacityType, InstanceClass, Arch

config = InfraConfig(
    vpc=dict(
        cidr_block="10.20.0.0/16",
        public_subnet_cidrs=["10.20.1.0/24", "10.20.2.0/24"],
        private_subnet_cidrs=["10.20.101.0/24", "10.20.102.0/24"],
        nat_gateway_enabled=True,
        availability_zones=["ap-south-1a", "ap-south-1b", "ap-south-1c"],
    ),

    eks=dict(
        cluster_name="autoprod-eks",
        version="1.29",
        enable_irsa=True,
        nodegroups=[
            dict(
                name="system-ng",
                instance_types=["t3.medium", "m5.large"],
                min_size=3,
                max_size=6,
                desired_capacity=4,
                labels={"role": "system"},
                taints=[],
            )
        ]
    ),

    karpenter=dict(
        controller_version="v0.34.1",
        cpu_provisioner=dict(
            name="cpu-provisioner",
            capacity_type=CapacityType.ON_DEMAND,
            instance_types=["t3", "m5"],
            architectures=[Arch.X86_64],
            zones=["ap-south-1a", "ap-south-1b", "ap-south-1c"],
            ttl_seconds_after_empty=60,
            consolidation_enabled=True
        ),
        gpu_provisioner=dict(
            name="gpu-provisioner",
            capacity_type=CapacityType.ON_DEMAND,
            instance_types=["g4dn.xlarge", "g4dn.2xlarge"],
            architectures=[Arch.X86_64],
            zones=["ap-south-1a", "ap-south-1b"],
            ttl_seconds_after_empty=300
        ),
        spot_provisioner=dict(
            name="spot-provisioner",
            capacity_type=CapacityType.SPOT,
            instance_types=["t3", "m5"],
            architectures=[Arch.X86_64],
            zones=["ap-south-1a", "ap-south-1b", "ap-south-1c"],
            ttl_seconds_after_empty=90,
            max_price="0.08"
        )
    ),

    observability=dict(
        prometheus=dict(
            enabled=True,
            scrape_interval="15s",
            extra_scrape_configs_secret="additional-scrape-configs",
        ),
        grafana=dict(
            enabled=True,
            admin_user="admin",
            admin_password_from_env="GRAFANA_ADMIN_PASSWORD",
            additional_data_sources=[{
                "name": "loki",
                "type": "loki",
                "url": "http://loki.loki.svc.cluster.local:3100",
                "access": "proxy",
                "editable": True
            }],
            dashboards_path="base_infra/observability/dashboards/",
        )
    )
)
