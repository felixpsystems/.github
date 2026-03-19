# GitHub Secrets Setup Guide — Felix Payments (felixpsystems org)

Configure these at: https://github.com/organizations/felixpsystems/settings/secrets/actions

---

## Organization-Level Secrets
> Shared across all repos. Set once.

| Secret Name | Value | Notes |
|-------------|-------|-------|
| `GH_PAT` | GitHub Personal Access Token | Needs `repo`, `read:org`. Used for submodule checkout across org repos. |
| `SSH_PRIVATE_KEY` | Contents of `~/.ssh/devserver_id_rsa` | Used by CI runners to SSH into dev/sandbox servers |
| `REGISTRY_HOST` | `10.10.100.86` | Private Docker registry IP |
| `REGISTRY_USER` | Registry username | Check registry config on 10.10.100.86 |
| `REGISTRY_PASS_QA` | `W5wWcr9t%4jUUQ` | Port :5011 (QA / base images) |
| `REGISTRY_PASS_CLOUD` | `<registry :5007 password>` | Port :5007 (cloud images) — see CREDS.md |
| `REGISTRY_PASS_CLOUD_RELEASE` | `<registry :5008 password>` | Port :5008 (cloud release) — see CREDS.md |
| `REGISTRY_PASS_TERMINAL` | `<registry :5001 password>` | Port :5001 (terminal) — see CREDS.md |
| `REGISTRY_PASS_TERMINAL_RELEASE` | `<registry :5002 password>` | Port :5002 (terminal release) — see CREDS.md |
| `REGISTRY_PASS_PORTAL` | `<registry :5003 password>` | Port :5003 (portal) — see CREDS.md |
| `REGISTRY_PASS_DELIVERY` | `<registry :5005 password>` | Port :5005 (delivery) — see CREDS.md |
| `JIRA_API_TOKEN` | `<Atlassian API token>` | From CREDS.md — expires 2027-01-20 |
| `AWS_ACCESS_KEY_ID` | `<AWS IAM Access Key ID>` | AWS IAM (Terraform) — see CREDS.md |
| `AWS_SECRET_ACCESS_KEY` | `<AWS IAM Secret Access Key>` | AWS IAM (Terraform) — see CREDS.md |

---

## GitHub Environments

Create these at: https://github.com/felixpsystems/<repo>/settings/environments

### `sandbox`
- **No required reviewers** (auto-deploy on push to `develop`)
- Environment secrets:
  - `DEPLOY_HOST`: `205.174.27.120`
  - `DEPLOY_USER`: `lwalle`
  - `DEPLOY_SSH_KEY`: Contents of `~/.ssh/sandbox_id_rsa`

### `uat`
- **Required reviewers**: 1 (tech lead)
- Environment secrets:
  - `DEPLOY_HOST`: `205.174.27.183`
  - `DEPLOY_USER`: `lwalle`
  - `DEPLOY_SSH_KEY`: Contents of `~/.ssh/uat_id_rsa`

### `production`
- **Required reviewers**: 2 (team lead + tech lead)
- **Wait timer**: 5 minutes
- Environment secrets:
  - `DEPLOY_HOST`: `205.174.27.124` (felixcloud1)
  - `DEPLOY_USER`: `lwalle`
  - `DEPLOY_SSH_KEY`: Contents of `~/.ssh/felixcloud1_id_rsa`

---

## Branch Protection Rules

Apply to: `felixkernel`, `felixl3widgets`, `hector`, `felixcommon`, `felix.portal.webapi`

**`develop` branch:**
- ✅ Require pull request before merging (1 reviewer)
- ✅ Require status checks: `build-and-test` (CI workflow)
- ✅ Require branches to be up to date before merging
- ✅ Restrict who can push (only maintainers direct-push)

**`release/**` branches:**
- ✅ Require pull request (2 reviewers)
- ✅ Require status checks: `build-and-test`
- ✅ Restrict force pushes
- ✅ Required environment approval: `uat`
