package org

import future.keywords

policy_name["orb_version_check"]

# Scoped to bcn-webapp only so it doesn't affect other projects.
target_project_id := "2558f172-e538-427c-828a-50973c4536a9" # bcn-webapp

is_target if {
    input._compiled_.meta.project_id == target_project_id
}

# Hard fail: config must use version 2.1
enable_hard contains "require_version_21"

require_version_21 = reason {
    is_target
    input.version
    input.version != 2.1
    input.version != "2.1"
    reason := sprintf("Config version must be 2.1 but found %v.", [input.version])
}
