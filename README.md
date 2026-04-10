# CircleCI Config Policies

Organization-level [config policies](https://circleci.com/docs/guides/config-policies/config-policy-management-overview/) for the BCBSM CircleCI org. These policies enforce security and governance standards across all projects.

## How It Works

```
Developer pushes config change
        │
        ▼
CircleCI evaluates config against org policies
        │
        ├── PASS         → Pipeline runs normally
        ├── SOFT_FAIL    → Pipeline runs with warnings in the UI
        └── HARD_FAIL    → Pipeline is blocked until config is fixed
```

Policies are written in [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) (Open Policy Agent) and managed through this repository. Changes are tested automatically on every push and deployed to the org on merge to `main`.

## Policies

### `demo_version_check`

Ensures all CircleCI configs across the org use config version 2.1, which is required for pipeline parameters, orbs, and reusable config features.

| Rule | Enforcement | Description |
|---|---|---|
| `require_version_2_1` | Hard fail | Config must specify `version: 2.1` |

**Scoped to:** All projects (org-wide)

### `orb_version_check`

Ensures CircleCI configs use config version 2.1. Same rule as `demo_version_check`, scoped to a specific project.

| Rule | Enforcement | Description |
|---|---|---|
| `require_version_2_1` | Hard fail | Config must specify `version: 2.1` |

**Scoped to:**
- `bcn-webapp` (`2558f172-e538-427c-828a-50973c4536a9`)

## Pipeline

The CI/CD pipeline for this repo runs automatically:

| Workflow | Trigger | What it does |
|---|---|---|
| `test-policies` | Every push | Runs `circleci policy test`, validates against sample configs |
| `deploy-policies` | Merge to `main` | Tests, then pushes the policy bundle to the org via `circleci policy push` |

The deploy job uses the `circleci-api` context which contains `CIRCLECI_CLI_TOKEN` for authentication.

## Local Development

### Run tests

```bash
circleci policy test ./policies -v
```

### Evaluate a config against policies

```bash
circleci policy decide ./policies --input /path/to/config.yml --no-compile
```

For configs without `_compiled_` metadata, add it manually or use `--metafile`:

```bash
circleci policy eval ./policies --input /path/to/config.yml --no-compile
```

### Diff local vs deployed policies

```bash
circleci policy diff ./policies --owner-id 32bb0be4-8e27-4ec2-9c02-5f09237d2ac4
```

### Push policies manually

```bash
circleci policy push ./policies --owner-id 32bb0be4-8e27-4ec2-9c02-5f09237d2ac4
```

## Adding a New Policy

1. Create a new `.rego` file in the `policies/` directory
2. Follow the [CircleCI policy format](https://circleci.com/docs/guides/config-policies/config-policy-management-overview/#rules): `package org`, `policy_name`, `enable_hard`/`enable_soft`, rule definitions
3. Add a test file (`_test.yaml`) with test cases
4. Run `circleci policy test ./policies -v` locally
5. Open a PR — the pipeline will test automatically
6. Merge to `main` — the pipeline deploys to the org

> **Docs**: [Config Policies Overview](https://circleci.com/docs/guides/config-policies/config-policy-management-overview/) | [Test Policies](https://circleci.com/docs/guides/config-policies/test-config-policies/) | [CLI Reference](https://circleci.com/docs/guides/toolkit/how-to-use-the-circleci-local-cli/#config-policy-management)

## Repository Structure

```
circleci-policies/
├── .circleci/
│   └── config.yml                              # CI/CD pipeline for testing and deploying policies
├── policies/
│   ├── demo_version_check.rego                 # Org-wide config version 2.1 policy
│   ├── demo_version_check_test.yaml            # Policy tests
│   ├── orb_version_check.rego                  # bcn-webapp config version 2.1 policy
│   └── orb_version_check_test.yaml             # Policy tests
└── README.md
```
