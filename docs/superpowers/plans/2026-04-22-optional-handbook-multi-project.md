# Optional Handbook + Multi-Project Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the handbook argument optional, generalize it to `--docs-dir`, support multiple project paths, and add cross-project user story overlap analysis.

**Architecture:** Single skill with progressive enhancement. The skill detects how many projects and whether docs are provided, then activates only the relevant phases. A new Phase 3.5 launches a Cross-Project Agent when multiple projects are given.

**Tech Stack:** Claude Code skill (SKILL.md markdown), shell scripts (unchanged), HTML template

**Spec:** `docs/superpowers/specs/2026-04-22-optional-handbook-multi-project-design.md`

---

### Task 1: SKILL.md — Frontmatter and Argument Parsing

**Files:**
- Modify: `SKILL.md:1-31`

- [ ] **Step 1: Update frontmatter metadata**

Replace lines 1-19 of `SKILL.md` with:

```yaml
---
name: groundwork
description: >-
  This skill should be used when the user asks to "analyze this codebase",
  "give me a complete picture of this project", "deep dive into this repo",
  "understand the architecture", "analyze the code and docs together",
  "what does this project do", "how is this codebase structured",
  "review this repository", "read all the code", "analyze the handbook",
  "analyze the engineering handbook", "read the Ansible handbook",
  "run groundwork", "do groundwork analysis",
  "analyze these projects together", "compare these codebases",
  "find overlap between these repos", "what do these projects have in common",
  or wants a holistic understanding of one or more code repositories,
  optionally correlated with an engineering handbook or documentation directory.
  Reads ALL source files comprehensively. Optionally correlates with docs.
  Analyzes git history for each code repo. Every data point is verified
  against source files before report generation.
argument-hint: <project-path> [<project-path> ...] [--docs-dir=<path>] [--handbook=<path>] [--focus=architecture|patterns|api|testing|devops|docs]
tools: Read, Write, Glob, Grep, Bash
---
```

- [ ] **Step 2: Rewrite the title and overview paragraph**

Replace the title and first paragraph (line 21-22 of current SKILL.md):

```markdown
# Groundwork: Multi-Project Codebase Analyzer

Perform a comprehensive analysis of one or more code repositories, optionally correlated with an engineering handbook or documentation directory. Read ALL source files in each project. When docs are provided, build a full correlation matrix between code and documentation. When multiple projects are given, identify overlapping user stories across codebases. Analyze git history for each code repo. Every data point is verified against source files before report generation -- nothing makes it into the report without proof it exists in the repos.
```

- [ ] **Step 3: Rewrite the Inputs section**

Replace lines 26-31 (the current `## Inputs` section) with:

```markdown
## Inputs

- `<project-path>`: One or more paths to code repositories (at least one required).
- `--docs-dir=<path>`: Optional path to a documentation directory. Applied globally for correlation analysis against all projects.
- `--handbook=<path>`: Optional convenience alias. Looks for "The Ansible Engineering Handbook" subdirectory inside `<path>`. If found, uses that as the docs path. If not found, falls back to using `<path>` directly as a generic docs dir (with a warning). Mutually exclusive with `--docs-dir`.
- `--focus=<area>`: Optional focus area for expanded analysis. Values: architecture, patterns, api, testing, devops, docs.

Parse `$ARGUMENTS` by splitting on spaces. All non-flag tokens are project paths. Extract `--docs-dir=X`, `--handbook=X`, and `--focus=X` flags. Error if both `--docs-dir` and `--handbook` are provided.

### Backward Compatibility

If exactly two non-flag paths are given and the second contains a directory named "The Ansible Engineering Handbook", treat the second as `--handbook=<path>` and emit a deprecation notice: "Note: Detected handbook repo as second argument. In the future, please use --handbook=<path> explicitly. Treating second path as handbook."

### Internal State

After parsing, set:
- `PROJECTS` = list of project paths (1 or more)
- `DOCS_PATH` = resolved docs directory path, or null if no docs provided
- `DOCS_MODE` = "handbook" (--handbook with Ansible handbook found), "generic" (--docs-dir or --handbook fallback), or null
- `FOCUS` = focus area string or null
- `MULTI_PROJECT` = true if len(PROJECTS) > 1
```

- [ ] **Step 4: Commit**

```bash
git add SKILL.md
git commit -m "feat(skill): update frontmatter and argument parsing for optional docs + multi-project"
```

---

### Task 2: SKILL.md — Phase 1 Discovery

**Files:**
- Modify: `SKILL.md:33-83` (Phase 1 section)

- [ ] **Step 1: Rewrite Phase 1 header and intro**

Replace the current Phase 1 section (lines 33-83) with:

```markdown
## Phase 1: Discovery & Orientation

Run these steps directly (not in sub-agents) to produce context that all subsequent agents need.

### 1.1 Validate Inputs

For each path in `PROJECTS`, verify it exists and is a directory. If any path is invalid, output an error and stop.

If `DOCS_PATH` is set:
- Verify `DOCS_PATH` exists and is a directory.
- If `DOCS_MODE=handbook`, locate the directory named **"The Ansible Engineering Handbook"** within `DOCS_PATH`. If found, set `HANDBOOK_PATH="$DOCS_PATH/The Ansible Engineering Handbook"` and use that as the effective docs path for analysis. If not found, emit a warning: "Could not find 'The Ansible Engineering Handbook' directory in $DOCS_PATH. Using $DOCS_PATH directly as documentation directory." Set `DOCS_MODE=generic`.

### 1.2 Per-Project Discovery

For each project in `PROJECTS`, run the following (parallelize across projects where possible):

#### 1.2.1 Detect Tech Stack

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/detect-stack.sh" "$PROJECT_PATH"
```

#### 1.2.2 Gather Repo Statistics

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/repo-stats.sh" "$PROJECT_PATH"
```

#### 1.2.3 Map Directory Structure

Use Bash to list the directory structure, excluding artifact directories (.git, node_modules, vendor, target, __pycache__, dist, build, .next, venv, .venv).

#### 1.2.4 Read Orientation Files

Read key orientation files from the project if they exist: README.md, CONTRIBUTING.md, ARCHITECTURE.md, and the primary language manifest (package.json, Cargo.toml, go.mod, pyproject.toml, pom.xml, etc.).

### 1.3 Docs Discovery (only if DOCS_PATH is set)

Skip this entire subsection if `DOCS_PATH` is null.

#### 1.3.1 Gather Docs Repo Statistics

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/repo-stats.sh" "$DOCS_PATH"
```

