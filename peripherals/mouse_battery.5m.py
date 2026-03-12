#!/usr/bin/env python3

# <xbar.title>Mouse Battery</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Josh Pomery</xbar.author>
# <xbar.author.github>laoist</xbar.author.github>
# <xbar.desc>Displays MX Master 3 battery level via pmset.</xbar.desc>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

import re
import subprocess
import sys

DEVICE_NAME = 'MX Master 3'

try:
    result = subprocess.run(  # noqa: S603
        ['/usr/bin/pmset', '-g', 'accps'],
        capture_output=True, text=True, timeout=5
    )
    output = result.stdout
except Exception:
    print(":computermouse: | size=10 sfsize=10 symbolize=true")
    sys.exit(0)

match = re.search(
    rf'-{re.escape(DEVICE_NAME)}\s+\(id=\d+\)\s+(\d+)%;',
    output
)

if not match:
    sys.exit(0)

pct = int(match.group(1))

print(f"**{pct}%** :computermouse.fill: | md=true size=11 sfsize=12 symbolize=true")
print("---")
print(f"{DEVICE_NAME}: {pct}%")
