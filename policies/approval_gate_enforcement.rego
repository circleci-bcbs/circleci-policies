package org

import future.keywords

# =============================================================================
# Approval Gate Enforcement Policy
# =============================================================================
#
# Ensures that any workflow with an approval gate also includes an
# approval-gates/validate_approver job from the cci-labs/approval-gates
# orb. This prevents someone from removing the validation step and
# bypassing the authorized approvers check.
#
# Scoped to specific projects via target_project_ids.
#
# Docs: https://circleci.com/docs/guides/config-policies/config-policy-management-overview/
# Orb:  https://github.com/CircleCI-Labs/approval-gates-orb
# =============================================================================

policy_name["approval_gate_enforcement"]

# ===================== USER CONFIGURATION =====================

# CircleCI project UUIDs (Project Settings > Overview).
target_project_ids := {
    "2558f172-e538-427c-828a-50973c4536a9", # bcn-webapp
    "8dee0f6e-2228-4a03-93f7-56742458b49b", # uipath-exception-mailer
}

# The orb job key that must appear after approval gates.
required_validation_job := "approval-gates/validate_approver"

# ================ END USER CONFIGURATION =====================

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Determine if this pipeline belongs to a target project.
is_target_project if {
    input._compiled_.meta.project_id in target_project_ids
}

# Extract the job key from a workflow job entry.
# Workflow jobs can be a plain string or a single-key object.
get_job_key(entry) := entry if is_string(entry)

get_job_key(entry) := key {
    is_object(entry)
    count(entry) == 1
    some key, _ in entry
}

# Extract the job config (the value side of the object).
get_job_config(entry) := {} if is_string(entry)

get_job_config(entry) := config {
    is_object(entry)
    count(entry) == 1
    some _, config in entry
}

# Check if a workflow has at least one approval-type job.
has_approval_gate(workflow) if {
    some entry in workflow.jobs
    config := get_job_config(entry)
    config.type == "approval"
}

# Check if a workflow has at least one approval-gates/validate_approver job.
has_validation_job(workflow) if {
    some entry in workflow.jobs
    key := get_job_key(entry)
    key == required_validation_job
}

# Collect the names of all approval jobs in a workflow.
approval_job_names(workflow) := names {
    names := {name |
        some entry in workflow.jobs
        config := get_job_config(entry)
        config.type == "approval"
        name := get_job_key(entry)
    }
}

# Check if any job directly requires an approval job (skipping validation).
# Returns the job key and the approval job it requires.
job_requires_approval_directly(workflow) := {result |
    some entry in workflow.jobs
    key := get_job_key(entry)
    config := get_job_config(entry)

    # Not an approval job itself
    not config.type == "approval"

    # Not the validation job
    key != required_validation_job

    # Has a requires list
    some req in config.requires

    # One of the requires is an approval job name
    approval_names := approval_job_names(workflow)
    req in approval_names

    result := sprintf("%s requires approval job '%s' directly", [key, req])
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------

# Rule 1: Workflows with approval gates must include the validation orb job.
enable_hard contains "require_approval_validation"

require_approval_validation[wf_name] := reason {
    is_target_project
    some wf_name, wf_config in input.workflows
    wf_name != "version"  # skip the version key
    has_approval_gate(wf_config)
    not has_validation_job(wf_config)
    reason := sprintf(
        "Workflow '%s' has approval gates but no %s job. Add the cci-labs/approval-gates orb to validate who approved the deployment.",
        [wf_name, required_validation_job]
    )
}

# Rule 2: The cci-labs/approval-gates orb must be declared in the config.
enable_hard contains "require_approval_gates_orb"

require_approval_gates_orb := reason {
    is_target_project
    # Check if any workflow has an approval gate
    some wf_name, wf_config in input.workflows
    wf_name != "version"
    has_approval_gate(wf_config)
    # But the orb is not declared
    not input.orbs["approval-gates"]
    reason := "Config uses approval gates but does not declare the cci-labs/approval-gates orb. Add it to ensure approver identity is validated."
}

# Rule 3 (soft): Deploy jobs should include deploy markers for tracking.
# This is a recommendation, not a requirement — soft fail produces a warning
# in the UI without blocking the pipeline.
enable_soft contains "recommend_deploy_markers"

recommend_deploy_markers[job_name] := reason {
    is_target_project
    some job_name, job_config in input._compiled_.jobs
    contains(lower(job_name), "deploy")
    not job_has_deploy_marker(job_config)
    reason := sprintf(
        "Deploy job '%s' does not include deploy marker commands (circleci run release plan/update). Adding deploy markers enables deployment tracking and version promotion in the Deploys UI.",
        [job_name]
    )
}

# Helper: check if a job's steps include a deploy marker command
job_has_deploy_marker(job_config) if {
    some step in job_config.steps
    is_object(step)
    step.run.command
    contains(step.run.command, "circleci run release")
}

job_has_deploy_marker(job_config) if {
    some step in job_config.steps
    is_object(step)
    is_string(step.run)
    contains(step.run, "circleci run release")
}