#### 1.3.2 Discover Images

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/find-images.sh" "$DOCS_PATH"
```

If `DOCS_MODE=handbook` and `HANDBOOK_PATH` is set, run on `HANDBOOK_PATH` instead.

### 1.4 Read File Strategy

Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` to understand what to read vs skip.

### 1.5 Produce Discovery Summary

Compile all findings into a Discovery Summary containing:
- Per-project data: detected tech stack, directory structure, repo stats, orientation notes
- Docs data (if DOCS_PATH is set): structure, stats, image manifest
- File inventory for allocation to Phase 2 agents
- Flags: `DOCS_PATH`, `DOCS_MODE`, `MULTI_PROJECT`, `FOCUS`
```

- [ ] **Step 2: Commit**

```bash
git add SKILL.md
git commit -m "feat(skill): rewrite Phase 1 for multi-project loop and conditional docs"
```

---

### Task 3: SKILL.md — Phase 2 Agent Prompts

**Files:**
- Modify: `SKILL.md` (Phase 2 section, currently lines 84-176)

- [ ] **Step 1: Rewrite Phase 2 header and agent allocation**

Replace the Phase 2 header and intro with:

```markdown
## Phase 2: Deep Analysis (Parallel Sub-Agents)

Launch Agent sub-agents concurrently in a single message. Pass each agent the Discovery Summary from Phase 1. **Critical: agents must read ALL files in their domain, not samples.**

### Agent Allocation

For each project in `PROJECTS`, launch 4 agents (A, B, C, D). All agents across all projects run in parallel in a single message. For N projects, this means 4×N agents.

When `DOCS_PATH` is null, agents A and D use their code-only variants (handbook instructions are omitted). When `DOCS_PATH` is set, agents A and D include docs analysis instructions.
```

- [ ] **Step 2: Rewrite Agent A prompt with conditionals**

```markdown
### Agent A: Architecture & Structure (per project)

Provide Agent A with the Discovery Summary and these instructions:

> Analyze the architecture of the code repository at `$PROJECT_PATH`.
>
> **Code architecture analysis (read ALL files):**
> - Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` for what to read vs skip
> - Read ALL entry point files and trace primary execution flows
> - Read ALL files in each code module/package to understand module responsibilities
> - Identify architectural boundaries: layers, modules, service boundaries
> - Map import/dependency graphs across the full codebase
> - Identify communication patterns: HTTP, queues, shared DB, events, gRPC
> - Read ADRs (Architecture Decision Records) if they exist in the code repo
>
> {IF DOCS_PATH is set}
> **Documentation analysis (read EVERY file):**
> - Read ALL markdown files in `$DOCS_PATH` -- every architecture doc, system design plan, and implementation proposal, in full
> - Read ALL images in the docs directory using the Read tool (it renders PNG/JPG visually)
> - For each doc, note: title, topic, what code areas it describes, key design decisions
>
> **Cross-reference:**
> - For each diagram/doc, compare what it describes vs what the code at `$PROJECT_PATH` actually implements
> - Note divergences, missing components, extra components not in docs
> {/IF}
>
> Output a structured Architecture Summary with: component map, layer structure, execution flows{IF DOCS_PATH is set}, and diagram-to-code cross-reference{/IF}.
```

- [ ] **Step 3: Rewrite Agent B prompt (unchanged but templated)**

```markdown
### Agent B: Code Patterns & Conventions (per project)

Provide Agent B with the Discovery Summary and these instructions:

> Analyze coding patterns and conventions in the code repository at `$PROJECT_PATH`.
>
> - Read `${CLAUDE_SKILL_DIR}/references/code-analysis-checklist.md` for the full analysis heuristics
> - Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` for what to read vs skip
> - **Read ALL source files across every directory** -- skip only: node_modules, vendor, target, dist, build, __pycache__, .git, generated files (*.min.js, *.bundle.*, *.generated.*, lock files), binary assets
> - For each directory/module, analyze: naming conventions, error handling patterns, code structure
> - Analyze testing: framework, file organization, mocking approach, fixture patterns, assertion style
> - Analyze logging: structured vs unstructured, log levels, tracing, metrics
> - Analyze configuration: env vars, config files, feature flags
> - Analyze code comments: density, format (JSDoc/docstrings/inline), what they document
> - Check for linting/formatting config and enforced rules
> - Include concrete code snippets (3-5 lines) as examples of each convention found
> - **Git analysis**: Run `git log --format='%ci' --diff-filter=A -- <path>` on files to check if conventions are consistent over time. Do newer files follow different patterns than older ones?
>
> Output a Comprehensive Coding Conventions Summary with real code examples from the codebase.
```

- [ ] **Step 4: Rewrite Agent C prompt with conditionals**

```markdown
### Agent C: API Surface, Data Models & Dependencies (per project)

Provide Agent C with the Discovery Summary and these instructions:

> Analyze the complete API surface, data models, and dependencies in the code repository at `$PROJECT_PATH`.
>
> - Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` for what to read vs skip
> - Read ALL route/endpoint definition files (every controller, handler, route file)
> - Read ALL data model/schema definitions (ORM models, protobuf, JSON schemas, GraphQL schemas, migration files)
> - Map the complete public API surface: every endpoint, every exported function/class
> - Read ALL database migration files to understand schema evolution
> - Identify the full persistence layer by reading config and connection code
> - Analyze the complete dependency manifest: every dependency, categorized (core framework, utilities, dev tools, testing, deployment)
> - Read ALL external service integration code (third-party API clients, SDK usage)
> - **Git analysis**: Run `git log --oneline --since='6 months ago' -- <api-paths>` to track how the API surface and data models have evolved recently
>
> {IF DOCS_PATH is set}
> - Read any API documentation from the docs directory at `$DOCS_PATH`
> {/IF}
>
> Output a Complete API & Data Summary with every endpoint, every data model, full dependency analysis, and evolution history.
```

- [ ] **Step 5: Rewrite Agent D prompt with conditionals**

