package org

import future.keywords

policy_name["demo_version_check"]

# Demo policy: blocks any config not using version 2.1.
# Unscoped — applies to all projects in the org.
# Delete this file or remove from the bundle after the demo.
enable_hard contains "demo_require_version_21"

demo_require_version_21 = reason {
    input.version
    input.version != 2.1
    input.version != "2.1"
    reason := sprintf("Policy violation: config version must be 2.1 but found %v.", [input.version])
}
