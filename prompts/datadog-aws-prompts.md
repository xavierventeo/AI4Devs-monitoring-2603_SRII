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