```markdown
### Agent D: Documentation, DevOps & Code Git History (per project)

Provide Agent D with the Discovery Summary and these instructions:

> Analyze DevOps setup and code repo git history for the code repository at `$PROJECT_PATH`.
>
> - Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` for what to read vs skip
> - Read ALL CI/CD configuration files (GitHub Actions workflows, Jenkinsfile, .gitlab-ci.yml, Makefile, scripts/)
> - Read ALL containerization files (every Dockerfile, docker-compose.yml, K8s manifests, Helm charts)
> - Analyze complete developer setup: prerequisites, setup scripts, environment variables
>
> {IF DOCS_PATH is set}
> - Read `${CLAUDE_SKILL_DIR}/references/docs-analysis-checklist.md` for documentation quality heuristics
> - **Read ALL remaining docs files** not covered by Agent A (operational docs, runbooks, onboarding guides, troubleshooting docs)
> - Read ALL documentation images not handled by Agent A
> {/IF}
>
> **Code repo git history analysis (`$PROJECT_PATH`):**
> - `git log --oneline -50` for recent commits
> - `git shortlog -sn --no-merges` for contributor analysis
> - `git log --numstat --since='90 days ago'` for recent areas of active development
> - Branching strategy and merge patterns
>
> Synthesize a "Getting Started" guide from code setup files{IF DOCS_PATH is set} and docs onboarding content{/IF}.
>
> Output a DevOps & Git Summary with code repo git analysis.
```

- [ ] **Step 6: Commit**

```bash
git add SKILL.md
git commit -m "feat(skill): rewrite Phase 2 agent prompts with conditional docs and per-project templating"
```

---

### Task 4: SKILL.md — Phase 3 Correlation (Conditional)

**Files:**
- Modify: `SKILL.md` (Phase 3 section, currently lines 177-266)

- [ ] **Step 1: Rewrite Phase 3 as conditional**

Replace the entire Phase 3 section with:

```markdown
## Phase 3: Correlation & Cross-Reference (only if DOCS_PATH is set)

**Skip this entire phase if `DOCS_PATH` is null.** Proceed directly to Phase 3.5 (if multi-project) or Phase 4 (if single project).

After all Phase 2 agents complete, this is the most critical phase when docs are available. Read `${CLAUDE_SKILL_DIR}/references/correlation-guide.md` for the detailed methodology.

### 3.1 Build the Correlation Matrix

Create a bidirectional map connecting every docs page to its corresponding code areas.

**Docs to Code mapping**: For each docs page, extract all references to code constructs (file paths, module names, class names, function names, service names, API endpoints, database table names, config keys). Verify each reference exists in the actual code using Grep.

When `MULTI_PROJECT` is true, check references against ALL projects and include a Project column:

```
| Docs Page | Referenced Code | Project | Exists? |
```

When single project, omit the Project column:

```
| Docs Page | Referenced Code | Exists? |
```

**Code to Docs mapping**: For each code module/directory in each project, list all docs pages that reference it.

When `MULTI_PROJECT` is true:

```
| Code Module | Project | Docs Pages | Coverage Level | Gaps |
```

When single project, omit the Project column:

```
| Code Module | Docs Pages | Coverage Level | Gaps |
```

**Semantic correlation**: Match docs pages to code areas by topic/domain keywords even when explicit references are absent. If a docs page discusses "task execution" and a project has a `task_executor/` module, correlate them.

### 3.2 Deep Cross-Reference Analysis

Using the correlation matrix, analyze:
- Architecture diagrams vs actual code structure
- API docs vs actual endpoints
- Getting-started docs vs actual setup requirements
- Code modules with **zero docs coverage** (orphaned code)
- Docs pages referencing **nonexistent code** (stale docs)
- **Design proposals**: implemented vs pending vs abandoned
- **Major code components** with no design doc explaining the "why"
- **Consistency**: Do different docs pages describe the same code area consistently or contradict each other?

When `MULTI_PROJECT` is true, also analyze:
- Which docs pages are relevant to multiple projects
- Whether coverage differs significantly across projects for the same docs

### 3.3 Produce Connected Summary

- Aggregate the Phase 2 agent summaries (per project)
- Overlay the correlation matrix
- For each major code area in each project, produce a mini-summary combining: what the code does + what the docs say + where they align or diverge
- Identify top 10 key findings for new engineers
```

- [ ] **Step 2: Commit**

```bash
git add SKILL.md
git commit -m "feat(skill): make Phase 3 correlation conditional on docs presence"
```

---

### Task 5: SKILL.md — New Phase 3.5 Cross-Project Overlap

**Files:**
- Modify: `SKILL.md` (insert after Phase 3, before verification)

- [ ] **Step 1: Add Phase 3.5 section**

Insert after Phase 3 (or after Phase 2 reference if no docs):

```markdown
## Phase 3.5: Cross-Project User Story Overlap (only if MULTI_PROJECT is true)

**Skip this phase if only one project is being analyzed.**

This phase identifies overlapping user stories -- features or capabilities that span or are duplicated across multiple projects.

### 3.5.1 Launch Cross-Project Agent

Launch a single **Cross-Project Agent** that receives all per-project agent summaries from Phase 2 and correlation data from Phase 3 (if available). Provide these instructions:

> Analyze user story overlap across the following projects: `$PROJECTS` (list all project paths).
>
> **Step 1 -- Infer user stories per project:**
>
> For each project, identify user-facing capabilities by analyzing:
> - From code: API endpoints and their resource domains, UI components and pages, CLI commands, business logic modules, service names, README feature descriptions
> - {IF DOCS_PATH is set} From docs at `$DOCS_PATH`: user stories, requirements docs, feature descriptions, design proposals {/IF}
>
> Produce a list of inferred user stories per project. Each user story should have:
> - **Story name**: A concise name for the capability (e.g., "User Authentication", "Task Scheduling", "Report Generation")
> - **Evidence**: The files, endpoints, modules, or docs that support this inference
> - **Project**: Which project this story belongs to
>
> **Step 2 -- Find overlaps:**
>
> Compare user story lists across all projects. Match by:
> - Identical or similar feature/capability names
> - Overlapping API surface (same endpoints, resources, or URL patterns)
> - Shared business domain concepts (same entity names, similar data models)
> - Similar module structures serving the same purpose
>
> Classify each overlap:
> - **Shared dependency**: Projects intentionally share this capability (e.g., both call a common auth service)
> - **Duplicate implementation**: Same user story implemented independently in both projects
> - **Complementary**: Projects implement different parts of the same user journey (e.g., one handles creation, another handles reporting)
> - **Potential conflict**: Overlapping stories with divergent implementations that could cause inconsistency
>
> **Step 3 -- Evidence gathering:**
>
> For each identified overlap, grep across all projects for concrete evidence:
> - Shared API calls or client code pointing to the same service
> - Common data models or schema definitions
> - Similar function signatures or class hierarchies
> - Matching route patterns or endpoint paths
> - {IF DOCS_PATH is set} Check whether the overlap is documented in the docs or appears to be accidental {/IF}
>
> **Output a Cross-Project Overlap Summary containing:**
> - Per-project user story inventory (table: story name, evidence summary, project)
> - Overlap matrix (table: story name, projects involved, overlap type, evidence, classification)
> - Recommendations: actionable suggestions for each overlap (deduplicate into shared library, document the intentional overlap, extract common service, resolve conflicting implementations, etc.)
```

- [ ] **Step 2: Commit**

```bash
git add SKILL.md
git commit -m "feat(skill): add Phase 3.5 cross-project user story overlap analysis"
```

---

### Task 6: SKILL.md — Verification and Report Generation

**Files:**
- Modify: `SKILL.md` (Phase 3.4 verification and Phase 4 report sections)

- [ ] **Step 1: Rewrite the verification section**

Replace the current Phase 3.4 verification section with:

```markdown
### 3.6 Verification Against Source of Truth

