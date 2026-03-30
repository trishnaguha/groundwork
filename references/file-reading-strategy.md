# Comprehensive File Reading Strategy

Rules for reading ALL files in a codebase intelligently. The goal is to read every unique, meaningful file while skipping generated artifacts and vendor code.

## Always Read (Every Single File)

### Source Code
- `.js`, `.jsx`, `.ts`, `.tsx`, `.mjs`, `.cjs`
- `.py`, `.pyi`
- `.go`
- `.rs`
- `.java`, `.kt`, `.scala`
- `.rb`
- `.php`
- `.cs`, `.fs`
- `.swift`
- `.c`, `.cpp`, `.h`, `.hpp`
- `.lua`, `.ex`, `.exs`, `.erl`
- `.dart`
- `.r`, `.R`
- `.sh`, `.bash`, `.zsh`
- Any other language-specific source files

### Configuration
- `.json` (except lockfiles)
- `.yaml`, `.yml`
- `.toml`
- `.ini`, `.cfg`
- `.env.example`, `.env.sample` (never `.env` itself)
- `.config.*`, `.*rc` (eslintrc, prettierrc, etc.)
- `.editorconfig`
- `Makefile`, `Rakefile`, `Justfile`
- `Procfile`
- `*.properties`

### Documentation
- `.md`, `.mdx`
- `.rst`
- `.txt` (in docs directories)
- `.adoc`

### Build & Deploy
- `Dockerfile`, `Dockerfile.*`
- `docker-compose*.yml`
- `.github/workflows/*.yml`
- `Jenkinsfile`
- `.gitlab-ci.yml`
- `.circleci/config.yml`
- `*.tf` (Terraform)
- `k8s/*.yml`, `kubernetes/*.yml`
- `helm/**/*.yaml`

### Test Files
- `*.test.*`, `*.spec.*`
- `test_*.py`, `*_test.go`
- Files in `tests/`, `test/`, `spec/`, `__tests__/` directories

### Schema & Migration
- `*.sql`
- `*.prisma`
- `*.graphql`, `*.gql`
- `*.proto`
- Migration files in `migrations/`, `db/migrate/`, `alembic/`

## Skip (Do NOT Read)

### Vendor & Generated Directories
- `node_modules/`
- `vendor/` (Go, PHP, Ruby)
- `target/` (Rust, Java)
- `dist/`, `build/`, `out/`
- `__pycache__/`, `*.pyc`
- `.next/`, `.nuxt/`
- `.git/`
- `venv/`, `.venv/`, `env/`, `.env/`
- `site-packages/`
- `.tox/`
- `coverage/`, `.nyc_output/`
- `.terraform/`
- `bower_components/`

### Generated Files
- `*.min.js`, `*.min.css`
- `*.bundle.*`
- `*.generated.*`
- `*.map` (source maps)
- `*.d.ts` in `node_modules`

### Lock Files
- `package-lock.json`
- `yarn.lock`
- `pnpm-lock.yaml`
- `Cargo.lock`
- `poetry.lock`
- `Pipfile.lock`
- `Gemfile.lock`
- `composer.lock`
- `go.sum`

### Binary Assets
- `*.woff`, `*.woff2`, `*.ttf`, `*.eot` (fonts)
- `*.ico`
- `*.exe`, `*.dll`, `*.so`, `*.dylib`
- `*.o`, `*.a`
- `*.jar`, `*.war`, `*.ear`
- `*.zip`, `*.tar`, `*.gz`
- `*.sqlite`, `*.db`

### Large Data Files
- `*.csv` (unless small and in config/seed directory)
- `*.parquet`, `*.avro`
- `*.h5`, `*.hdf5`

## Handling Large Files

### Files 500-2000 lines
Read the full file. Note it as a large file in the analysis.

### Files >2000 lines with repetitive structure
Likely generated or data. Read the first 200 lines + last 50 lines. Note it as "likely generated, read partially."

### Files >2000 lines with unique content
Read the full file. These are important -- they contain significant logic.

## Handling Duplicate Test Patterns

If a test directory contains 10+ test files that follow an identical pattern (same setup, same structure, just different entity name):
1. Read 3 representative test files fully
2. For the rest, note the pattern: "N test files follow the same pattern as [example file]"

This saves context while still capturing the convention.

## Reading Order Priority

When allocating files to agents, prioritize:
1. Entry points (main.*, index.*, app.*, server.*)
2. Configuration files
3. Core business logic
4. API/route definitions
5. Data models and schemas
6. Middleware and utilities
7. Test files
8. Build/deploy configuration

## Image Files in Documentation

These should be READ (not skipped) using the Read tool:
- `*.png`, `*.jpg`, `*.jpeg` -- Read tool renders these visually
- `*.svg` -- Read as text (XML) for structural analysis
- `*.gif`, `*.webp` -- Read tool can display these

Skip images >10MB (note them for manual review).
