#!/usr/bin/env bash
# =============================================================================
# setup-monorepo.sh
# Script de inicialización del Monorepo: portfolio-web
# Autor: Marco A. Avila
# Descripción: Genera la estructura de directorios profesional, archivos base
#              y un .gitignore robusto para un portafolio Cloud Architect en AWS.
# =============================================================================

set -euo pipefail

# --- Colores ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_step() { echo -e "\n${CYAN}${BOLD}[STEP]${RESET} $1"; }
log_ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
log_warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║       portfolio-web · Monorepo Initializer       ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"

# =============================================================================
# PASO 1 — Crear estructura de directorios
# =============================================================================
log_step "Creando estructura de directorios..."

DIRS=(
  ".github/workflows"
  "terraform"
  "web/css"
  "web/assets/images"
)

for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
  log_ok "Creado: $dir/"
done

# =============================================================================
# PASO 2 — Archivos base
# =============================================================================
log_step "Generando archivos base..."

# --- README.md ---
if [ ! -f "README.md" ]; then
cat > README.md << 'EOF'
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
EOF
  log_ok "Creado: README.md"
else
  log_warn "README.md ya existe — omitido."
fi

# --- terraform/providers.tf ---
if [ ! -f "terraform/providers.tf" ]; then
cat > terraform/providers.tf << 'EOF'
# =============================================================================
# providers.tf — Configuración del proveedor de Terraform
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Descomenta y configura el backend remoto cuando estés listo:
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "portfolio-web/terraform.tfstate"
  #   region         = var.aws_region
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "portfolio-web"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Proveedor en us-east-1 requerido para certificados ACM + CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
EOF
  log_ok "Creado: terraform/providers.tf"
else
  log_warn "terraform/providers.tf ya existe — omitido."
fi

# --- terraform/variables.tf ---
if [ ! -f "terraform/variables.tf" ]; then
cat > terraform/variables.tf << 'EOF'
# =============================================================================
# variables.tf — Definición de variables del proyecto
# =============================================================================

variable "aws_region" {
  description = "Región principal de AWS donde se desplegarán los recursos."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Entorno de despliegue (dev | staging | prod)."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El entorno debe ser 'dev', 'staging' o 'prod'."
  }
}

variable "domain_name" {
  description = "Nombre de dominio personalizado para el portafolio (ej: marcoavila.dev)."
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "Nombre único del bucket S3 para alojar el sitio estático."
  type        = string
}
EOF
  log_ok "Creado: terraform/variables.tf"
else
  log_warn "terraform/variables.tf ya existe — omitido."
fi

# --- terraform/main.tf ---
if [ ! -f "terraform/main.tf" ]; then
cat > terraform/main.tf << 'EOF'
# =============================================================================
# main.tf — Recursos principales de infraestructura AWS
# =============================================================================
#
# Recursos planificados:
#   - S3 Bucket (static website hosting)
#   - CloudFront Distribution (CDN + HTTPS)
#   - ACM Certificate (TLS/SSL) — región us-east-1
#   - Route 53 Record (DNS)
#
# TODO: Implementar recursos según avance el proyecto.
# =============================================================================
EOF
  log_ok "Creado: terraform/main.tf"
else
  log_warn "terraform/main.tf ya existe — omitido."
fi

# --- web/index.html ---
if [ ! -f "web/index.html" ]; then
cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="Portafolio de Marco A. Avila — Cloud Architect especializado en AWS Serverless." />
  <title>Marco A. Avila | Cloud Architect Portfolio</title>
  <link rel="stylesheet" href="css/style.css" />
</head>
<body>

  <header>
    <h1>Marco A. Avila</h1>
    <p>Cloud Architect · AWS Serverless · IaC</p>
  </header>

  <main>
    <section id="about">
      <h2>Sobre mí</h2>
      <p>En construcción 🚧</p>
    </section>
  </main>

  <footer>
    <p>Desplegado en AWS · Infraestructura gestionada con Terraform</p>
  </footer>

</body>
</html>
EOF
  log_ok "Creado: web/index.html"
else
  log_warn "web/index.html ya existe — omitido."
fi

# --- web/css/style.css ---
if [ ! -f "web/css/style.css" ]; then
cat > web/css/style.css << 'EOF'
/* =============================================================================
   style.css — Hoja de estilos principal del portafolio
   ============================================================================= */

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --color-bg:      #0d1117;
  --color-surface: #161b22;
  --color-primary: #58a6ff;
  --color-text:    #c9d1d9;
  --color-muted:   #8b949e;
  --font-main:     'Inter', system-ui, sans-serif;
}