**This is a mandatory gate. No report is generated until verification passes.**

Read `${CLAUDE_SKILL_DIR}/references/verification-checklist.md` for the detailed verification procedures.

Every factual claim from the Phase 2 agent summaries{IF DOCS_PATH is set}, the correlation matrix,{/IF}{IF MULTI_PROJECT} and the cross-project overlap analysis{/IF} must be traced back to an actual file in the repos. Launch a **Verification Agent** with these instructions:

> Verify every factual claim in the analysis against the actual source files. Read `${CLAUDE_SKILL_DIR}/references/verification-checklist.md` for procedures.
>
> **File existence:** For every file path cited anywhere in the analysis, run Glob to confirm it exists in the appropriate project repo. If a file is not found, flag it for removal.
>
> **Code snippets:** For every code example in the conventions section, Grep for that exact text in the cited file. If the snippet doesn't match, re-read the file and correct or remove it.
>
> **API endpoints:** For every endpoint in the API surface table, Grep for the route pattern in the relevant project's code repo. Confirm method, path, and handler all exist.
>
> **Dependencies:** For every dependency listed, Read the package manifest in the relevant project and confirm the name and version match.
>
> **Data models:** For every model/schema described, Read the model file and confirm fields and relationships exist.
>
> {IF DOCS_PATH is set}
> **Documentation claims:** For every claim about what a docs page says, Read that page and confirm the claim is accurate. For correlation matrix entries, confirm the docs page actually references or describes the correlated code area.
> {/IF}
>
> **Git statistics:** Re-run key git commands (commit count, contributor count, recent velocity) for each project repo and compare with reported numbers. Replace any mismatches with the verified numbers.
>
> **Architecture claims:** For claims like "Service A calls Service B via HTTP", Grep for the actual HTTP call in the relevant project's code.
>
> {IF DOCS_PATH is set}
> **Diagram analysis:** For claims about what diagrams depict, re-read the image to confirm.
>
> **Design proposal status:** For proposals marked "implemented", verify the claimed code exists via Glob + Grep.
> {/IF}
>
> {IF MULTI_PROJECT}
> **Cross-project overlap claims:** For each overlap identified in Phase 3.5, verify:
> - The user story evidence exists in both projects (grep for the cited files, endpoints, or modules)
> - The overlap classification is accurate (e.g., if classified as "duplicate implementation", confirm both projects actually implement it independently)
> {/IF}
>
> For each claim, record: PASSED (confirmed), CORRECTED (fixed minor inaccuracy), REMOVED (unverifiable), or FLAGGED (needs manual review).
>
> **Auto-correct:** If a file path has a typo but a similar file exists, correct it. If a snippet is slightly off, replace with actual text. If a git stat is wrong, replace with the re-verified number. If a claim cannot be verified at all, remove it from the analysis rather than include unverified data.
>
> Output a Verification Summary with counts of PASSED, CORRECTED, REMOVED, FLAGGED and the details of each.

After the verification agent completes, merge its corrections into the analysis data. Remove all unverified claims. The verification summary will be included in the final report.
```

- [ ] **Step 2: Rewrite the report generation section**

Replace the current section 3.5/3.6 report generation with:

```markdown
### 3.7 Generate Final Report (Markdown)

Read `${CLAUDE_SKILL_DIR}/references/report-template.md` for the output structure.

**Single project, no docs:** Produce sections 1-11, 15-17. Omit sections 12 (Handbook Assessment), 13 (Correlation Matrix), and 14 (Cross-Reference Findings). Use the flat report structure (no project wrapper).

**Single project, with docs:** Produce all sections 1-17. Use the flat report structure (current behavior).

**Multiple projects, no docs:** Produce a multi-project report:
- Executive Summary covering all projects and key overlaps
- For each project: sections 1-11 under a "## Project: {project_name}" wrapper
- Section 13.5: Cross-Project User Story Overlap
- Sections 15-17 with aggregated/unified data

**Multiple projects, with docs:** Produce a multi-project report:
- Executive Summary covering all projects, correlations, and overlaps
- For each project: sections 1-14 under a "## Project: {project_name}" wrapper
- Section 13.5: Cross-Project User Story Overlap
- Sections 15-17 with aggregated/unified data

Only include data that passed verification.

### 3.8 Generate HTML Report

After producing the markdown report, also generate an interactive HTML version:

1. Read the HTML template at `${CLAUDE_SKILL_DIR}/assets/report-template.html`
2. Create a filled-in copy of the template with all analysis data. Replace:
   - `__PROJECT_NAME__` with the project name (or "Multi-Project Analysis" if multiple projects)
   - `__DATE__` with today's date
   - `__REPO_PATHS__` with the project paths (replaces `__CODE_REPO_PATH__`)
   - `__DOCS_PATH__` with the docs path (or "N/A" if no docs; replaces `__HANDBOOK_REPO_PATH__`)
   - `__FILES_COUNT__`, `__DOCS_COUNT__`, `__IMAGES_COUNT__` with actual counts (DOCS_COUNT and IMAGES_COUNT are 0 if no docs)
   - Each `<!-- __CONTENT_xxx__ -->` comment with the actual HTML content for that section
   - For multi-project: populate `<!-- __CONTENT_PROJECTS__ -->` with per-project section HTML
   - For multi-project: populate `<!-- __CONTENT_OVERLAP__ -->` with cross-project overlap HTML
   - Omit docs-related sections from sidebar and body when `DOCS_PATH` is null

3. Use the template's built-in CSS classes for rich rendering (same as current behavior).

