# Code-Handbook Correlation Guide

Detailed methodology for building the bidirectional correlation matrix between the code repository and "The Ansible Engineering Handbook". This is the most critical analysis phase -- it connects what the documentation says with what the code actually does.

## Step 1: Extract Code References from Handbook Pages

For each markdown file in the handbook, scan for and extract:

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
For each handbook page, produce:
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

## Step 2: Match Code to Handbook Semantically

Not all connections are explicit. When a handbook page discusses a topic without naming specific files, use semantic matching:

### Topic Extraction
From each handbook page, extract key domain terms:
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
- Handbook page explicitly references file path in the code module
- Handbook page names a class/function that exists in the module
- Code module's README references the handbook page

**Medium match (reasonable confidence)**:
- Handbook page discusses the same domain as the module name suggests
- Service names in handbook match module directory names
- API endpoints in handbook correspond to route files in the module

**Weak match (possible connection)**:
- Keyword overlap between handbook page and code file contents
- Related but not identical terminology (e.g., "user management" in docs, `accounts/` in code)
- Transitive connection through a shared dependency

## Step 3: Build the Correlation Matrix

### Handbook to Code Table

```
| Handbook Page | Related Code Modules | Match Type | Confidence | Key References |
|---------------|---------------------|------------|------------|----------------|
| auth-design.md | src/auth/, src/middleware/auth.py | Explicit | Strong | jwt.py, UserAuthService |
| task-queue.md | src/workers/, src/queue/ | Explicit + Semantic | Strong | TaskWorker, CeleryConfig |
| scaling-plan.md | infrastructure/k8s/ | Semantic | Medium | "horizontal pod autoscaler" |
| data-model.md | src/models/, db/migrations/ | Explicit | Strong | User, Task, Project models |
```

### Code to Handbook Table

```
| Code Module | Handbook Pages | Coverage | Missing Documentation |
|-------------|---------------|----------|----------------------|
| src/auth/ | auth-design.md, security.md | Full | None |
| src/api/ | api-reference.md | Partial | Missing v2 endpoints |
| src/workers/ | task-queue.md | Full | None |
| src/utils/ | (none) | None | No handbook page covers utility functions |
| src/notifications/ | (none) | None | Entire notification system undocumented |
```

## Step 4: Identify Gaps and Issues

### Orphaned Code (no handbook coverage)
List every code module/directory that has zero handbook matches at any confidence level. Prioritize by:
1. Module size (larger modules are bigger gaps)
2. Module importance (entry points, core business logic)
3. Module complexity (measured by file count, import count)

### Stale Documentation
List every handbook page where:
- ALL explicit code references have been renamed, moved, or removed
- The corresponding code module has changed significantly since the doc was last updated
- The doc references features or APIs that no longer exist

### Contradictions
Identify cases where:
- Two handbook pages describe the same code area with conflicting information
- A diagram shows a different architecture than what's described in text
- Different docs specify different versions, requirements, or interfaces for the same component

### Partial Implementations
For design proposals/RFCs in the handbook:
- Compare the proposed design against actual code
- List which aspects are implemented and which are missing
- Flag proposals where implementation diverged significantly from the design

## Step 5: Produce the Connected Summary

For each major code area, create a unified view:

```markdown
### [Module Name]: [One-line description]

**Code**: [what the code actually does, from reading every file]
**Handbook says**: [what the documentation claims, from reading the design docs]
**Alignment**: [Match / Partial match / Divergent / Undocumented]
**Key differences**: [if any]
**Alignment**: [Match / Partial match / Divergent / Undocumented]
```

This gives engineers a single place to see the full picture of each component -- what it does, what it's supposed to do, and where reality and documentation diverge.

## Verification Checklist

Before finalizing the correlation matrix, verify:
- [ ] Every handbook page has been mapped (even if to "no code match found")
- [ ] Every top-level code directory has been checked for handbook coverage
- [ ] Code references have been verified against actual codebase
- [ ] At least 10 explicit code references have been verified (exist/don't exist)
- [ ] Semantic matches have been justified with specific keyword/topic overlap
- [ ] Contradictions have been documented with specific quotes from conflicting docs
