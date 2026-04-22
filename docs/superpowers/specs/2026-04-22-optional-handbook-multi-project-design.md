# Design: Optional Handbook + Multi-Project Support for Groundwork

_Date: 2026-04-22_
_Status: Approved_

## Problem

The groundwork skill currently requires two mandatory arguments: a code repo path and a handbook repo path. This limits usage to teams that maintain "The Ansible Engineering Handbook" alongside their code. Additionally, it can only analyze one project at a time, making it impossible to identify overlapping user stories across related projects.

## Goals

1. Make the handbook/docs argument optional so groundwork works as a pure code analyzer when no docs exist
2. Generalize "handbook" into any docs directory via `--docs-dir`
3. Support analyzing multiple projects in a single run
4. Identify overlapping user stories across multiple projects using both code inference and docs analysis

## Non-Goals

- Per-project docs pairing (each project gets its own docs dir)
- Technical comparison across projects (convention drift, dependency version comparison)
- Separate skill commands for single vs multi-project

## Approach: Single Skill with Progressive Enhancement

The skill progressively adds complexity based on arguments provided:

- 1 project, no docs: code-only analysis, lean report
- 1 project, with docs: full analysis with correlation (current behavior)
- N projects, no docs: per-project code analysis + cross-project user story overlap
- N projects, with docs: full per-project analysis + correlation + cross-project overlap

---

## Section 1: Argument Parsing & Input Model

### New Syntax

```
/groundwork <project-path> [<project-path> ...] [--docs-dir=<path>] [--handbook=<path>] [--focus=<area>]
```

### Rules

- All non-flag arguments are treated as project paths (minimum 1 required)
- `--docs-dir=<path>`: optional, points to any documentation directory. Applied globally to all projects for correlation analysis.
- `--handbook=<path>`: optional convenience alias. Sets docs-dir to `<path>` and specifically looks for "The Ansible Engineering Handbook" subdirectory inside it. If found, uses that as the docs path. If not found, falls back to using `<path>` directly as a generic docs dir with a warning.
- `--focus=<area>`: unchanged, applies to all projects.
- `--docs-dir` and `--handbook` are mutually exclusive. Error if both provided.

### Internal State After Parsing

```
PROJECTS = ["/path/a", "/path/b", ...]   # 1 or more
DOCS_PATH = "/path/to/docs" | null        # optional
DOCS_MODE = "handbook" | "generic" | null  # how docs were specified
FOCUS = "architecture" | ... | null        # optional
```

### Backward Compatibility

The old two-positional-arg syntax (`/groundwork <code-repo> <handbook-repo>`) is ambiguous. If exactly two non-flag paths are given and the second contains a directory named "The Ansible Engineering Handbook", treat the second as `--handbook=<path>` and emit a deprecation notice suggesting the new syntax.

---

## Section 2: Phase 1 — Discovery (Adapted for Multi-Project)

Phase 1 runs sequentially in the main context, looping over projects and conditionally handling docs.

### Per-Project Discovery (for each project in PROJECTS)

- 1.1 Validate input: confirm directory exists
- 1.2 Detect tech stack: `detect-stack.sh "$PROJECT"`
- 1.3 Gather repo stats: `repo-stats.sh "$PROJECT"`
- 1.4 Map directory structure
- 1.5 Read orientation files (README, CONTRIBUTING, manifests)

### Global Docs Discovery (only if DOCS_PATH is set)

- 1.6 Validate docs path exists
- 1.7 If `DOCS_MODE=handbook`, locate "The Ansible Engineering Handbook" subdirectory
- 1.8 Gather docs repo stats: `repo-stats.sh "$DOCS_PATH"`
- 1.9 Discover images: `find-images.sh "$DOCS_PATH"` (or handbook subdirectory)

### No Docs Provided

Steps 1.6-1.9 are skipped entirely. No error, no warning.

### Output

Discovery Summary containing:
- Per-project data: tech stack, structure, stats, orientation notes
- Docs data (if present): structure, stats, image manifest
- File inventory for allocation to Phase 2 agents

### Script Changes

`detect-stack.sh`, `repo-stats.sh`, and `find-images.sh` need no changes. They already take a path argument and just get called more times.

---

## Section 3: Phase 2 — Deep Analysis (Adapted)

Phase 2 launches agents per project, with agent behavior adapting based on docs availability.

### Agent Allocation

| Projects | Docs? | Agents spawned |
|----------|-------|----------------|
| 1 project | No docs | 4 agents (code-only variants) |
| 1 project | With docs | 4 agents (current behavior) |
| N projects | No docs | 4 x N agents (code-only, all in parallel) |
| N projects | With docs | 4 x N agents + docs shared across Agent A and D per project |

### Agent Behavior When No Docs

**Agent A (Architecture):**
- Code architecture analysis: unchanged
- Handbook analysis: skipped entirely
- Cross-reference section: skipped
- Output: Architecture Summary (code-only)

**Agent B (Code Patterns):**
- Unchanged. Never depended on docs.

**Agent C (API, Data, Dependencies):**
- Code analysis: unchanged
- "Read any API documentation from the handbook": skipped if no docs
- Output: API & Data Summary

**Agent D (Docs, DevOps, Git History):**
- CI/CD and containerization analysis: unchanged
- Git history analysis: unchanged
- Handbook reading: skipped if no docs
- "Synthesize Getting Started guide": synthesizes from code only if no docs
- Output: DevOps & Git Summary

### When Docs ARE Present

Each project's Agent A and D receive the same `DOCS_PATH`. They analyze docs in relation to their specific project's code. The same handbook page may be read by multiple Agent A instances across projects since each correlates against different code.

