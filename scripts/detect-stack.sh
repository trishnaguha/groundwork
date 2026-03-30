#!/bin/bash
# detect-stack.sh -- Detect primary tech stack from repository files
# Usage: bash detect-stack.sh <repo-path>

REPO="${1:-.}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: Directory not found: $REPO"
    exit 1
fi

cd "$REPO" || exit 1

echo "=== Tech Stack Detection ==="
echo "REPO_PATH: $REPO"

# Check for language-specific manifests
echo ""
echo "=== Manifest Files ==="
for f in package.json tsconfig.json Cargo.toml go.mod pyproject.toml setup.py \
         requirements.txt Pipfile pom.xml build.gradle build.gradle.kts \
         Gemfile composer.json mix.exs pubspec.yaml CMakeLists.txt \
         deno.json deno.jsonc bun.lockb; do
    if [ -e "$f" ]; then
        echo "FOUND: $f"
    fi
done

# Check for solution/project files (.NET)
for f in *.csproj *.sln *.fsproj; do
    if ls $f 1>/dev/null 2>&1; then
        echo "FOUND: $f"
        break
    fi
done

# Count source files by extension
echo ""
echo "=== File Distribution (top 20 extensions) ==="
find . -type f \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    -not -path '*/vendor/*' \
    -not -path '*/target/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/.next/*' \
    -not -path '*/dist/*' \
    -not -path '*/build/*' \
    -not -path '*/venv/*' \
    -not -path '*/.venv/*' \
    -not -path '*/site-packages/*' \
    -not -path '*/.tox/*' \
    -not -path '*/coverage/*' \
    -not -path '*/.terraform/*' \
    -not -path '*/bower_components/*' \
    -not -name '*.min.js' \
    -not -name '*.min.css' \
    -not -name '*.map' \
    -not -name '*.lock' \
    2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20

# Framework detection via dependency files
echo ""
echo "=== Framework Detection ==="

# JavaScript/TypeScript frameworks
if [ -f "package.json" ]; then
    for fw in react next vue nuxt angular svelte express fastify nestjs hono koa hapi electron react-native; do
        if grep -q "\"$fw\"" package.json 2>/dev/null || grep -q "\"@${fw}" package.json 2>/dev/null; then
            echo "JS_FRAMEWORK: $fw"
        fi
    done
    # Check for TypeScript
    if [ -f "tsconfig.json" ] || grep -q '"typescript"' package.json 2>/dev/null; then
        echo "TYPESCRIPT: true"
    fi
fi

# Python frameworks
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "Pipfile" ]; then
    for fw in django flask fastapi starlette tornado celery airflow ansible; do
        if grep -qi "$fw" requirements.txt pyproject.toml setup.py Pipfile 2>/dev/null; then
            echo "PY_FRAMEWORK: $fw"
        fi
    done
fi

# Go frameworks
if [ -f "go.mod" ]; then
    for fw in gin echo fiber gorilla grpc; do
        if grep -qi "$fw" go.mod 2>/dev/null; then
            echo "GO_FRAMEWORK: $fw"
        fi
    done
fi

# Rust frameworks
if [ -f "Cargo.toml" ]; then
    for fw in actix-web axum rocket warp tonic; do
        if grep -qi "$fw" Cargo.toml 2>/dev/null; then
            echo "RUST_FRAMEWORK: $fw"
        fi
    done
fi

# Java/Kotlin frameworks
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    for fw in spring-boot quarkus micronaut ktor; do
        if grep -qi "$fw" pom.xml build.gradle build.gradle.kts 2>/dev/null; then
            echo "JVM_FRAMEWORK: $fw"
        fi
    done
fi

# Ruby frameworks
if [ -f "Gemfile" ]; then
    for fw in rails sinatra hanami; do
        if grep -qi "$fw" Gemfile 2>/dev/null; then
            echo "RUBY_FRAMEWORK: $fw"
        fi
    done
fi

# PHP frameworks
if [ -f "composer.json" ]; then
    for fw in laravel symfony; do
        if grep -qi "$fw" composer.json 2>/dev/null; then
            echo "PHP_FRAMEWORK: $fw"
        fi
    done
fi

# Database detection
echo ""
echo "=== Database Detection ==="
for db in prisma sequelize typeorm mongoose mongodb redis pg psycopg2 asyncpg \
          mysql2 mysqlclient sqlite3 better-sqlite3 sqlalchemy diesel gorm ent \
          ActiveRecord Eloquent; do
    if grep -rqi "$db" package.json requirements.txt pyproject.toml Cargo.toml go.mod \
                       Gemfile composer.json pom.xml build.gradle 2>/dev/null; then
        echo "DATABASE_INDICATOR: $db"
    fi
done

# Infrastructure detection
echo ""
echo "=== Infrastructure Detection ==="
[ -f "Dockerfile" ] && echo "INFRA: Docker"
ls docker-compose*.yml docker-compose*.yaml 2>/dev/null | head -1 | xargs -I{} echo "INFRA: Docker Compose"
ls *.tf 2>/dev/null | head -1 | xargs -I{} echo "INFRA: Terraform"
[ -d "k8s" ] || [ -d "kubernetes" ] && echo "INFRA: Kubernetes"
[ -d "helm" ] && echo "INFRA: Helm"
[ -d ".github/workflows" ] && echo "CI: GitHub Actions"
[ -f "Jenkinsfile" ] && echo "CI: Jenkins"
[ -f ".gitlab-ci.yml" ] && echo "CI: GitLab CI"
[ -d ".circleci" ] && echo "CI: CircleCI"
[ -f "serverless.yml" ] && echo "INFRA: Serverless"
[ -f "vercel.json" ] && echo "INFRA: Vercel"
[ -f "netlify.toml" ] && echo "INFRA: Netlify"

echo ""
echo "=== Detection Complete ==="
