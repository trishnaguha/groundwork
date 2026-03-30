# Report Template

Use this exact structure for the final analysis report. Fill in every section based on findings from the 4 analysis agents and the correlation phase. If a section is not applicable (e.g., no API endpoints), note "Not applicable" with a brief explanation.

---

```markdown
# Groundwork: {project_name}

_Generated on {date} | Code repo: {code_repo_path} | Handbook: {handbook_repo_path}_
_Files analyzed: {total_files_read} source files, {handbook_docs_count} handbook pages, {images_count} images_

---

## Executive Summary

{2-3 paragraphs summarizing: what the project is, its architecture at a glance, the tech stack, the state of documentation, and the most important findings. Highlight the biggest code-to-handbook discrepancies.}

---

## 1. Project Identity

- **Purpose**: {what the project does, in 1-2 sentences}
- **Primary Language**: {language}
- **Framework**: {framework}
- **License**: {license if found}
- **Code Repo Stats**: {total commits} commits, {contributors} contributors, {age} old, {recent_velocity} commits in last 90 days
- **Handbook Repo Stats**: {total commits} commits, {contributors} contributors, {handbook_pages} pages in "The Ansible Engineering Handbook"

---

## 2. Architecture

### High-Level Component Map
{Textual description of the system architecture: what the major components are, how they communicate, what the boundaries are}

### Layer Structure
{If applicable: presentation, business logic, data access, infrastructure layers}

### Architecture from Handbook Diagrams
{For each relevant diagram read from the handbook:
- Image: {filename}
- What it depicts: {description from visual analysis}
- Accuracy: {does it match the actual code? what's different?}
}

### Architecture Divergences
{List specific places where handbook architecture docs don't match the code:
- {handbook says X, code actually does Y}
}

---

## 3. Complete Directory Structure & Module Map

### Code Repository
{Every top-level directory with its purpose, derived from reading ALL files:}
```
project/
  src/           - {description}
  tests/         - {description}
  config/        - {description}
  ...
```

### Module Responsibilities
{For each significant module, a 2-3 sentence description of what it does, based on reading every file in it}

### Handbook Repository
```
handbook-repo/
  The Ansible Engineering Handbook/
    {directory structure}