### Agent Prompt Templating

Agent prompts in SKILL.md become templates with conditionals:
- `{IF_DOCS}...{/IF_DOCS}` blocks wrap all handbook-related instructions
- `$PROJECT_PATH` replaces the current hardcoded `$0`
- `$DOCS_PATH` replaces `$HANDBOOK_PATH` (with `$HANDBOOK_PATH` still used internally when `DOCS_MODE=handbook`)

---

## Section 4: Phase 3 — Correlation (Conditional)

Phase 3 becomes entirely conditional on `DOCS_PATH` being set.

### No Docs

Phase 3 is skipped completely. Report omits sections 12, 13, and handbook-related parts of section 14.

### With Docs, Single Project

Behaves as today. Bidirectional correlation matrix maps docs to code and code to docs.

### With Docs, Multiple Projects

Correlation runs once but maps docs against all projects. The matrix gains a "Project" column:

```
| Handbook Page | Related Code | Project | Match Type | Confidence |
|---------------|-------------|---------|------------|------------|
| auth-design.md | src/auth/ | project-a | Explicit | Strong |
| auth-design.md | lib/auth/ | project-b | Semantic | Medium |
```

Code-to-docs mapping also gains a project column:

```
| Code Module | Project | Handbook Pages | Coverage |
|-------------|---------|---------------|----------|
| src/auth/ | project-a | auth-design.md | Full |
| lib/auth/ | project-b | auth-design.md | Partial |
```

### Verification Agent (Phase 3.4)

Also conditional on docs. When docs absent, verification still runs but only checks code-related claims. Handbook claim verification is skipped.

---

## Section 5: Phase 3.5 — Cross-Project Overlap (New)

Activates only when `len(PROJECTS) > 1`. Runs after correlation (or after Phase 2 if no docs) and before verification.

### Purpose

Identify overlapping user stories across projects.

### Process

Launch a single Cross-Project Agent that receives all per-project agent summaries from Phase 2 and correlation data from Phase 3 (if available).

**Step 1 — Infer user stories per project:**
- From code: analyze API endpoints, UI components, CLI commands, business logic modules, service names, README feature descriptions
- From docs (if available): look for user stories, requirements docs, feature descriptions, design proposals
- Produce a list of inferred user stories per project with: story name, evidence (files/endpoints/docs), and owning project

**Step 2 — Find overlaps:**
- Compare user story lists across projects
- Match by: identical/similar feature names, overlapping API surface, shared business domain concepts, similar module structures
- Classify each overlap:
  - **Shared dependency**: projects intentionally share this capability
  - **Duplicate implementation**: same user story implemented independently
  - **Complementary**: projects implement different parts of the same user journey
  - **Potential conflict**: overlapping stories with divergent implementations

**Step 3 — Evidence gathering:**
- For each overlap, grep across all projects for concrete evidence: shared API calls, common data models, similar function signatures, matching route patterns
- If docs exist, check whether the overlap is documented or accidental

### Output

Cross-Project Overlap Summary:
- Per-project user story inventory
- Overlap matrix with classification and evidence
- Recommendations (deduplicate, extract shared library, document intentional overlap, etc.)

---

## Section 6: Report Adaptation

### Scenario Matrix

| Scenario | Sections present |
|----------|-----------------|
| 1 project, no docs | 1-11, 15-17 (sections 12-14 omitted) |
| 1 project, with docs | 1-17 (current behavior) |
| N projects, no docs | 1-11 per project + 13.5 (overlap) + 15-17 |
| N projects, with docs | 1-17 per project + 13.5 (overlap) |

### Multi-Project Report Structure

```
# Groundwork: Multi-Project Analysis

## Executive Summary (covers all projects + key overlaps)

## Project: project-a
  ### 1. Project Identity
  ### 2. Architecture
  ### ...through 11 (or 14 if docs)

## Project: project-b
  ### 1. Project Identity
  ### 2. Architecture
  ### ...through 11 (or 14 if docs)

## Cross-Project User Story Overlap
  ### Inferred User Stories per Project
  ### Overlap Matrix
  ### Overlap Classification & Evidence
  ### Recommendations

## 15. Verification Summary (aggregated across all projects)
## 16. Git History (per project, side by side)
## 17. Key Findings (unified, includes cross-project insights)
```

### Single-Project Report

Identical to today's structure. Sections 12-14 disappear when no docs provided. No "Project: X" wrapper.

### HTML Report

Same `report-template.html` handles both scenarios. Multi-project adds sidebar entries per project. Cross-project overlap section gets its own sidebar entry with the overlap matrix as a searchable table.

Report path: `/tmp/groundwork-report.html` for all scenarios.

---

## Section 7: Files Changed

| File | Change |
|------|--------|
| `SKILL.md` | Argument parsing, conditional phases, new Phase 3.5, agent prompt templates, report structure |
| `README.md` | Usage examples, options table, multi-project section |
| `references/report-template.md` | New section 13.5, conditional section markers |
| `assets/report-template.html` | Multi-project sidebar, cross-project overlap section |
| `scripts/*` | No changes needed |

### SKILL.md Metadata Updates

```yaml
argument-hint: <project-path> [<project-path> ...] [--docs-dir=<path>] [--handbook=<path>] [--focus=architecture|patterns|api|testing|devops|docs]
```

Description adds triggers: "analyze these projects together", "compare these codebases", "find overlap between these repos", "what do these projects have in common".

### README.md Updates

- Quick start shows all usage variants
- "What it expects" rewritten: handbook/docs optional
- Options table adds `--docs-dir` and `--handbook`
- New section: "Multi-Project Analysis"
- Architecture diagram updated for conditional Phase 3.5
