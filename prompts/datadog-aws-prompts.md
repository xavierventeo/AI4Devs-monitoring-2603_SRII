# Prompts — Datadog Integration with AWS via Terraform

Prompts used to generate the Terraform code for Datadog monitoring on AWS infrastructure.

---

## Prompt 0 — Understand the project

```
You are a Site Reliability Engineer specialised in observability and infrastructure as code.
Analyse the repository and give me a summary of its contents. Pay special attention to the tf/ folder and the EC2 instance user_data scripts.
```

---

## Prompt 1 — Configure the Datadog provider in Terraform

```
Add the Datadog provider to tf/main.tf alongside the existing AWS provider.
- EU site: api_url = "https://api.datadoghq.eu"
- Reference: https://registry.terraform.io/providers/DataDog/datadog/latest/docs

Variable distribution following best practices:
- tf/variables.tf: declare datadog_api_key, datadog_app_key and datadog_api_url as string without values
- tf/terraform.tfvars: real values for the three variables → add to .gitignore
- tf/terraform.tfvars.example: template with example values → committed
- .env: application configuration only, no TF_VAR_* variables

Deliverable: provider "datadog" in main.tf, variables.tf, terraform.tfvars, terraform.tfvars.example and updated .gitignore so that no sensitive data is in version control.
```

---

## Prompt 2 — Install the Datadog agent on the EC2 instances

```
Modify tf/scripts/backend_user_data.sh and frontend_user_data.sh to install
the Datadog agent v7 before starting Docker.

Requirements:
- DD_SITE="datadoghq.eu"
- DD_AGENT_MAJOR_VERSION=7 (explicit even though the script already sets it)
- DD_API_KEY injected via templatefile() in tf/ec2.tf, not hardcoded in the script
- Official Datadog one-line script: https://install.datadoghq.com/scripts/install_script_agent7.sh
- Start the agent as a service with: systemctl start datadog-agent
- Reference: https://app.datadoghq.com/account/settings/agent/latest

Deliverable: both complete scripts and the updated templatefile() block in ec2.tf.
```

---

## Prompt 3 — Create the monitoring dashboard in Datadog

```
Create the datadog_dashboard resource in tf/datadog.tf to monitor the EC2 instances
lti-project-backend and lti-project-frontend.

Dashboard:
- Name: "LTI Project - EC2 Monitoring Dashboard", layout_type = "ordered"
- timeseries_definition widgets for: CPU Utilization, Network In, Network Out,
  Disk Read Ops, Disk Write Ops, Status Check Failed

Metrics source: the Datadog agent installed on the instances (Prompt 3), not CloudWatch.
Agent metrics use the system.* namespace and are grouped by {host}:
- CPU:         avg:system.cpu.user{*} by {host}
- Network In:  avg:system.net.bytes_rcvd{*} by {host}
- Network Out: avg:system.net.bytes_sent{*} by {host}
- Disk Read:   avg:system.io.r_s{*} by {host}
- Disk Write:  avg:system.io.w_s{*} by {host}
- Agent up:    avg:datadog.agent.running{*} by {host}

How to reference existing Terraform resources:
- Instance IDs: aws_instance.backend.id / aws_instance.frontend.id
- Public IPs: aws_instance.backend.public_ip / aws_instance.frontend.public_ip

Add the public IP outputs for both instances in tf/outputs.tf.

Reference: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/dashboard

Deliverable: complete tf/datadog.tf and tf/outputs.tf with the IP outputs.
```
