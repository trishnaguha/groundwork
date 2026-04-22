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

# Groundwork: Multi-Project Codebase Analyzer

Perform a comprehensive analysis of one or more code repositories, optionally correlated with an engineering handbook or documentation directory. Read ALL source files in each project. When docs are provided, build a full correlation matrix between code and documentation. When multiple projects are given, identify overlapping user stories across codebases. Analyze git history for each code repo. Every data point is verified against source files before report generation -- nothing makes it into the report without proof it exists in the repos.

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

## Phase 2: Deep Analysis (Parallel Sub-Agents)

Launch Agent sub-agents concurrently in a single message. Pass each agent the Discovery Summary from Phase 1. **Critical: agents must read ALL files in their domain, not samples.**

### Agent Allocation

For each project in `PROJECTS`, launch 4 agents (A, B, C, D). All agents across all projects run in parallel in a single message. For N projects, this means 4×N agents.

When `DOCS_PATH` is null, agents A and D use their code-only variants (handbook instructions are omitted). When `DOCS_PATH` is set, agents A and D include docs analysis instructions.

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
