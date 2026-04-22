# Code-Documentation Correlation Guide

Detailed methodology for building the bidirectional correlation matrix between code repositories and the documentation directory. When multiple projects are analyzed, the matrix maps docs against all projects. This is the most critical analysis phase -- it connects what the documentation says with what the code actually does.

## Step 1: Extract Code References from Docs Pages

For each markdown file in the docs directory, scan for and extract:

### Explicit References
- **File paths**: Patterns like `src/`, `lib/`, `app/`, `./`, `/`, or any path-like strings with directory separators
- **Module/package names**: References to specific modules, packages, or namespaces
- **Class names**: CamelCase words that match class definitions in code
- **Function/method names**: References to specific functions, especially in code blocks
- **Service names**: Names of services, microservices, or components
- **API endpoints**: URL patterns like `/api/`, HTTP methods (`GET`, `POST`, `PUT`, `DELETE`)
- **Database references**: Table names, collection names, schema references
- **Config keys**: Environment variable names (UPPER_SNAKE_CASE), config file keys
- **CLI commands**: Command-line invocations referencing project scripts or binaries

### From Code Blocks
Scan fenced code blocks (` ``` `) in markdown for:
- Import statements that reference project modules
- File paths in comments or examples
- Configuration snippets with key names
- Command-line examples

### From Image Captions and Diagrams
- Alt text on images may reference component names
- Diagram file names often indicate what they depict (e.g., `auth-flow.png`)
- SVG files (read as text) contain labels and text elements

### Output Format
For each docs page, produce:
```
Page: architecture/auth-design.md
Explicit References:
  - src/auth/jwt.py (file path, line 23)
  - UserAuthService (class name, line 45)
  - /api/v1/auth/login (endpoint, line 67)
  - JWT_SECRET_KEY (config key, line 89)
  - auth-flow.png (diagram, line 12)
Implicit Topics:
  - authentication, authorization, JWT, OAuth2, session management
```

## Step 2: Match Code to Docs Semantically

Not all connections are explicit. When a docs page discusses a topic without naming specific files, use semantic matching:

### Topic Extraction
From each docs page, extract key domain terms:
- Section headings as topic indicators
- Frequently used nouns and technical terms
- Problem domain language (not generic programming terms)

### Code Module Matching
For each code module/directory, identify its domain:
- Directory name as primary indicator
- README or docstring in the module
- Import graph (what it imports/exports suggests its domain)
- File names within the module

### Matching Confidence Levels

**Strong match (high confidence)**:
- Docs page explicitly references file path in the code module
- Docs page names a class/function that exists in the module
- Code module's README references the docs page

**Medium match (reasonable confidence)**:
- Docs page discusses the same domain as the module name suggests
- Service names in docs match module directory names
- API endpoints in docs correspond to route files in the module

**Weak match (possible connection)**:
- Keyword overlap between docs page and code file contents
- Related but not identical terminology (e.g., "user management" in docs, `accounts/` in code)
- Transitive connection through a shared dependency

## Step 3: Build the Correlation Matrix

### Docs to Code Table

```
| Docs Page | Related Code Modules | Match Type | Confidence | Key References |
|---------------|---------------------|------------|------------|----------------|
| auth-design.md | src/auth/, src/middleware/auth.py | Explicit | Strong | jwt.py, UserAuthService |
| task-queue.md | src/workers/, src/queue/ | Explicit + Semantic | Strong | TaskWorker, CeleryConfig |
| scaling-plan.md | infrastructure/k8s/ | Semantic | Medium | "horizontal pod autoscaler" |
| data-model.md | src/models/, db/migrations/ | Explicit | Strong | User, Task, Project models |
```

### Code to Docs Table

```
| Code Module | Docs Pages | Coverage | Missing Documentation |
|-------------|---------------|----------|----------------------|
| src/auth/ | auth-design.md, security.md | Full | None |
| src/api/ | api-reference.md | Partial | Missing v2 endpoints |
| src/workers/ | task-queue.md | Full | None |
| src/utils/ | (none) | None | No docs page covers utility functions |
| src/notifications/ | (none) | None | Entire notification system undocumented |
```

### Multi-Project Matrix

When analyzing multiple projects, add a Project column to both tables:

```
| Docs Page | Related Code Modules | Project | Match Type | Confidence | Key References |
|-----------|---------------------|---------|------------|------------|----------------|
| auth-design.md | src/auth/ | project-a | Explicit | Strong | jwt.py |
| auth-design.md | lib/auth/ | project-b | Semantic | Medium | AuthProvider |
```

```
| Code Module | Project | Docs Pages | Coverage | Missing Documentation |
|-------------|---------|-----------|----------|----------------------|
| src/auth/ | project-a | auth-design.md | Full | None |
| lib/auth/ | project-b | auth-design.md | Partial | Missing OAuth flow |
```

A single docs page may correlate with modules in different projects. This is expected and highlights shared documentation.

## Step 4: Identify Gaps and Issues

### Orphaned Code (no docs coverage)
List every code module/directory that has zero docs matches at any confidence level. Prioritize by:
1. Module size (larger modules are bigger gaps)
2. Module importance (entry points, core business logic)
3. Module complexity (measured by file count, import count)

### Stale Documentation
List every docs page where:
- ALL explicit code references have been renamed, moved, or removed
- The corresponding code module has changed significantly since the doc was last updated
- The doc references features or APIs that no longer exist

### Contradictions
Identify cases where:
- Two docs pages describe the same code area with conflicting information
- A diagram shows a different architecture than what's described in text
- Different docs specify different versions, requirements, or interfaces for the same component

### Partial Implementations
For design proposals/RFCs in the docs:
- Compare the proposed design against actual code
- List which aspects are implemented and which are missing
- Flag proposals where implementation diverged significantly from the design

## Step 5: Produce the Connected Summary

For each major code area, create a unified view:

```markdown
### [Module Name]: [One-line description]

**Code**: [what the code actually does, from reading every file]
**Docs say**: [what the documentation claims, from reading the design docs]
**Alignment**: [Match / Partial match / Divergent / Undocumented]
**Key differences**: [if any]
**Alignment**: [Match / Partial match / Divergent / Undocumented]
```

This gives engineers a single place to see the full picture of each component -- what it does, what it's supposed to do, and where reality and documentation diverge.

## Verification Checklist

Before finalizing the correlation matrix, verify:
- [ ] Every docs page has been mapped (even if to "no code match found")
- [ ] Every top-level code directory in each project has been checked for docs coverage
- [ ] Code references have been verified against actual codebase
- [ ] At least 10 explicit code references have been verified (exist/don't exist)
- [ ] Semantic matches have been justified with specific keyword/topic overlap
- [ ] Contradictions have been documented with specific quotes from conflicting docs
