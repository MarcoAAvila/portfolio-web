# 🌐 Portfolio Web — AWS Serverless Architecture

> Portafolio personal desplegado sobre infraestructura **100% Serverless en AWS**, diseñado para demostrar competencias avanzadas como **Cloud Architect** y principios de *Clean Code* e *Infraestructura como Código (IaC)*.

## 🏗️ Arquitectura

```text
Usuario 
  │ (HTTPS)
  ▼
Cloudflare (DNS) 
  │
  ▼
CloudFront (CDN) ── (OAC) ──▶ S3 Bucket (Frontend estático y privado)
  │
  │ (Llamada asíncrona - Contador de visitas)
  ▼
API Gateway (HTTP API) ──▶ AWS Lambda (Python) ──▶ DynamoDB (On-Demand)
```

## 🧠 Decisiones Arquitectónicas

1. **Autenticación sin contraseñas (OIDC):**
   Se utiliza **GitHub Actions** para el pipeline de CI/CD por su velocidad e integración nativa. La decisión clave aquí fue configurar **OpenID Connect (OIDC)** entre GitHub y AWS. Esto permite asumir un rol temporal en AWS sin necesidad de crear usuarios IAM ni almacenar *Access Keys* permanentes en GitHub Secrets, reduciendo drásticamente la superficie de ataque.

2. **Cloudflare vs Route 53:**
   La gestión del dominio se delegó a **Cloudflare** en lugar de AWS Route 53. Esto permite aprovechar la protección anti-DDoS, el proxy proxy inverso gratuito y una propagación de DNS ultra rápida, manteniendo la emisión de certificados SSL gratuitos a través de **AWS ACM** (vía validación CNAME).

3. **Backend Serverless Escalable (Contador de visitas):**
   Para añadir dinamismo (un contador de visualizaciones del CV), se optó por **DynamoDB (On-Demand) + Lambda + API Gateway** en lugar de un servidor tradicional (EC2) o contenedores (ECS). Esta decisión garantiza un coste de mantenimiento cercano a $0 (Free Tier), escalado a cero automático cuando no hay tráfico, y capacidad para absorber picos de peticiones instantáneamente con la operación atómica `UpdateItem` de DynamoDB.

4. **S3 Privado con OAC:**
   No se utiliza el "Static Website Hosting" clásico de S3 porque expone el bucket públicamente. En su lugar, el bucket está configurado como 100% privado. CloudFront accede a los archivos mediante **Origin Access Control (OAC)**, obligando a los usuarios a pasar por la CDN, forzando HTTPS y mejorando los tiempos de carga globales mediante caché en los nodos perimetrales (Edge Locations).

## 📁 Estructura del Repositorio

```text
portfolio-web/
├── .github/workflows/   # Pipeline CI/CD automatizado (OIDC + S3 Sync + CloudFront Invalidation)
├── terraform/           # Infraestructura como Código (AWS)
│   ├── lambda_src/      # Código Python para la función Lambda del backend
│   ├── acm.tf           # Certificados TLS/SSL
│   ├── backend_counter.tf # DynamoDB, Lambda, IAM Roles, API Gateway
│   ├── iam_oidc.tf      # Integración de identidad GitHub Actions
│   ├── s3_cloudfront.tf # Hosting y CDN con OAC
│   ├── budget.tf        # Control de costes y alertas automáticas
│   ├── variables.tf     # Parametrización modular
│   └── providers.tf     # Configuración multi-región
└── web/                 # Código fuente del Frontend
    ├── index.html       # Landing page
    ├── cv.html          # Previsualización del PDF y contador dinámico
    ├── css/             # Diseño Mobile-First en Vanilla CSS
    └── assets/          # Imágenes y documentos (PDF)
```

## 🚀 Stack Tecnológico

| Capa        | Tecnología                              |
|-------------|-----------------------------------------|
| Frontend    | HTML5 · CSS3 (Vanilla) · JavaScript     |
| Hosting     | AWS S3 + CloudFront (OAC)               |
| Backend     | AWS Lambda (Python) + API Gateway       |
| Base Datos  | Amazon DynamoDB                         |
| DNS/TLS     | Cloudflare + AWS ACM                    |
| IaC         | Terraform (HCL)                         |
| CI/CD       | GitHub Actions (OIDC)                   |

## 🔒 Seguridad e Integridad

- **Zero Secrets:** Ninguna credencial estática de AWS existe en el código o en los secretos de CI/CD.
- **Control de Presupuesto:** Infraestructura protegida por **AWS Budgets** con alertas automáticas (forecast) si el coste mensual se proyecta sobre $1 USD.
- **Estado Seguro:** Archivos `.tfstate` locales, `.terraform/`, `.tfvars` y configuraciones privadas excluidos rigurosamente vía `.gitignore`.

---
*Repositorio preparado con fines de demostración profesional.*