body {
  background-color: var(--color-bg);
  color: var(--color-text);
  font-family: var(--font-main);
  line-height: 1.6;
  min-height: 100vh;
}

header {
  text-align: center;
  padding: 4rem 1rem 2rem;
}

header h1 {
  font-size: clamp(2rem, 5vw, 3.5rem);
  color: var(--color-primary);
}

header p {
  color: var(--color-muted);
  margin-top: 0.5rem;
  font-size: 1.1rem;
  letter-spacing: 0.05em;
}

main {
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

section {
  background: var(--color-surface);
  border-radius: 8px;
  padding: 2rem;
  margin-bottom: 2rem;
  border: 1px solid #30363d;
}

section h2 {
  font-size: 1.4rem;
  color: var(--color-primary);
  margin-bottom: 1rem;
}

footer {
  text-align: center;
  padding: 2rem 1rem;
  color: var(--color-muted);
  font-size: 0.85rem;
  border-top: 1px solid #30363d;
}
EOF
  log_ok "Creado: web/css/style.css"
else
  log_warn "web/css/style.css ya existe — omitido."
fi

# =============================================================================
# PASO 3 — .gitignore robusto
# =============================================================================
log_step "Generando .gitignore con protección de secretos..."

if [ ! -f ".gitignore" ]; then
cat > .gitignore << 'EOF'
# =============================================================================
# .gitignore — portfolio-web
# NUNCA subas secretos, credenciales o estado de infraestructura a este repo.
# =============================================================================

# --- Sistema Operativo ---
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
Desktop.ini

# --- Editores e IDEs ---
.vscode/
.idea/
*.swp
*.swo
*~

# ============================================================
# TERRAFORM — ⚠️  CRÍTICO: pueden contener secretos en texto plano
# ============================================================
**/.terraform/
**/.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfstate.backup
crash.log
crash.*.log

# Archivos de variables con valores reales
*.tfvars
*.tfvars.json
!terraform.tfvars.example

# Planes de ejecución generados localmente
*.tfplan
*.plan

# --- Credenciales AWS ---
.aws/credentials
.aws/config
aws-credentials*
*_credentials*
*_access_key*
*_secret_key*

# --- Archivos de Entorno y Claves Privadas ---
.env
.env.*
!.env.example
*.pem
*.key
*.p12
*.pfx
*.cer
*.crt
id_rsa
id_rsa.*
id_ed25519
id_ed25519.*

# --- Node.js ---
node_modules/
npm-debug.log*
yarn-debug.log*
dist/
build/

# --- Python ---
__pycache__/
*.py[cod]
.venv/
venv/

# --- Logs y temporales ---
*.log
*.tmp
*.temp
.cache/
EOF
  log_ok "Creado: .gitignore"
else
  log_warn ".gitignore ya existe — omitido."
fi

# =============================================================================
# PASO 4 — .gitkeep para directorios vacíos
# =============================================================================
log_step "Añadiendo .gitkeep a directorios vacíos..."

for dir in ".github/workflows" "web/assets/images"; do
  if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    touch "$dir/.gitkeep"
    log_ok ".gitkeep en: $dir/"
  fi
done

# =============================================================================
# Resumen final
# =============================================================================
echo -e "\n${BOLD}${GREEN}════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${GREEN}  ✅  Monorepo inicializado correctamente.${RESET}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${RESET}\n"

echo -e "${BOLD}Estructura generada:${RESET}"
if command -v tree &> /dev/null; then
  tree -a -I ".git" --dirsfirst
else
  find . -not -path "./.git/*" -not -name ".git" | sort | \
    awk 'BEGIN{FS="/"}{depth=NF-2; indent=""; for(i=0;i<depth;i++) indent=indent"  "; print indent "├── " $NF}'
fi

echo ""
echo -e "${YELLOW}${BOLD}⚠  Próximos pasos recomendados:${RESET}"
echo -e "   1. Revisa el .gitignore antes de tu primer 'git add'."
echo -e "   2. Añade valores reales en un archivo local .tfvars (nunca lo subas)."
echo -e "   3. Ejecuta: ${CYAN}git add . && git commit -m 'chore: initialize monorepo structure'${RESET}"
echo ""