```

---

## 4. Tech Stack & Dependencies

### Primary Stack
{Language, framework, runtime, package manager}

### Dependencies (Categorized)
| Category | Dependency | Version | Purpose |
|----------|-----------|---------|---------|
| Core Framework | ... | ... | ... |
| Database | ... | ... | ... |
| Authentication | ... | ... | ... |
| Testing | ... | ... | ... |
| DevOps | ... | ... | ... |
| Utilities | ... | ... | ... |

---

## 5. Entry Points & Execution Flows

### Entry Points
{List all entry points: main files, CLI entry points, server start files, worker entry points}

### Primary Execution Flow
{Walk through the main execution path, e.g., HTTP request -> router -> controller -> service -> database -> response}

---

## 6. Coding Patterns & Conventions

{For each pattern, include a real code snippet (3-5 lines) from the codebase}

### Naming Conventions
{Variables, functions, classes, files -- with examples}

### Error Handling
{Dominant pattern with examples}

### Logging & Observability
{Library, format, patterns}

### Configuration Management
{How config is handled}

### Code Comment Style
{Density, format, what gets documented}

### Convention Evolution
{Have conventions changed over time? Based on git history analysis}

---

## 7. Complete API Surface

{Every endpoint, organized by resource/domain}

| Method | Path | Handler | Auth | Description |
|--------|------|---------|------|-------------|
| ... | ... | ... | ... | ... |

### Authentication/Authorization
{How auth works}

### API Versioning
{Strategy if present}

---

## 8. Data Models & Persistence

### Core Models
{Every data model with key fields and relationships}

### Database Technology
{What's used, how it's configured}

### Schema Evolution
{From migration history: how the schema has evolved}

---

## 9. Testing

### Framework & Setup
{Testing framework, configuration, helper utilities}

### Test Organization
{Where tests live, naming convention, types present}

| Test Type | Count | Location | Framework |
|-----------|-------|----------|-----------|
| Unit | ... | ... | ... |
| Integration | ... | ... | ... |
| E2E | ... | ... | ... |

### Mocking Strategy
{How external dependencies are mocked}

---

## 10. Build, CI/CD & Deployment

### Build System
{Build tool, key scripts, build steps}

### CI Pipeline
{Full breakdown of CI steps, in order}

### Deployment
{Where and how the application is deployed}

### Containerization
{Docker setup, K8s configuration if present}

---

## 11. Getting Started (Synthesized)

{Synthesized from both code setup files and handbook onboarding docs}

### Prerequisites
{What needs to be installed}

### Setup Steps
1. {Step-by-step setup instructions}

### Running Locally
{Commands to start the application}

### Running Tests
{Commands to run the test suite}

### Key Environment Variables
| Variable | Purpose | Required | Default |
|----------|---------|----------|---------|
| ... | ... | ... | ... |

---

## 12. Handbook Assessment ("The Ansible Engineering Handbook")

### Document Inventory
| Document | Topic | Last Updated | Author | Status |
|----------|-------|-------------|--------|--------|
| ... | ... | ... | ... | Fresh/Aging/Stale/Critical |

### Coverage Analysis
- **Well-documented areas**: {list}
- **Partially documented**: {list with gaps noted}
- **Undocumented**: {list of code areas with no handbook page}

### Design Proposal Status
| Proposal | Status | Evidence |
|----------|--------|----------|
| ... | Implemented/Partial/Pending/Abandoned | ... |

### Quality Score: {X}/5
{Justification for the score}

### Image/Diagram Inventory
| Image | Depicts | Accurate? | Notes |
|-------|---------|-----------|-------|
| ... | ... | Yes/Partial/No | ... |

---

## 13. Code <-> Handbook Correlation Matrix

### Handbook to Code Mapping
| Handbook Page | Related Code | Match Type | Confidence | Code Refs Verified |
|---------------|-------------|------------|------------|-------------------|
| ... | ... | Explicit/Semantic | Strong/Medium/Weak | X of Y exist |

### Code to Handbook Mapping
| Code Module | Handbook Pages | Coverage | Missing |
|-------------|---------------|----------|---------|
| ... | ... | Full/Partial/None | ... |

---

## 14. Cross-Reference Findings

### Alignment Issues
{Specific places where docs and code disagree}

### Orphaned Code (undocumented)
{Code modules with zero handbook coverage, ordered by importance}

### Stale Documentation
{Handbook pages referencing code that no longer exists}

### Unimplemented Designs
{Design proposals in handbook with no corresponding code}

### Contradictions
{Cases where different handbook pages describe the same thing differently}

---

## 15. Verification Summary

### Verification Gate Results
| Metric | Count |
|--------|-------|
| Total claims checked | ... |
| Passed (confirmed against source) | ... |
| Corrected (auto-fixed) | ... |
| Removed (unverifiable) | ... |
| Flagged (manual review) | ... |
| **Pass rate** | **...%** |

### Confidence Score: {High/Medium/Low}
{Justification: High if >95% pass rate with zero removals. Medium if >85% or minor corrections. Low if significant claims were removed.}

### Corrections Made
{List each claim that was auto-corrected, with before/after}

### Items Removed
{List each claim that could not be verified and was excluded from the report}

### Items Flagged for Manual Review
{List claims that need human verification}

---

## 16. Code Repo Git History

### Code Repository
- **Velocity**: {commits per week/month}
- **Contributors**: {count and top contributors}
- **Hot Areas**: {most frequently changed files/directories in last 90 days}
- **Branching Strategy**: {observed pattern}

---

## 17. Key Findings for New Engineers

### Top 10 Things to Know
1. {Most important finding}
2. ...

### Common Pitfalls
- {Things that might trip up a new contributor}

### Where to Start Reading
- {Recommended reading order for someone new to the project}
```
