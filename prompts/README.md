# Implementing a Datadog Monitoring Pipeline with Terraform on AWS

Complete observability pipeline on AWS infrastructure using Terraform as IaC and Datadog as the monitoring platform. The system deploys two EC2 instances (backend and frontend) with the Datadog agent installed, and a metrics dashboard.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Changes made](#changes-made)
3. [Prompts used](#prompts-used)
4. [Dashboard in Datadog](#dashboard-in-datadog)
5. [Setup and configuration](#setup-and-configuration)
6. [Challenges encountered](#challenges-encountered)

---

## Architecture

```
Internet
   │
   ├── SG frontend (22, 3000) ──► EC2 t3.micro (lti-project-frontend)
   │                                    │  Docker + React app :3000
   │                                    └── Datadog Agent v7 ──► datadoghq.eu
   │
   └── SG backend (22, 8080) ──► EC2 t3.micro (lti-project-backend)
                                       │  Docker + Express API :8080
                                       └── Datadog Agent v7 ──► datadoghq.eu

S3 Bucket (lti-project-code-bucket-xvb)
   ├── backend.zip
   └── frontend.zip

Datadog (EU)
   └── Dashboard: LTI Project - EC2 Monitoring Dashboard
         └── Metrics: CPU, Network In/Out, Disk R/W, Agent status
```

### Terraform resources deployed

| Resource | Detail |
|---|---|
| S3 Bucket | `lti-project-code-bucket-xvb` with `backend.zip` and `frontend.zip` |
| EC2 backend | `t3.micro`, port `8080`, Amazon Linux 2 + Docker |
| EC2 frontend | `t3.micro`, port `3000`, Amazon Linux 2 + Docker |
| IAM Role | S3 access from EC2 |
| Security Groups | SSH (22) and application ports (8080/3000) |
| Datadog Dashboard | Agent metrics per host (`tf/datadog.tf`) |


---

## Changes made

### 1. Datadog provider in Terraform (`tf/main.tf`, `tf/variables.tf`)

Added the Datadog provider pointing to the EU site, with keys declared as variables without hardcoded values. File distribution following best practices:

- `tf/variables.tf` — type declarations without values
- `tf/terraform.tfvars` — real values, gitignored
- `tf/terraform.tfvars.example` — committed template

### 2. Datadog agent on EC2 (`tf/scripts/`)

Installation of the Datadog agent v7 on both instances before starting Docker. The `DD_API_KEY` is injected at deploy time via `templatefile()` instead of being hardcoded in the script.

```bash
DD_API_KEY="${datadog_api_key}" DD_SITE="datadoghq.eu" DD_AGENT_MAJOR_VERSION=7 \
  bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
systemctl start datadog-agent
```

### 3. Monitoring dashboard (`tf/datadog.tf`)

Dashboard with 6 widgets using Datadog agent metrics (`system.*`):

| Widget | Query |
|---|---|
| CPU Utilization | `avg:system.cpu.user{*} by {host}` |
| Network In | `avg:system.net.bytes_rcvd{*} by {host}` |
| Network Out | `avg:system.net.bytes_sent{*} by {host}` |
| Disk Read Ops | `avg:system.io.r_s{*} by {host}` |
| Disk Write Ops | `avg:system.io.w_s{*} by {host}` |
| Agent Running | `avg:datadog.agent.running{*} by {host}` |

---

## Prompts used

The main prompts used to generate the Terraform code are documented in:

➡ [datadog-aws-prompts.md](./datadog-aws-prompts.md)

Summary of prompts:

| Prompt | Goal |
|---|---|
| Prompt 0 | Repository analysis and project understanding |
| Prompt 1 | Configure the Datadog provider with variable best practices |
| Prompt 2 | Install the Datadog agent v7 on the EC2 instances |
| Prompt 3 | Monitoring dashboard with agent metrics |

---

## Dashboard in Datadog

### EC2 Monitoring Dashboard

Complete dashboard with CPU, network and disk metrics grouped by host:

![EC2 Monitoring Dashboard](images/EC2%20Monitoring%20Dashboard.png)

### CPU Utilization detail

Detailed view of the CPU metric per instance:

![CPU Utilization Detail](images/CPU%20Utilization%20Detail.png)

### Host view

EC2 instances registered in Datadog with the active agent:

![Host View](images/Host%20View.png)

---

## Setup and configuration

### Prerequisites

```bash
brew install terraform awscli

terraform --version   # >= 1.5.7
aws --version
zip --version
```

### AWS configuration

#### 1. Create credentials in IAM

1. AWS Console → **IAM** → **Users** → your user
2. **Security credentials** tab → **Create access key** → choose **CLI**
3. Required permissions: `AmazonEC2FullAccess`, `AmazonS3FullAccess`, `IAMFullAccess`
4. Copy the `Access Key ID` and the `Secret Access Key` — they are only shown once

#### 2. Configure the CLI

```bash
aws configure
```

| Field | Value |
|---|---|
| AWS Access Key ID | `AKIA...` |
| AWS Secret Access Key | `xxxx...` |
| Default region name | `us-east-1` |
| Default output format | `json` |

#### 3. Verify access

```bash
aws sts get-caller-identity
```

### Datadog configuration

#### 1. Obtain the keys

1. **Organization Settings → API Keys** → copy the **Key** value (not the Key ID)
2. **Organization Settings → Application Keys** → copy the **Key** value

> The account must be on `datadoghq.eu`. Verify the URL when logged in.

#### 2. Configure the keys

Copy the template and fill in your real values:

```bash
cp tf/terraform.tfvars.example tf/terraform.tfvars
# Edit terraform.tfvars with your real keys
```

```hcl
# tf/terraform.tfvars (gitignored)
datadog_api_url = "https://api.datadoghq.eu"
datadog_api_key = "your_secret_api_key_value"
datadog_app_key = "your_app_key_value"
```

### Deployment with Terraform

```bash
# 1. Generate the code ZIPs (from the project root)
./generar-zip.sh

# 2. Initialize Terraform (first time only)
cd tf/
terraform init

# 3. Review the changes
terraform plan

# 4. Deploy
terraform apply   # type "yes" to confirm
```

### Verify the deployment

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lti-project-backend,lti-project-frontend" \
  --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value|[0],PublicIpAddress,State.Name]" \
  --output table
```

### Destroy the infrastructure when finished

```bash
cd tf/
terraform destroy   # type "yes" to confirm
```

---

## Challenges encountered

### Challenge 1 — Secrets exposed in version control

**Problem:** several files containing secrets were committed to the repo. In a public repository any attacker or automated scanner can retrieve them from the history even after the files are removed.

**Solution:**

```bash
# .gitignore — corrected/added lines
**/.env
**/terraform.tfvars
**/terraform.tfstate
**/terraform.tfstate.backup
**/.terraform.tfstate.lock.info

# Remove files from the index without deleting them from disk
git rm --cached .env backend/.env tf/terraform.tfstate tf/terraform.tfstate.backup
```

> In production, `tfstate` should be stored in a remote S3 + DynamoDB backend to avoid team conflicts and protect the state.

**Inventory of secrets compromised in the original repo:**

| Secret | File | Solution |
|---|---|---|
| `DD_API_KEY='76cd5e07...'` | `tf/scripts/*.sh` | Inject via `templatefile()` |
| `DB_PASSWORD=D1ymf8wy...` | `.env`, `backend/.env` | Fix `.gitignore` |
| Infrastructure IDs and ARNs | `tf/terraform.tfstate` | Add to `.gitignore` |

---

### Challenge 2 — Confusion between Datadog API Key and App Key

**Problem:** Datadog has two types of credentials in different sections of the UI, with fields that can be easily confused:

| Terraform Variable | Section in Datadog | Field to copy |
|---|---|---|
| `datadog_api_key` | Organization Settings → **API Keys** | **Key** (secret value, not the Key ID) |
| `datadog_app_key` | Organization Settings → **Application Keys** | **Key** |

**Common mistake:** copying the `Key ID` from API Keys instead of the secret value, or using keys from **Personal Settings** instead of **Organization Settings**.

---

### Challenge 3 — `DD_SITE` pointing to the wrong region

**Problem:** the original scripts had `DD_SITE="datadoghq.com"` (US1) but the Datadog account is on EU. The agent was sending metrics to the wrong site → empty data in the dashboard.

**Solution:** align scripts and provider to the same site:

```bash
DD_SITE="datadoghq.eu"                # in the user_data scripts
api_url = "https://api.datadoghq.eu"  # in the Terraform provider
```

---

### Challenge 4 — Datadog API key exposed in EC2 user-data

**Problem:** although the `DD_API_KEY` is no longer hardcoded in source code, AWS stores it in plain text as the instance `user_data`, accessible from within the instance:

```bash
curl http://169.254.169.254/latest/user-data
```

**Current solution:** injection via `templatefile()` — removes exposure in source code but not in instance metadata.

**Recommended production solution (not applied in this exercise):** AWS Secrets Manager:

```bash
DD_API_KEY=$(aws secretsmanager get-secret-value \
  --secret-id datadog/api-key \
  --query SecretString --output text)
```

---

### Challenge 5 — EC2 instance types not eligible for Free Tier

**Problem:** `t2.micro` and `t2.medium` returned `InvalidParameterCombination: not eligible for Free Tier`.

**Solution:** change both instances to `t3.micro` in `tf/ec2.tf`.

---

### Challenge 6 — tfstate from the original repository caused conflicts on first deployment

**Problem:** the repo included the original `terraform.tfstate` with references to AWS and Datadog resources from the original repository account. When running `terraform plan` for the first time, Terraform tried to refresh those resources with the new credentials → 401/403 errors.

**Solution:** remove the inherited state before the first deployment:

```bash
rm tf/terraform.tfstate tf/terraform.tfstate.backup
```

---

### Challenge 7 — S3 bucket name already taken globally

**Problem:** `lti-project-code-bucket` already existed — S3 names are globally unique (`BucketAlreadyExists`).

**Solution:** add a unique suffix: `lti-project-code-bucket-xvb` in `tf/s3.tf` and in the user_data scripts.

---

### Challenge 8 — Docker does not start automatically after EC2 reboot

**Problem:** `service docker start` starts Docker once but does not register it as a system service. After a reboot the instance had no active Docker.

**Solution:**

```bash
# Before
service docker start

# After
systemctl enable docker
systemctl start docker
```