4. Write the HTML file to `/tmp/groundwork-report.html`
5. Open it in the browser: `open /tmp/groundwork-report.html`
6. Tell the user the file path
```

- [ ] **Step 3: Rewrite Phase 4 Interactive Q&A**

Replace the current Phase 4 section with:

```markdown
## Phase 4: Interactive Q&A

After producing both reports, end with this message:

---

**Single project, no docs:**

**Groundwork complete.** Read {N} source files across {M} modules. {V} claims verified against source files ({pass_rate}% pass rate).

HTML report: `/tmp/groundwork-report.html` (opened in browser)

---

**Single project, with docs:**

**Groundwork complete.** Read {N} source files across {M} modules and {P} documents in the docs directory. {V} claims verified against source files ({pass_rate}% pass rate).

HTML report: `/tmp/groundwork-report.html` (opened in browser)

---

**Multiple projects:**

**Groundwork complete.** Analyzed {num_projects} projects: {project_names}. Read {N} total source files{IF DOCS_PATH is set} and {P} documents{/IF}. Identified {overlap_count} user story overlaps. {V} claims verified ({pass_rate}% pass rate).

HTML report: `/tmp/groundwork-report.html` (opened in browser)

---

Follow-up prompts:
- "How is [feature] implemented?"
- "Walk me through the [X] execution flow"
{IF DOCS_PATH is set}
- "What does the docs say about [component] vs what the code does?"
- "Which docs pages are most out of date?"
{/IF}
{IF MULTI_PROJECT}
- "Show me the overlap between [project-a] and [project-b] for [feature]"
- "Which user stories are duplicated across projects?"
{/IF}
- "What would I need to do to add a new [endpoint/feature/module]?"

The full analysis context is available for deep follow-ups.
```

- [ ] **Step 4: Commit**

```bash
git add SKILL.md
git commit -m "feat(skill): adapt verification, report generation, and Q&A for all scenarios"
```

---

### Task 7: Report Template — Multi-Project and Conditional Sections

**Files:**
- Modify: `references/report-template.md`

- [ ] **Step 1: Add conditional markers and multi-project structure to template header**

Replace lines 7-12 of `references/report-template.md` (the report header) with:

````markdown
```markdown
# Groundwork: {project_name}

{IF MULTI_PROJECT: use "Multi-Project Analysis" as project_name}

_Generated on {date}_
_Projects analyzed: {project_paths}_
{IF DOCS_PATH}_Docs: {docs_path}_{/IF}
_Files analyzed: {total_files_read} source files{IF DOCS_PATH}, {docs_count} docs pages, {images_count} images{/IF}_
````

- [ ] **Step 2: Add multi-project wrapper in section structure**

After the Executive Summary section, add:

```markdown
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
```

- [ ] **Step 3: Add section 13.5 template**

Insert after section 14 (Cross-Reference Findings) and before section 15 (Verification):

```markdown
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
```

- [ ] **Step 4: Update sections 15-17 for multi-project**

In section 15 (Verification), add note:

```markdown
{IF MULTI_PROJECT}
_Verification covers all {num_projects} projects{IF DOCS_PATH} and docs{/IF}. Claims are tagged with their source project._
{/IF}
```

In section 16 (Git History), add:

```markdown
{IF MULTI_PROJECT}
### Per-Project Git History
{Repeat git history subsection for each project, side by side}
{/IF}
```

In section 17 (Key Findings), add:

```markdown
{IF MULTI_PROJECT}
### Cross-Project Insights
- {Findings that span multiple projects}
- {Key overlaps and their implications}
{/IF}
```

- [ ] **Step 5: Commit**

```bash
git add references/report-template.md
git commit -m "feat(template): add multi-project structure, section 13.5, and conditional docs sections"
```

---

### Task 8: Correlation Guide — Generalize from Handbook

**Files:**
- Modify: `references/correlation-guide.md`

- [ ] **Step 1: Update title and intro**

Replace line 1-2:

Old:
```markdown
# Code-Handbook Correlation Guide

Detailed methodology for building the bidirectional correlation matrix between the code repository and "The Ansible Engineering Handbook". This is the most critical analysis phase -- it connects what the documentation says with what the code actually does.
```

New:
```markdown
# Code-Documentation Correlation Guide

Detailed methodology for building the bidirectional correlation matrix between code repositories and the documentation directory. When multiple projects are analyzed, the matrix maps docs against all projects. This is the most critical analysis phase -- it connects what the documentation says with what the code actually does.
```

- [ ] **Step 2: Replace "handbook" terminology throughout**

Throughout the file, replace:
- "handbook" → "docs" (when referring to the generic concept)
- "handbook page" → "docs page"
- Keep "The Ansible Engineering Handbook" only where it refers to the specific directory name

Specific replacements in Step 1 (Extract Code References):

Old: `For each markdown file in the handbook, scan for and extract:`
New: `For each markdown file in the docs directory, scan for and extract:`

Old: `From Image Captions and Diagrams` subsection references
New: Keep as-is (image analysis applies to any docs dir)

- [ ] **Step 3: Add multi-project guidance to Step 3 (Build Matrix)**

After the existing "Handbook to Code Table" example, add:

```markdown
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
```

- [ ] **Step 4: Update verification checklist at bottom**

Replace "handbook page" references:

Old: `Every handbook page has been mapped`
New: `Every docs page has been mapped`

Old: `Every top-level code directory has been checked for handbook coverage`
New: `Every top-level code directory in each project has been checked for docs coverage`

- [ ] **Step 5: Commit**

```bash
git add references/correlation-guide.md
git commit -m "feat(correlation): generalize from handbook to docs, add multi-project matrix guidance"
```

---

### Task 9: Verification Checklist — Conditional Docs and Multi-Project

**Files:**
- Modify: `references/verification-checklist.md`

- [ ] **Step 1: Update intro paragraph**

Replace lines 1-2:

Old:
```markdown
# Verification Checklist

Every factual claim in the analysis must be verified against the actual source files in the code repo or handbook repo before it appears in the final report. This checklist defines the verification procedure for each claim type.
```

New:
```markdown
# Verification Checklist

Every factual claim in the analysis must be verified against the actual source files in the project repo(s) and docs directory (if provided) before it appears in the final report. When analyzing multiple projects, verify claims against the correct project repo. This checklist defines the verification procedure for each claim type.
```

- [ ] **Step 2: Update section 1 (File Existence) for multi-project**

Add after the existing procedure:

```markdown
**Multi-project note:** When verifying file paths, ensure you check within the correct project repo. A path `src/auth/jwt.py` must be verified against the specific project it was cited in, not any arbitrary project.
```

- [ ] **Step 3: Update section 6 (Handbook Content Claims) to be conditional**

Replace the title and add conditional note:

Old: `## 6. Handbook Content Claims`
New: `## 6. Documentation Content Claims (only when docs are provided)`

Old: `**What to check:** Every claim about what a handbook page says or describes.`
New: `**What to check:** Every claim about what a docs page says or describes. Skip this entire section if no docs directory was provided.`

Replace "handbook page" with "docs page" throughout section 6.

- [ ] **Step 4: Update section 9 (Diagram Analysis) to be conditional**

Add: `**Note:** Skip if no docs directory was provided.`

- [ ] **Step 5: Update section 10 (Design Proposal Status) to be conditional**

Add: `**Note:** Skip if no docs directory was provided.`

- [ ] **Step 6: Update section 11 (Correlation Matrix Entries) to be conditional**

Add: `**Note:** Skip if no docs directory was provided. When multiple projects are analyzed, also verify the Project column is correct for each entry.`

Replace "handbook page" with "docs page" and "handbook-to-code" with "docs-to-code".

- [ ] **Step 7: Add new section 12 for cross-project overlap verification**

Add at the end (before the Rules section):

```markdown
## 12. Cross-Project Overlap Claims (only for multi-project analysis)

**What to check:** Every user story overlap identified in Phase 3.5.

**Procedure:**
- For each overlap, verify the user story evidence exists in both cited projects
- Grep for the cited files, endpoints, modules, or function names in each project
- Confirm the classification is accurate:
  - "Shared dependency": verify both projects reference the same external service/library
  - "Duplicate implementation": verify both projects contain independent implementations
  - "Complementary": verify the projects implement different aspects of the same story
  - "Potential conflict": verify the implementations actually diverge

**Examples:**
```
Claim: "User Authentication is a Duplicate Implementation in project-a (src/auth/) and project-b (lib/auth/)"
Verify: Glob for src/auth/ in project-a and lib/auth/ in project-b. Read key files in each to confirm they implement auth independently.
Result: PASSED or CORRECTED (actually a Shared dependency — both call the same SSO service)
```
```

- [ ] **Step 8: Commit**

```bash
git add references/verification-checklist.md
git commit -m "feat(verification): add conditional docs checks, multi-project awareness, and overlap verification"
```

---

### Task 10: HTML Template — Multi-Project and Conditional Sections

**Files:**
- Modify: `assets/report-template.html`

- [ ] **Step 1: Update the report header in HTML**

Replace lines 309-316 (the report-header div) with:

```html
  <div class="report-header">
    <h1>Groundwork: __PROJECT_NAME__</h1>
    <p class="subtitle">__REPO_PATHS__ <!-- replaces __CODE_REPO_PATH__ --> {IF DOCS_PATH}&mdash; Docs: __DOCS_PATH__ <!-- replaces __HANDBOOK_REPO_PATH__ -->{/IF}</p>
    <div class="stats-bar">
      <span class="stat"><strong>__FILES_COUNT__</strong> files read</span>
      <!-- __IF_DOCS__ --><span class="stat"><strong>__DOCS_COUNT__</strong> docs pages</span><!-- __/IF_DOCS__ -->
      <!-- __IF_DOCS__ --><span class="stat"><strong>__IMAGES_COUNT__</strong> images analyzed</span><!-- __/IF_DOCS__ -->
      <!-- __IF_MULTI__ --><span class="stat"><strong>__PROJECTS_COUNT__</strong> projects</span><!-- __/IF_MULTI__ -->
    </div>
  </div>
```

- [ ] **Step 2: Add multi-project nav entries and cross-project overlap section to sidebar**

Replace lines 285-304 (the nav-links ul) with:

```html
  <ul class="nav-links" id="nav-links">
    <li><a href="#summary">Executive Summary</a></li>
    <!-- __NAV_PROJECT_SECTIONS__ -->
    <!-- When single project, render flat section links (sections 1-11, optionally 12-14) -->
    <!-- When multi-project, render per-project groups:
      <li><a href="#project-a" class="nav-sub">Project: project-a</a></li>
        followed by sub-nav for that project's sections
    -->
    <li><a href="#identity">1. Project Identity</a></li>
    <li><a href="#architecture">2. Architecture</a></li>
    <li><a href="#directory">3. Directory &amp; Modules</a></li>
    <li><a href="#stack">4. Tech Stack &amp; Deps</a></li>
    <li><a href="#entrypoints">5. Entry Points &amp; Flows</a></li>
    <li><a href="#conventions">6. Coding Conventions</a></li>
    <li><a href="#api">7. API Surface</a></li>
    <li><a href="#data">8. Data Models</a></li>
    <li><a href="#testing">9. Testing</a></li>
    <li><a href="#cicd">10. Build &amp; CI/CD</a></li>
    <li><a href="#getting-started">11. Getting Started</a></li>
    <!-- __IF_DOCS__ -->
    <li><a href="#handbook">12. Docs Assessment</a></li>
    <li><a href="#correlation">13. Correlation Matrix</a></li>
    <li><a href="#crossref">14. Cross-Reference</a></li>
    <!-- __/IF_DOCS__ -->
    <!-- __IF_MULTI__ -->
    <li><a href="#overlap">13.5 Cross-Project Overlap</a></li>
    <!-- __/IF_MULTI__ -->
    <li><a href="#verification">15. Verification</a></li>
    <li><a href="#git">16. Git History</a></li>
    <li><a href="#findings">17. Key Findings</a></li>
  </ul>
```

- [ ] **Step 3: Wrap docs-only sections with conditional comments**

Wrap sections 12, 13, 14 (lines 479-548) with conditional markers:

```html
  <!-- __IF_DOCS__ -->
  <!-- ====== SECTION: DOCS ASSESSMENT ====== -->
  <section id="handbook">
    <h2>12. Docs Assessment <span class="collapse-icon">&#9660;</span></h2>
    <div class="section-body">
      <!-- __CONTENT_HANDBOOK__ -->
    </div>
  </section>

  <!-- ====== SECTION: CORRELATION MATRIX ====== -->
  <section id="correlation">
    <h2>13. Correlation Matrix <span class="collapse-icon">&#9660;</span></h2>
    <div class="section-body">
      <!-- __CONTENT_CORRELATION__ -->
    </div>
  </section>

  <!-- ====== SECTION: CROSS-REFERENCE FINDINGS ====== -->
  <section id="crossref">
    <h2>14. Cross-Reference Findings <span class="collapse-icon">&#9660;</span></h2>
    <div class="section-body">
      <!-- __CONTENT_CROSSREF__ -->
    </div>
  </section>
  <!-- __/IF_DOCS__ -->
```

