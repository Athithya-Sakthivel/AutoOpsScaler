#!/usr/bin/env python3
"""
Patch applied to config/infra_schema/base_types.py:

--- a/config/infra_schema/base_types.py
+++ b/config/infra_schema/base_types.py
@@
-# AWS Regions
-Region = enum_from_list("Region", get_aws_regions())
+# AWS Regions enum (fallback to empty if no-region error)
+try:
+    Region = enum_from_list("Region", get_aws_regions())
+except NoRegionError:
+    # No AWS_DEFAULT_REGION set or credentials; define empty enum for import safety
+    Region = Enum("Region", {})
"""

import os
import sys
from pathlib import Path

# 1. Apply patch to base_types.py
base = Path(__file__).parent / "config" / "infra_schema" / "base_types.py"
text = base.read_text().splitlines()
out = []
for line in text:
    if line.strip() == "Region = enum_from_list(\"Region\", get_aws_regions())":
        out.extend([
            "# AWS Regions enum (fallback to empty if no-region error)",
            "try:",
            "    Region = enum_from_list(\"Region\", get_aws_regions())",
            "except NoRegionError:",
            "    # No AWS_DEFAULT_REGION set or credentials; define empty enum for import safety",
            "    Region = Enum(\"Region\", {})",
        ])
    else:
        out.append(line)
base.write_text("\n".join(out) + "\n")

# 2. Run import test
ret = os.system(
    'python3 -c "import config.infra_schema; print(\'✅ schemas OK\')"'
)
sys.exit(ret)
