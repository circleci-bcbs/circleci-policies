package org

import future.keywords

policy_name["orb_version_check"]

# Simple policy that fires on ALL projects (no project scoping).
# Used to verify the policy engine is actively evaluating configs.

# Hard fail: config must declare a version field
enable_hard contains "check_version_exists"

check_version_exists = reason {
    not input.version
    reason := "Config must declare a version field."
}

# Hard fail: flag configs that do NOT use version 2.1
# This will hard-fail any config with version 2 or missing version.
enable_hard contains "require_version_21"

require_version_21 = reason {
    input.version
    input.version != 2.1
    input.version != "2.1"
    reason := sprintf("Config version must be 2.1 but found %v.", [input.version])
}
