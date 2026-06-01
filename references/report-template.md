# Report Template

Use this exact structure for the final analysis report. Fill in every section based on findings from the 4 analysis agents and the correlation phase. If a section is not applicable (e.g., no API endpoints), note "Not applicable" with a brief explanation.

---

```markdown
# Groundwork: {project_name}

{IF MULTI_PROJECT: use "Multi-Project Analysis" as project_name}

_Generated on {date}_
_Projects analyzed: {project_paths}_
{IF DOCS_PATH}_Docs: {docs_path}_{/IF}
_Files analyzed: {total_files_read} source files{IF DOCS_PATH}, {docs_count} docs pages, {images_count} images{/IF}_

---

## Report Personalization

> **Customized for:** {USER_LEVEL_DISPLAY}
> **Tech Stack Familiarity:** {TECH_COMFORT_SUMMARY}

This report has been tailored based on your experience level and familiarity with the technologies in this codebase.

{IF USER_LEVEL == "associate"}
_As an Associate SE, this report includes detailed explanations, a glossary of terms, "start here" recommendations, and learning resources for technologies you're still learning._
{/IF}

{IF USER_LEVEL == "mid"}
_As a Software Engineer, this report includes contributor guides, patterns to follow, and step-by-step guidance for adding features._
{/IF}

{IF USER_LEVEL == "senior"}
_As a Senior SE, this report includes technical debt assessment, scalability analysis, and refactoring recommendations._
{/IF}

{IF USER_LEVEL == "principal"}
_As a Principal SE+, this report leads with strategic insights, architectural risk assessment, and industry best practice comparisons._
{/IF}

---

{IF USER_LEVEL == "principal"}
## Section 0: Strategic Technical Overview

### One-Page Assessment
{High-level assessment of the system's technical posture, maturity, and strategic fit}

### Industry Best Practices Alignment
| Practice | Status | Notes |
|----------|--------|-------|
| 12-Factor App | ... | ... |
| API Design | ... | ... |
| Security Posture | ... | ... |
| Observability | ... | ... |
| CI/CD Maturity | ... | ... |

### Strategic Risks
{Prioritized list of technical, operational, and organizational risks}

### Top Recommendations
{Prioritized list of improvements with estimated impact: High/Medium/Low}

### Questions for the Team
{Gaps in understanding that need human context to resolve}

---
{/IF}

## Executive Summary

{2-3 paragraphs summarizing: what the project is, its architecture at a glance, the tech stack, the state of documentation, and the most important findings. Highlight the biggest code-to-handbook discrepancies.}

---

{IF USER_LEVEL == "associate"}
## Section 1.5: Getting Started Guide (for New Engineers)

### Your First Day Checklist
- [ ] Clone the repository and run the setup steps in Section 11
- [ ] Read the key orientation files: {list top 3-5 files}
- [ ] Set up your local development environment
- [ ] Run the test suite to verify your setup
- [ ] Find a "good first issue" or pair with a team member

### Glossary of Terms
{Table of domain-specific and technical terms used in this codebase with definitions}

| Term | Definition |
|------|------------|
| ... | ... |

### Annotated Directory Map
{Visual directory structure with explanations of what each folder contains and why it matters}

### Start Here: Top 5 Files to Understand First
1. {file_path} - {why this file matters, what you'll learn from it}
2. ...

### Common Beginner Mistakes
- **Mistake**: {description}
  - **Why it happens**: {explanation}
  - **How to avoid it**: {guidance}

---
{/IF}

{IF TECH_COMFORT has any "new" or "learning" entries}
## Technology Primers

{For each technology where user indicated "New to me" or "Learning":}

### {Technology Name} Primer

**What it is:** {One-paragraph explanation of the technology's purpose}

**Why this project uses it:** {Specific reasons this codebase chose this technology}

**Key concepts you'll encounter:**
- **{Concept 1}**: {Brief explanation}
- **{Concept 2}**: {Brief explanation}

**How it's used in this codebase:**
- Primary usage pattern: {description with code example}
- Configuration location: {file path and key settings}

**Quick reference:**
- Official docs: {link}
- Recommended tutorial: {link}
- Key files to study in this codebase:
  1. {file_path} - {what it demonstrates}
  2. ...

**Common gotchas:**
- {Pitfall 1 and how to avoid it}
- {Pitfall 2 and how to avoid it}

---
{/IF}

{IF MULTI_PROJECT}
## Per-Project Analysis

Repeat sections 1-{11 or 14} for each project under a project wrapper:

### Project: {project_name} ({project_path})

{sections 1 through 11 for this project}
{IF DOCS_PATH}{sections 12 through 14 for this project}{/IF}

---
{/IF}

{IF NOT MULTI_PROJECT}
{sections 1 through 11}
{IF DOCS_PATH}{sections 12 through 14}{/IF}
{/IF}

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

{IF USER_LEVEL == "mid"}
## Section 6.5: Contributor's Guide

### How to Add a New Feature
1. {Step with file locations and patterns to follow}
2. ...

### How to Add a New API Endpoint
1. Create the route in `{routes_file_path}`
2. Create the handler in `{handlers_path}`
3. Add validation using {validation_pattern}
4. Add tests in `{tests_path}`
5. Update API documentation

### How to Add Tests
{Testing patterns from this codebase with examples}

**Unit test example (from this codebase):**
```{language}
{actual_test_example_from_codebase}
```

**Integration test example (from this codebase):**
```{language}
{actual_test_example_from_codebase}
```

### Code Review Checklist (Based on Project Conventions)
- [ ] Follows naming conventions (see Section 6)
- [ ] Error handling matches project patterns
- [ ] Has appropriate test coverage
- [ ] Logging follows project standards
- [ ] No hardcoded configuration values
- [ ] {Other project-specific checks}

### Patterns to Follow
{List of patterns with code snippets showing the preferred way to do things}

### Anti-Patterns to Avoid
{List of anti-patterns found in the codebase with examples of what to do instead}

---
{/IF}

{IF USER_LEVEL == "senior"}
## Section 6.5: Technical Health Assessment

### Technical Debt Inventory
| Area | Description | Severity | Effort to Fix | Impact |
|------|-------------|----------|---------------|--------|
| ... | ... | High/Medium/Low | ... | ... |

### Refactoring Opportunities
{Ranked by impact, with specific recommendations}

1. **{Area/Module}** - {Description of opportunity}
   - Current state: {what exists now}
   - Recommended change: {what should be done}
   - Impact: {why this matters}

### Scalability Considerations
- **Current bottlenecks**: {identified bottlenecks in code patterns}
- **Scaling limitations**: {what would break at higher load}
- **Recommendations**: {what to address proactively}

### Security Considerations
{Security-related observations from code analysis - NOT a security audit}

| Area | Observation | Recommendation |
|------|-------------|----------------|
| Authentication | ... | ... |
| Input validation | ... | ... |
| Secrets management | ... | ... |

### Performance Hotspots
{Based on code patterns, not runtime data}

### Dependency Health
| Dependency | Status | Notes |
|------------|--------|-------|
| ... | Current/Outdated/Deprecated/Vulnerable | ... |

---
{/IF}

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

{IF USER_LEVEL == "principal"}
## Section 14.5: Strategic Recommendations

### Architecture Evolution
{Suggested architectural improvements with rationale}

| Recommendation | Rationale | Effort | Priority |
|---------------|-----------|--------|----------|
| ... | ... | High/Medium/Low | P0/P1/P2 |

### Build vs Buy Analysis
{For key components, analysis of whether current approach is optimal}

| Component | Current Approach | Alternative | Recommendation | Rationale |
|-----------|------------------|-------------|----------------|-----------|
| ... | Build (custom) | Buy (vendor X) | Keep/Migrate | ... |

### Team Structure Implications
{Based on code ownership patterns from git history}

- **Module ownership**: {observations about who owns what}
- **Bottlenecks**: {single points of failure in knowledge}
- **Recommendations**: {suggested changes}

### Long-term Maintainability Assessment
{Assessment of the codebase's trajectory}

| Factor | Current State | Trend | Concern Level |
|--------|---------------|-------|---------------|
| Code complexity | ... | Increasing/Stable/Decreasing | High/Medium/Low |
| Test coverage | ... | ... | ... |
| Documentation | ... | ... | ... |
| Dependency freshness | ... | ... | ... |

---
{/IF}

{IF MULTI_PROJECT}

---

## 13.5 Cross-Project User Story Overlap

### User Story Inventory

{For each project, list inferred user stories}

| Project | Story Name | Evidence | Type |
|---------|-----------|----------|------|
| ... | ... | ... | API/UI/CLI/Business Logic |

### Overlap Matrix

| Story | Projects | Classification | Evidence | Recommendation |
|-------|----------|---------------|----------|----------------|
| ... | project-a, project-b | Shared/Duplicate/Complementary/Conflict | ... | ... |

### Overlap Classification Detail

{For each overlap, a 2-3 sentence explanation with:}
- What the overlap is
- Evidence in each project (specific files, endpoints, modules)
- Why it's classified the way it is
- Recommended action

{/IF}

## 15. Verification Summary

{IF MULTI_PROJECT}
_Verification covers all {num_projects} projects{IF DOCS_PATH} and docs{/IF}. Claims are tagged with their source project._
{/IF}

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

{IF MULTI_PROJECT}
### Per-Project Git History
{Repeat git history subsection for each project, side by side}
{/IF}

---

## 17. Key Findings for New Engineers

### Top 10 Things to Know
1. {Most important finding}
2. ...

### Common Pitfalls
- {Things that might trip up a new contributor}

### Where to Start Reading
- {Recommended reading order for someone new to the project}

{IF MULTI_PROJECT}
### Cross-Project Insights
- {Findings that span multiple projects}
- {Key overlaps and their implications}
{/IF}
```
