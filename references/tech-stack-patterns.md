# Tech Stack Detection Patterns

Lookup table mapping manifest files and code patterns to technology stacks. Used by the detect-stack.sh script and by agents to interpret detection results.

## Language Detection by Manifest

| Manifest File | Language | Notes |
|--------------|----------|-------|
| `package.json` | JavaScript/TypeScript | Check `devDependencies` for `typescript` to distinguish |
| `tsconfig.json` | TypeScript | Definitive TS indicator |
| `Cargo.toml` | Rust | |
| `go.mod` | Go | |
| `pyproject.toml` | Python | Modern Python packaging |
| `setup.py` | Python | Legacy Python packaging |
| `requirements.txt` | Python | Dependency list (no build config) |
| `Pipfile` | Python | Pipenv-based |
| `pom.xml` | Java | Maven build |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin | Gradle build |
| `Gemfile` | Ruby | |
| `composer.json` | PHP | |
| `mix.exs` | Elixir | |
| `*.csproj` / `*.sln` | C# / .NET | |
| `Package.swift` | Swift | |
| `pubspec.yaml` | Dart/Flutter | |
| `Makefile` only | C/C++ | Or language-agnostic build |
| `CMakeLists.txt` | C/C++ | CMake build |
| `deno.json` / `deno.jsonc` | TypeScript (Deno) | |
| `bun.lockb` | TypeScript (Bun) | |

## Framework Detection

### JavaScript/TypeScript Frameworks

| Dependency in package.json | Framework | Type |
|---------------------------|-----------|------|
| `react` | React | Frontend |
| `next` | Next.js | Full-stack |
| `vue` | Vue.js | Frontend |
| `nuxt` | Nuxt.js | Full-stack |
| `@angular/core` | Angular | Frontend |
| `svelte` | Svelte | Frontend |
| `express` | Express.js | Backend |
| `fastify` | Fastify | Backend |
| `@nestjs/core` | NestJS | Backend |
| `hono` | Hono | Backend |
| `koa` | Koa | Backend |
| `@hapi/hapi` | Hapi | Backend |
| `electron` | Electron | Desktop |
| `react-native` | React Native | Mobile |

### Python Frameworks

| Import/Dependency | Framework | Type |
|------------------|-----------|------|
| `django` | Django | Full-stack |
| `flask` | Flask | Backend |
| `fastapi` | FastAPI | Backend |
| `starlette` | Starlette | Backend |
| `tornado` | Tornado | Backend |
| `celery` | Celery | Task queue |
| `airflow` | Apache Airflow | Workflow |
| `pytest` | pytest | Testing |
| `ansible` | Ansible | Automation |

### Go Frameworks

| Import/Module | Framework | Type |
|--------------|-----------|------|
| `github.com/gin-gonic/gin` | Gin | Backend |
| `github.com/labstack/echo` | Echo | Backend |
| `github.com/gofiber/fiber` | Fiber | Backend |
| `net/http` | stdlib | Backend |
| `github.com/gorilla/mux` | Gorilla Mux | Router |
| `google.golang.org/grpc` | gRPC | RPC |

### Rust Frameworks

| Dependency in Cargo.toml | Framework | Type |
|-------------------------|-----------|------|
| `actix-web` | Actix Web | Backend |
| `axum` | Axum | Backend |
| `rocket` | Rocket | Backend |
| `tokio` | Tokio | Async runtime |
| `warp` | Warp | Backend |
| `tonic` | Tonic | gRPC |

### Java/Kotlin Frameworks

| Dependency | Framework | Type |
|-----------|-----------|------|
| `spring-boot` | Spring Boot | Full-stack |
| `spring-webflux` | Spring WebFlux | Reactive |
| `quarkus` | Quarkus | Backend |
| `micronaut` | Micronaut | Backend |
| `jakarta.servlet` | Jakarta EE | Enterprise |
| `ktor` | Ktor | Backend (Kotlin) |

### Ruby Frameworks

| Gem | Framework | Type |
|-----|-----------|------|
| `rails` | Ruby on Rails | Full-stack |
| `sinatra` | Sinatra | Backend |
| `hanami` | Hanami | Backend |

### PHP Frameworks

| Dependency | Framework | Type |
|-----------|-----------|------|
| `laravel/framework` | Laravel | Full-stack |
| `symfony/framework-bundle` | Symfony | Full-stack |

## Database Detection

| Indicator | Database |
|-----------|----------|
| `prisma` in dependencies | Prisma ORM (likely PostgreSQL/MySQL) |
| `sequelize` | Sequelize ORM |
| `typeorm` | TypeORM |
| `mongoose` / `mongodb` | MongoDB |
| `redis` / `ioredis` | Redis |
| `pg` / `psycopg2` / `asyncpg` | PostgreSQL |
| `mysql2` / `mysqlclient` | MySQL |
| `sqlite3` / `better-sqlite3` | SQLite |
| `sqlalchemy` | SQLAlchemy ORM (Python) |
| `diesel` | Diesel ORM (Rust) |
| `gorm` | GORM (Go) |
| `ent` | Ent (Go) |
| `ActiveRecord` | ActiveRecord (Ruby) |
| `Eloquent` | Eloquent ORM (PHP/Laravel) |

## Infrastructure Detection

| File/Dependency | Technology |
|----------------|------------|
| `Dockerfile` | Docker |
| `docker-compose*.yml` | Docker Compose |
| `*.tf` files | Terraform |
| `k8s/` or `kubernetes/` | Kubernetes |
| `helm/` with `Chart.yaml` | Helm |
| `.github/workflows/` | GitHub Actions |
| `Jenkinsfile` | Jenkins |
| `.gitlab-ci.yml` | GitLab CI |
| `.circleci/config.yml` | CircleCI |
| `serverless.yml` | Serverless Framework |
| `amplify/` | AWS Amplify |
| `firebase.json` | Firebase |
| `vercel.json` | Vercel |
| `netlify.toml` | Netlify |