- [ ] **Step 4: Add cross-project overlap section**

Insert after the crossref section (or after getting-started if no docs) and before verification:

```html
  <!-- __IF_MULTI__ -->
  <!-- ====== SECTION: CROSS-PROJECT OVERLAP ====== -->
  <section id="overlap">
    <h2>13.5 Cross-Project User Story Overlap <span class="collapse-icon">&#9660;</span></h2>
    <div class="section-body">
      <!-- __CONTENT_OVERLAP__ -->
      <!--
        User Story Inventory:
        <h3>User Stories by Project</h3>
        <div class="table-filter"><input type="text" data-filter-table="story-table" placeholder="Filter stories..."></div>
        <div class="table-wrap">
          <table id="story-table">
            <thead><tr><th>Project</th><th>Story</th><th>Evidence</th><th>Type</th></tr></thead>
            <tbody>
              <tr><td>project-a</td><td>User Authentication</td><td>src/auth/, /api/v1/auth/*</td><td><span class="badge badge-blue">API</span></td></tr>
            </tbody>
          </table>
        </div>

        Overlap Matrix:
        <h3>Overlaps</h3>
        <div class="table-filter"><input type="text" data-filter-table="overlap-table" placeholder="Filter overlaps..."></div>
        <div class="table-wrap">
          <table id="overlap-table">
            <thead><tr><th>Story</th><th>Projects</th><th>Classification</th><th>Evidence</th><th>Recommendation</th></tr></thead>
            <tbody>
              <tr>
                <td>User Auth</td>
                <td>project-a, project-b</td>
                <td><span class="badge badge-yellow">Duplicate</span></td>
                <td>Independent JWT implementations</td>
                <td>Extract shared auth library</td>
              </tr>
            </tbody>
          </table>
        </div>

        Classification badges:
        <span class="badge badge-green">Shared</span>
        <span class="badge badge-yellow">Duplicate</span>
        <span class="badge badge-blue">Complementary</span>
        <span class="badge badge-red">Conflict</span>
      -->
    </div>
  </section>
  <!-- __/IF_MULTI__ -->
```

- [ ] **Step 5: Commit**

```bash
git add assets/report-template.html
git commit -m "feat(html): add multi-project support, conditional docs sections, cross-project overlap section"
```

---

### Task 11: README.md — Updated Documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update title and intro**

Replace lines 1-6:

```markdown
# groundwork

A Claude Code skill that reads every file in one or more code repositories, optionally correlates with an engineering handbook or documentation directory, and produces a structured analysis report. When multiple projects are provided, it identifies overlapping user stories across codebases.

Built for teams that need deep codebase understanding -- whether analyzing a single project, correlating code with architecture docs, or finding overlap across related repositories.
```

- [ ] **Step 2: Update Quick Start section**

Replace lines 59-63:

```markdown
## Quick start

Single project (code-only):
```
/groundwork /path/to/code-repo
```

Single project with docs:
```
/groundwork /path/to/code-repo --docs-dir=/path/to/docs
```

Single project with Ansible Engineering Handbook:
```
/groundwork /path/to/code-repo --handbook=/path/to/handbook-repo
```

Multiple projects:
```
/groundwork /path/to/project-a /path/to/project-b
```

Multiple projects with shared docs:
```
/groundwork /path/to/project-a /path/to/project-b --docs-dir=/path/to/shared-docs
```

The skill reads all project repos, spins up parallel analysis agents per project, cross-references with docs (if provided), identifies cross-project user story overlaps (if multiple projects), and produces:

1. A **markdown report** in the conversation (interactive Q&A after)
2. An **HTML report** at `/tmp/groundwork-report.html` (opens automatically)
```

- [ ] **Step 3: Rewrite "What it expects" section**

Replace lines 70-78:

```markdown
## What it expects

One or more git repositories containing code:

```
project-a/           <-- your application code
project-b/           <-- another project (optional, for multi-project analysis)
```

Optionally, a documentation directory:

```
docs-dir/            <-- any directory of markdown files and images
```

Or an Ansible Engineering Handbook:

```
handbook-repo/
  The Ansible Engineering Handbook/    <-- architecture & design docs (markdown + images)
```

The `--handbook` flag is a convenience shortcut: it looks for the "The Ansible Engineering Handbook" subdirectory automatically. If not found, it falls back to using the path directly as a generic docs directory.
```

- [ ] **Step 4: Update Options section**

Replace lines 92-106:

```markdown
## Options

```
/groundwork <project-path> [<project-path> ...] [--docs-dir=<path>] [--handbook=<path>] [--focus=<area>]
```

| Flag | Description |
|------|-------------|
| `--docs-dir=<path>` | Path to any documentation directory. Enables correlation analysis. |
| `--handbook=<path>` | Convenience alias. Looks for "The Ansible Engineering Handbook" subdirectory; falls back to generic docs. Mutually exclusive with `--docs-dir`. |
| `--focus=<area>` | Expands a specific section in the report. |

`--focus` values:

| Value | Expands |
|-------|---------|
| `architecture` | Component boundaries, layer structure, execution flows |
| `patterns` | Naming, error handling, testing, logging conventions |
| `api` | Every endpoint, auth model, versioning strategy |
| `testing` | Test framework, coverage, mocking, fixtures |
| `devops` | CI/CD pipeline, Docker, K8s, deployment |
| `docs` | Documentation quality, coverage gaps, stale pages (requires --docs-dir or --handbook) |

Without `--focus`, all areas get equal treatment.
```

- [ ] **Step 5: Update "How it works" section**

Replace lines 109-138 with an updated architecture diagram:

