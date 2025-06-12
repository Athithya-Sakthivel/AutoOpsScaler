#!/usr/bin/env python3
import os, sys
from pathlib import Path

# Apply patch (idempotent)
BT = Path("config/infra_schema/base_types.py")
lines = BT.read_text().splitlines()
out = []
for L in lines:
    if L.strip().startswith("Region = enum_from_list"):
        out += [
            "# AWS Regions enum (fallback to empty if no-region error)",
            "try:",
            "    Region = enum_from_list(\"Region\", get_aws_regions())",
            "except NoRegionError:",
            "    Region = Enum(\"Region\", {})",
        ]
    else:
        out.append(L)
BT.write_text("\n".join(out)+"\n")

# Run import test
code = os.system('python3 -c "import config.infra_schema; print(\'✅ schemas OK\')"')
sys.exit(code)
