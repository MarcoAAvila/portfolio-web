# 🌐 Portfolio Web — AWS Serverless Architecture

> Portafolio personal desplegado sobre infraestructura **100% Serverless en AWS**,
> diseñado para demostrar competencias como **Cloud Architect**.

## 🏗️ Arquitectura

```
S3 (Static Hosting) → CloudFront (CDN + HTTPS) → Route 53 (DNS)
```

## 📁 Estructura del Repositorio

```
portfolio-web/
├── .github/workflows/   # Pipelines CI/CD (GitHub Actions)
├── terraform/           # Infraestructura como Código (IaC) — AWS
│   ├── main.tf
│   ├── variables.tf
│   └── providers.tf
└── web/                 # Frontend estático
    ├── index.html
    ├── css/
    │   └── style.css
    └── assets/images/
```

## 🚀 Stack Tecnológico

| Capa        | Tecnología                              |
|-------------|-----------------------------------------|
| Frontend    | HTML5 · CSS3 · JavaScript               |
| Hosting     | AWS S3 + CloudFront                     |
| DNS/TLS     | AWS Route 53 + ACM                      |
| IaC         | Terraform                               |
| CI/CD       | GitHub Actions                          |

## 🔒 Seguridad

- Ningún secreto, credencial o archivo `.tfstate` es versionado.
- Ver `.gitignore` para la lista completa de exclusiones.

---
*Repositorio público con fines educativos y de demostración profesional.*