```markdown
## How it works

The skill operates in phases, progressively activating features based on arguments:

```
                          /groundwork
                               |
                     Phase 1: Discovery
                   (per-project: tech stack,
                    structure, stats)
                   (if docs: image manifest)
                               |
              -----------------+------------------
              |          |          |              |       (×N projects)
          Agent A    Agent B    Agent C        Agent D
         Architecture  Code     API/Data    DevOps/Git
         {+Docs}      Patterns  + Deps      {+Docs}
              |          |          |              |
              -----------------+------------------
                               |
                  Phase 3: Correlation          ← only if docs provided
                 (bidirectional matrix,
                  cross-reference, gaps)
                               |
                  Phase 3.5: Cross-Project      ← only if multiple projects
                 (user story overlap,
                  duplicate detection)
                               |
                  Phase 3.6: Verification
                 (every claim checked against
                  source files -- mandatory gate)
                               |
                  Phase 4: Report + Q&A
                  (markdown + HTML output)
```
```

- [ ] **Step 6: Update the phase descriptions**

Replace the Phase 1, Phase 2, Phase 3 descriptions to reflect the changes. Key updates:

Phase 1:
```markdown
### Phase 1 -- Discovery

Runs shell scripts to orient before heavy reading, looping over each project:

- `detect-stack.sh` -- language, framework, database from manifest files (per project)
- `repo-stats.sh` -- git statistics (per project, and for docs if provided)
- `find-images.sh` -- image manifest (only if docs are provided)

Also reads README, CONTRIBUTING guide, and primary package manifest from each project to build a Discovery Summary passed to all agents.
```

Phase 2:
```markdown
### Phase 2 -- Parallel analysis

Launches 4 agents per project, all running simultaneously.

**Agent A (Architecture)** reads every code source file in the project. When docs are provided, also reads every doc and image, comparing documented architecture against actual code structure.

**Agent B (Code Patterns)** reads every source file and catalogs conventions: naming, error handling, testing, logging, configuration, comments. Includes code snippets and checks convention evolution via git.

**Agent C (API + Data)** maps the complete API surface, every data model, the full dependency tree, and external service integrations. Reads migration files for schema evolution.

**Agent D (DevOps + Git)** reads CI/CD configs, Dockerfiles, K8s manifests. Runs git log analysis. When docs are provided, also reads operational docs and synthesizes a getting-started guide from both sources.
```

Phase 3:
```markdown
### Phase 3 -- Correlation (when docs are provided)

Only runs when `--docs-dir` or `--handbook` is used. Builds a **bidirectional correlation matrix** between docs pages and code modules. When multiple projects are analyzed, the matrix maps docs against all projects with a Project column.

Correlation methods, gap analysis, and cross-reference work the same as before, but generalized from "handbook" to any docs directory.
```

Add Phase 3.5:
```markdown
### Phase 3.5 -- Cross-Project Overlap (when multiple projects)

Only runs when more than one project path is provided. A Cross-Project Agent analyzes all per-project summaries to:

1. **Infer user stories** per project from code (API endpoints, modules, README) and docs (if provided)
2. **Find overlaps** -- matching by feature names, API surface, domain concepts, module structure
3. **Classify** each overlap: Shared dependency, Duplicate implementation, Complementary, Potential conflict
4. **Gather evidence** -- grep across all projects for concrete proof

The result is a user story inventory, overlap matrix, and actionable recommendations.
```

- [ ] **Step 7: Update Output section**

In the markdown report table (lines 208-230), add between rows 14 and 15:

```markdown
| 13.5 | Cross-Project Overlap | User story inventory, overlap matrix, recommendations (multi-project only) |
```

Update the introductory text to note that sections 12-14 only appear with docs, and 13.5 only with multiple projects.

- [ ] **Step 8: Update Tips section**

Replace lines 244-250:

```markdown
## Tips

- **Large repos take time.** The skill reads every file. For a 500-file repo, expect 10-15 minutes. Multiple projects multiply this.
- **Start without docs.** You can always re-run with `--docs-dir` later for correlation analysis.
- **Use `--focus` when you know what you need.** Other sections still appear but with less detail.
- **Follow up after the report.** The report gives you the map; follow-up questions let you drill into any corner.
- **The HTML report is shareable.** Single file, no dependencies. Drop it in Slack or host it on a wiki.
- **Re-run after major changes.** The correlation matrix and overlap analysis are snapshots.
- **Multi-project analysis shines for microservices.** Related services often share user stories -- groundwork finds where.
```

- [ ] **Step 9: Commit**

```bash
git add README.md
git commit -m "docs: update README for optional docs, multi-project support, and cross-project overlap"
```

---

### Task 12: Final Verification

**Files:**
- All modified files

- [ ] **Step 1: Verify all conditional markers are consistent**

Grep across all files to ensure conditional markers (`{IF DOCS_PATH}`, `{IF MULTI_PROJECT}`, `<!-- __IF_DOCS__ -->`, `<!-- __IF_MULTI__ -->`) are used consistently and every opening marker has a closing marker:

```bash
grep -rn "IF_DOCS\|IF_MULTI\|IF DOCS_PATH\|IF MULTI_PROJECT\|/IF" SKILL.md references/ assets/
```

Verify every `{IF ...}` has a matching `{/IF}` and every `<!-- __IF_xxx__ -->` has a `<!-- __/IF_xxx__ -->`.

- [ ] **Step 2: Verify all $VARIABLE references are defined**

Grep for all variable references and confirm each is defined in the argument parsing section:

```bash
grep -rn '\$PROJECT_PATH\|\$DOCS_PATH\|\$DOCS_MODE\|\$HANDBOOK_PATH\|\$PROJECTS\|\$MULTI_PROJECT\|\$FOCUS' SKILL.md
```

Confirm: `$PROJECT_PATH`, `$DOCS_PATH`, `$DOCS_MODE`, `$HANDBOOK_PATH`, `$PROJECTS`, `$MULTI_PROJECT`, `$FOCUS` are all defined in Task 1's argument parsing section.

- [ ] **Step 3: Verify section numbering is consistent**

Check that section numbers in SKILL.md, report-template.md, and report-template.html all match:
- Sections 1-11: always present
- Sections 12-14: conditional on docs
- Section 13.5: conditional on multi-project
- Sections 15-17: always present

```bash
grep -n "^## \|^### \|Section \|section " SKILL.md references/report-template.md | grep -i "section\|^##"
```

- [ ] **Step 4: Verify backward compatibility path**

Re-read the argument parsing section in SKILL.md and confirm:
- Two bare paths where second contains "The Ansible Engineering Handbook" → treated as `--handbook`
- One bare path → single project, no docs
- One bare path + `--docs-dir` → single project with docs
- Multiple bare paths → multi-project

- [ ] **Step 5: Commit any fixes**

If any inconsistencies were found and fixed:

```bash
git add -A
git commit -m "fix: resolve inconsistencies found during final verification"
```
