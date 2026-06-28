# Prompts — Integración Datadog con AWS via Terraform

Prompts utilizados para generar el código Terraform de monitorización Datadog sobre infraestructura AWS.

---

## Prompt 0 — Entender el proyecto

```
Eres un Site Reliability Engineer especializado en observabilidad e infraestructura como código.
Analiza el repositorio y hazme un resumen de su contenido. Presta especial atención a la carpeta tf/ y a los scripts de user_data de las instancias EC2.
```

---

## Prompt 1 — Configurar el proveedor Datadog en Terraform

```
Añade el proveedor Datadog a tf/main.tf junto al proveedor AWS existente.
- Site EU: api_url = "https://api.datadoghq.eu"
- Referencia: https://registry.terraform.io/providers/DataDog/datadog/latest/docs

Distribución de variables siguiendo buenas prácticas:
- tf/variables.tf: declara datadog_api_key, datadog_app_key y datadog_api_url como string sin valores
- tf/terraform.tfvars: valores reales de las tres variables → añadir a .gitignore
- tf/terraform.tfvars.example: plantilla con valores de ejemplo → commiteado
- .env: solo configuración de la aplicación, sin variables TF_VAR_*

Entregable: provider "datadog" en main.tf, variables.tf, terraform.tfvars, terraform.tfvars.example y .gitignore actualizado para que no haya datos sensibles en control de versiones.
```

---

## Prompt 2 — Configurar la integración AWS-Datadog

```
Configura la integración oficial entre AWS y Datadog para que pueda leer métricas
de CloudWatch de las instancias EC2. Coloca todo en tf/datadog.tf.

Necesito:
1. Política IAM con permisos: cloudwatch:GetMetricData/ListMetrics,
   ec2:DescribeInstances, logs:Describe*/GetLogEvents/FilterLogEvents,
   tag:GetResources/GetTagKeys/GetTagValues
2. Data source con las instancias EC2 en estado "running"
3. Recurso datadog_integration_aws filtrando por tag Datadog:true

Sin claves hardcodeadas.

Referencias:
- https://docs.datadoghq.com/integrations/amazon_web_services/
- https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws

Entregable: fichero tf/datadog.tf completo con los tres bloques.
```

---

## Prompt 3 — Instalar el agente Datadog en las instancias EC2

```
Modifica tf/scripts/backend_user_data.sh y frontend_user_data.sh para instalar
el agente Datadog v7 antes de arrancar Docker.

Requisitos:
- DD_SITE="datadoghq.eu"
- DD_AGENT_MAJOR_VERSION=7 (explícito aunque el script ya lo fija)
- DD_API_KEY inyectada via templatefile() en tf/ec2.tf, no hardcodeada en el script
- Script one-line oficial de Datadog: https://install.datadoghq.com/scripts/install_script_agent7.sh
- Arrancar el agente como servicio con: systemctl start datadog-agent
- Referencia: https://app.datadoghq.com/account/settings/agent/latest

Entregable: los dos scripts completos y el bloque templatefile() actualizado en ec2.tf.
```

---

## Prompt 4 — Crear el dashboard de monitorización en Datadog

```
Crea el recurso datadog_dashboard en tf/dashboard.tf para monitorizar las instancias
EC2 lti-project-backend y lti-project-frontend.

Dashboard:
- Nombre: "LTI Project - EC2 Monitoring Dashboard", layout_type = "ordered"
- Widgets timeseries_definition para: CPU Utilization, Network In, Network Out,
  Disk Read Ops, Disk Write Ops, Status Check Failed

Fuente de métricas: el agente Datadog instalado en las instancias (Prompt 3), no CloudWatch.
Las métricas del agente usan el namespace system.* y se agrupan por {host}:
- CPU:        avg:system.cpu.user{*} by {host}
- Network In: avg:system.net.bytes_rcvd{*} by {host}
- Network Out: avg:system.net.bytes_sent{*} by {host}
- Disk Read:  avg:system.io.r_s{*} by {host}
- Disk Write: avg:system.io.w_s{*} by {host}
- Agent up:   avg:datadog.agent.running{*} by {host}

Cómo referenciar recursos existentes de Terraform:
- IDs de instancia: aws_instance.backend.id / aws_instance.frontend.id
- IPs públicas: aws_instance.backend.public_ip / aws_instance.frontend.public_ip

Añade en tf/outputs.tf los outputs de las IPs públicas de ambas instancias.

Referencia: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/dashboard

Entregable: tf/dashboard.tf completo y tf/outputs.tf con los outputs de las IPs.

```
