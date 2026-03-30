# Handbook & Documentation Analysis Checklist

Detailed heuristics for analyzing the quality, coverage, and freshness of "The Ansible Engineering Handbook" and any other documentation. The handbook is the primary documentation repository containing architecture designs, system design plans, and implementation proposals.

## 1. Completeness Assessment

### Structural Completeness
- [ ] Is there a table of contents or index page?
- [ ] Does the handbook cover every major code module/service?
- [ ] Are there architecture overview docs?
- [ ] Are there system design docs for key features?
- [ ] Are there implementation proposal/RFC docs?
- [ ] Is there a getting-started/onboarding guide?
- [ ] Are there operational runbooks?
- [ ] Is there a troubleshooting guide?
- [ ] Are there ADRs (Architecture Decision Records)?

### Per-Module Coverage
For each major code module/directory, check:
- [ ] Does a handbook page exist that describes this module?
- [ ] Does it explain the "why" (design rationale), not just the "what"?
- [ ] Does it document the module's public interface?
- [ ] Does it document the module's dependencies?
- [ ] Does it include architecture diagrams specific to this module?

Produce a coverage table:
```
| Code Module | Has Handbook Page? | Coverage Level | Notes |
|-------------|-------------------|----------------|-------|
| auth/       | Yes               | Full           |       |
| api/        | Partial           | Missing endpoints list | Only covers v1 |
| workers/    | No                | None           | Major gap |
```

## 2. Accuracy Verification

### Code Reference Checking
For each handbook page, extract code references and verify they exist:
- [ ] File paths mentioned in docs -- do they still exist?
- [ ] Function/class names mentioned -- do they still exist?
- [ ] API endpoints documented -- do they match actual routes?
- [ ] Configuration keys referenced -- do they match actual config?
- [ ] CLI commands documented -- do they still work?

Sample at least 10 code references across different handbook pages. For each:
```
| Doc Page | Referenced Code | Type | Exists? | Notes |
|----------|----------------|------|---------|-------|
| auth.md  | src/auth/jwt.py | File | Yes     |       |
| auth.md  | validate_token() | Function | No | Renamed to verify_token() |
```

### Factual Accuracy
- [ ] Do architecture diagrams match current code structure?
- [ ] Do data flow descriptions match actual implementation?
- [ ] Do deployment docs match current CI/CD pipeline?
- [ ] Do dependency lists match current package manifests?

## 3. Freshness Analysis

### Per-File Git Analysis
For each markdown file in the handbook, run:
```bash
git log -1 --format='%ci|%an|%s' -- <filepath>
```

Produce a freshness table:
```
| Doc Page | Last Updated | Author | Days Since Update | Status |
|----------|-------------|--------|-------------------|--------|
| auth.md  | 2025-01-15  | jdoe   | 439               | STALE  |
| api.md   | 2026-03-01  | asmith | 29                | Fresh  |
```

Status thresholds:
- **Fresh**: Updated within 90 days
- **Aging**: 90-180 days since last update
- **Stale**: 180-365 days since last update
- **Critical**: >365 days since last update

### Cross-Reference with Code Changes
For each stale doc, check if the corresponding code area has changed:
```bash
# In code repo, check recent changes in the module the doc describes
git log --oneline --since='<doc_last_update_date>' -- <code_module_path>
```

If code changed significantly after doc was last updated, flag as **high-priority staleness**.

## 4. Image & Diagram Quality

### Inventory
List all images in the handbook:
```
| Image Path | Size | Type | Referenced In | Description |
```

### Quality Assessment
For each image/diagram:
- [ ] Is it legible at normal zoom?
- [ ] Does it have labels and legends?
- [ ] Do component/service names match current code names?
- [ ] Is the diagram style consistent with others in the handbook?
- [ ] Is it an editable format (SVG, draw.io) or rasterized (PNG)?
- [ ] Does the diagram include a date or version indicator?

### Staleness Indicators
- [ ] Do diagram component names match actual module/service names in code?
- [ ] Are all depicted services still present in the codebase?
- [ ] Are there new services in code not shown in diagrams?

## 5. Consistency Assessment

### Template Consistency
- [ ] Do handbook pages follow a consistent template/structure?
- [ ] Are headings structured similarly across docs?
- [ ] Is the level of detail consistent across similar types of docs?
- [ ] Do design docs follow a consistent RFC/proposal format?

### Terminology Consistency
- [ ] Is the same feature/component called by the same name across docs?
- [ ] Are acronyms defined consistently?
- [ ] Do different docs use the same terminology for the same concepts?

### Cross-Page Contradictions
- [ ] Do multiple pages describe the same component differently?
- [ ] Are there conflicting architectural claims?
- [ ] Do different docs specify different versions/requirements?

## 6. Navigation & Discoverability

### Structure
- [ ] Is there a main index/README that links to all handbook sections?
- [ ] Are docs organized by topic/domain or by type (design/ops/reference)?
- [ ] Can a new engineer find the getting-started guide easily?
- [ ] Are related docs cross-linked?

### Searchability
- [ ] Are docs titled descriptively?
- [ ] Do docs use consistent tags or categories?
- [ ] Are important keywords in headings (not buried in paragraphs)?

## 7. Design Proposal Status Tracking

For docs that appear to be design proposals/RFCs/implementation plans:

### Classification
- [ ] **Implemented**: The proposed design is fully reflected in the codebase
- [ ] **Partially Implemented**: Some aspects are in code, others are not
- [ ] **Pending**: The proposal exists but no corresponding code was found
- [ ] **Abandoned**: The proposal exists, related code was removed or never added, and no recent activity

### Evidence
For each proposal, note:
- What code areas correspond to the proposal?
- What aspects are implemented vs missing?
- Is there a status field in the doc itself?
- Does git history show the proposal was discussed/revised?
