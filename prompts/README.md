# Implementando un Canal de Monitorización Datadog con Terraform en AWS

Canal de observabilidad completo sobre infraestructura AWS usando Terraform como IaC y Datadog como plataforma de monitorización. El sistema despliega dos instancias EC2 (backend y frontend) con el agente Datadog instalado, un dashboard de métricas.

---

## Índice

1. [Arquitectura](#arquitectura)
2. [Cambios realizados](#cambios-realizados)
3. [Prompts utilizados](#prompts-utilizados)
4. [Dashboard en Datadog](#dashboard-en-datadog)
5. [Setup y configuración](#setup-y-configuración)
6. [Desafíos encontrados](#desafíos-encontrados)

---

## Arquitectura

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
         └── Métricas: CPU, Network In/Out, Disk R/W, Agent status
```

### Recursos Terraform desplegados

| Recurso | Detalle |
|---|---|
| S3 Bucket | `lti-project-code-bucket-xvb` con `backend.zip` y `frontend.zip` |
| EC2 backend | `t3.micro`, puerto `8080`, Amazon Linux 2 + Docker |
| EC2 frontend | `t3.micro`, puerto `3000`, Amazon Linux 2 + Docker |
| IAM Role | Acceso S3 desde EC2 |
| Security Groups | SSH (22) y puertos de aplicación (8080/3000) |
| Datadog Dashboard | Métricas del agente por host (`tf/datadog.tf`) |


---

## Cambios realizados

### 1. Proveedor Datadog en Terraform (`tf/main.tf`, `tf/variables.tf`)

Añadido el proveedor Datadog apuntando al site EU, con las claves declaradas como variables sin valores hardcodeados. Distribución de ficheros siguiendo buenas prácticas:

- `tf/variables.tf` — declaraciones de tipo sin valores
- `tf/terraform.tfvars` — valores reales, gitignoreado
- `tf/terraform.tfvars.example` — plantilla commiteada

### 2. Agente Datadog en EC2 (`tf/scripts/`)

Instalación del agente Datadog v7 en ambas instancias antes de arrancar Docker. La `DD_API_KEY` se inyecta en tiempo de despliegue via `templatefile()` en lugar de estar hardcodeada en el script.

```bash
DD_API_KEY="${datadog_api_key}" DD_SITE="datadoghq.eu" DD_AGENT_MAJOR_VERSION=7 \
  bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
systemctl start datadog-agent
```

### 3. Dashboard de monitorización (`tf/datadog.tf`)

Dashboard con 6 widgets usando métricas del agente Datadog (`system.*`):

| Widget | Query |
|---|---|
| CPU Utilization | `avg:system.cpu.user{*} by {host}` |
| Network In | `avg:system.net.bytes_rcvd{*} by {host}` |
| Network Out | `avg:system.net.bytes_sent{*} by {host}` |
| Disk Read Ops | `avg:system.io.r_s{*} by {host}` |
| Disk Write Ops | `avg:system.io.w_s{*} by {host}` |
| Agent Running | `avg:datadog.agent.running{*} by {host}` |

---

## Prompts utilizados

Los prompts principales usados para generar el código Terraform están documentados en:

➡ [datadog-aws-prompts.md](./datadog-aws-prompts.md)

Resumen de los prompts:

| Prompt | Objetivo |
|---|---|
| Prompt 0 | Análisis del repositorio y comprensión del proyecto |
| Prompt 1 | Configurar el proveedor Datadog con buenas prácticas de variables |
| Prompt 2 | Instalación del agente Datadog v7 en las instancias EC2 |
| Prompt 3 | Dashboard de monitorización con métricas del agente |

---

## Dashboard en Datadog

### Dashboard EC2 Monitoring

Dashboard completo con métricas de CPU, red y disco agrupadas por host:

![EC2 Monitoring Dashboard](images/EC2%20Monitoring%20Dashboard.png)

### Detalle CPU Utilization

Vista detallada de la métrica de CPU por instancia:

![CPU Utilization Detail](images/CPU%20Utilization%20Detail.png)

### Vista de hosts

Instancias EC2 registradas en Datadog con el agente activo:

![Host View](images/Host%20View.png)

---

## Setup y configuración

### Prerrequisitos

```bash
brew install terraform awscli

terraform --version   # >= 1.5.7
aws --version
zip --version
```

### Configuración de AWS

#### 1. Crear credenciales en IAM

1. Consola AWS → **IAM** → **Users** → tu usuario
2. Pestaña **Security credentials** → **Create access key** → elige **CLI**
3. Permisos necesarios: `AmazonEC2FullAccess`, `AmazonS3FullAccess`, `IAMFullAccess`
4. Copia el `Access Key ID` y el `Secret Access Key` — solo se muestran una vez

#### 2. Configurar el CLI

```bash
aws configure
```

| Campo | Valor |
|---|---|
| AWS Access Key ID | `AKIA...` |
| AWS Secret Access Key | `xxxx...` |
| Default region name | `us-east-1` |
| Default output format | `json` |

#### 3. Verificar acceso

```bash
aws sts get-caller-identity
```

### Configuración de Datadog

#### 1. Obtener las claves

1. **Organization Settings → API Keys** → copia el valor **Key** (no el Key ID)
2. **Organization Settings → Application Keys** → copia el valor **Key**

> La cuenta debe estar en `datadoghq.eu`. Verifica la URL cuando estés logado.

#### 2. Configurar las claves

Copia la plantilla y rellena con tus valores reales:

```bash
cp tf/terraform.tfvars.example tf/terraform.tfvars
# Edita terraform.tfvars con tus claves reales
```

```hcl
# tf/terraform.tfvars (gitignoreado)
datadog_api_url = "https://api.datadoghq.eu"
datadog_api_key = "tu_api_key_valor_secreto"
datadog_app_key = "tu_app_key_valor"
```

### Despliegue con Terraform

```bash
# 1. Generar los ZIPs del código (desde la raíz del proyecto)
./generar-zip.sh

# 2. Inicializar Terraform (solo la primera vez)
cd tf/
terraform init

# 3. Revisar los cambios
terraform plan

# 4. Desplegar
terraform apply   # escribe "yes" para confirmar
```

### Verificar el despliegue

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lti-project-backend,lti-project-frontend" \
  --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value|[0],PublicIpAddress,State.Name]" \
  --output table
```

### Destruir la infraestructura al finalizar el ejercicio

```bash
cd tf/
terraform destroy   # escribe "yes" para confirmar
```

---

## Desafíos encontrados

### Desafío 1 — Secretos expuestos en el control de versiones

**Problema:** varios ficheros con secretos estaban commiteados en el repo. En un repositorio público cualquier atacante o scanner automático puede recuperarlos del historial aunque los ficheros se eliminen después.

**Solución:**

```bash
# .gitignore — líneas corregidas/añadidas
**/.env
**/terraform.tfvars
**/terraform.tfstate
**/terraform.tfstate.backup
**/.terraform.tfstate.lock.info

# Sacar los ficheros del índice sin borrarlos del disco
git rm --cached .env backend/.env tf/terraform.tfstate tf/terraform.tfstate.backup
```

> El `tfstate` en producción debe ir en un backend remoto S3 + DynamoDB para evitar conflictos en equipo y proteger el estado.

**Inventario de secretos comprometidos en el repo original:**

| Secreto | Fichero | Solución |
|---|---|---|
| `DD_API_KEY='76cd5e07...'` | `tf/scripts/*.sh` | Inyectar via `templatefile()` |
| `DB_PASSWORD=D1ymf8wy...` | `.env`, `backend/.env` | Corregir `.gitignore` |
| IDs y ARNs de infraestructura | `tf/terraform.tfstate` | Añadir a `.gitignore` |

---

### Desafío 2 — Confusión entre API Key y App Key de Datadog

**Problema:** Datadog tiene dos tipos de credenciales en secciones distintas de la UI, con campos que pueden confundirse fácilmente:

| Variable Terraform | Sección en Datadog | Campo a copiar |
|---|---|---|
| `datadog_api_key` | Organization Settings → **API Keys** | **Key** (valor secreto, no el Key ID) |
| `datadog_app_key` | Organization Settings → **Application Keys** | **Key** |

**Error frecuente:** copiar el `Key ID` de API Keys en lugar del valor secreto, o usar claves de **Personal Settings** en lugar de **Organization Settings**.

---

### Desafío 3 — `DD_SITE` apuntando a la región incorrecta

**Problema:** los scripts originales tenían `DD_SITE="datadoghq.com"` (US1) pero la cuenta Datadog está en EU. El agente enviaba métricas al site incorrecto → datos vacíos en el dashboard.

**Solución:** alinear scripts y provider al mismo site:

```bash
DD_SITE="datadoghq.eu"          # en los scripts de user_data
api_url = "https://api.datadoghq.eu"  # en el provider de Terraform
```

---

### Desafío 4 — API key de Datadog expuesta en el user-data de la EC2

**Problema:** aunque la `DD_API_KEY` ya no está hardcodeada en el código fuente, AWS la almacena en texto plano como `user_data` de la instancia, accesible desde dentro:

```bash
curl http://169.254.169.254/latest/user-data
```

**Solución actual:** inyección via `templatefile()` — elimina la exposición en código fuente pero no en los metadatos de la instancia.

**Solución recomendada para producción, aunque no aplicada en el ejercicio:** AWS Secrets Manager:

```bash
DD_API_KEY=$(aws secretsmanager get-secret-value \
  --secret-id datadog/api-key \
  --query SecretString --output text)
```

---

### Desafío 5 — Tipos de instancia EC2 no elegibles para Free Tier

**Problema:** `t2.micro` y `t2.medium` devolvieron `InvalidParameterCombination: not eligible for Free Tier`.

**Solución:** cambiar ambas instancias a `t3.micro` en `tf/ec2.tf`.

---

### Desafío 6 — tfstate del repositorio original causaba conflictos en el primer despliegue

**Problema:** el repo incluía el `terraform.tfstate` original con referencias a recursos de la cuenta AWS y Datadog del repositorio original. Al ejecutar `terraform plan` por primera vez, Terraform intentaba refrescar esos recursos con las nuevas credenciales → errores 401/403.

**Solución:** eliminar el estado heredado antes del primer despliegue:

```bash
rm tf/terraform.tfstate tf/terraform.tfstate.backup
```

---

### Desafío 7 — Nombre del bucket S3 ya ocupado globalmente

**Problema:** `lti-project-code-bucket` ya existía — los nombres de S3 son únicos a nivel mundial (`BucketAlreadyExists`).

**Solución:** añadir sufijo único: `lti-project-code-bucket-xvb` en `tf/s3.tf` y en los scripts de user_data.

---

### Desafío 8 — Docker no arranca automáticamente tras reinicio de la EC2

**Problema:** `service docker start` arranca Docker una sola vez pero no lo registra como servicio del sistema. Tras un reinicio la instancia quedaba sin Docker activo.

**Solución:**

```bash
# Antes
service docker start

# Después
systemctl enable docker
systemctl start docker
```

