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
  or wants a holistic understanding of a code repository and its
  engineering handbook including architecture designs, system design plans,
  and implementation proposals. Reads ALL source files comprehensively.
  Looks for "The Ansible Engineering Handbook" directory in the handbook repo.
  Analyzes git history for the code repo. Every data point is verified
  against source files before report generation.
argument-hint: <code-repo-path> <handbook-repo-path> [--focus=architecture|patterns|api|testing|devops|docs]
tools: Read, Write, Glob, Grep, Bash
---

# Groundwork: Codebase + Handbook Analyzer

Perform a comprehensive, holistic analysis of a code repository and its associated engineering handbook. Read ALL source files, ALL handbook docs, and ALL images. Build a full correlation matrix between code and documentation. Analyze git history for the code repo. Every data point is verified against source files before report generation -- nothing makes it into the report without proof it exists in the repos.

## Inputs

- `$0`: Path to the code repository (required)
- `$1`: Path to the handbook repository (required). Must contain a directory named "The Ansible Engineering Handbook".
- `--focus=<area>`: Optional focus area for expanded analysis. Values: architecture, patterns, api, testing, devops, docs.

Parse `$ARGUMENTS` by splitting on spaces. First non-flag token is the code repo path, second is the handbook repo path. Extract any `--focus=X` flag.

## Phase 1: Discovery & Orientation

Run these steps directly (not in sub-agents) to produce context that all subsequent agents need.

### 1.1 Validate Inputs

Verify `$0` exists and is a directory. Verify `$1` exists and is a directory. Within `$1`, locate the directory named **"The Ansible Engineering Handbook"**. If not found, output an error: "Could not find 'The Ansible Engineering Handbook' directory in the handbook repo. Expected at: $1/The Ansible Engineering Handbook/". Store the handbook docs path as `HANDBOOK_PATH="$1/The Ansible Engineering Handbook"`.

### 1.2 Detect Tech Stack

Run the detection script:
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/detect-stack.sh" "$0"
```

### 1.3 Gather Repo Statistics

Run stats for both repos in parallel:
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/repo-stats.sh" "$0"
bash "${CLAUDE_SKILL_DIR}/scripts/repo-stats.sh" "$1"
```

### 1.4 Map Directory Structures

Use Bash to list directory structures for both repos, excluding artifact directories (.git, node_modules, vendor, target, __pycache__, dist, build, .next, venv, .venv).

### 1.5 Discover Images

Run the image finder on the handbook:
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/find-images.sh" "$HANDBOOK_PATH"
```

### 1.6 Read File Strategy

Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` to understand what to read vs skip.

### 1.7 Read Orientation Files

Read key orientation files from the code repo if they exist: README.md, CONTRIBUTING.md, ARCHITECTURE.md, and the primary language manifest (package.json, Cargo.toml, go.mod, pyproject.toml, pom.xml, etc.).

### 1.8 Produce Discovery Summary

Compile all findings into a Discovery Summary containing:
- Detected tech stack and framework
- Directory structure sketches of both repos
- Image manifest from handbook
- Entry-point candidates in the code repo
- File inventory for allocation to Phase 2 agents

## Phase 2: Deep Analysis (4 Parallel Sub-Agents)

Launch 4 Agent sub-agents concurrently in a single message. Pass each agent the Discovery Summary from Phase 1. **Critical: agents must read ALL files in their domain, not samples.**

### Agent A: Architecture & Structure

Provide Agent A with the Discovery Summary and these instructions:

> Analyze the architecture of the code repository at `$0` and the engineering handbook at `$HANDBOOK_PATH`.
>
> **Handbook analysis (read EVERY file):**
> - Read ALL markdown files in `$HANDBOOK_PATH` -- every architecture doc, system design plan, and implementation proposal, in full
> - Read ALL images in the handbook using the Read tool (it renders PNG/JPG visually)
> - For each doc, note: title, topic, what code areas it describes, key design decisions
>
> **Code architecture analysis (read ALL files):**
> - Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` for what to read vs skip
> - Read ALL entry point files and trace primary execution flows
> - Read ALL files in each code module/package to understand module responsibilities
> - Identify architectural boundaries: layers, modules, service boundaries
> - Map import/dependency graphs across the full codebase
> - Identify communication patterns: HTTP, queues, shared DB, events, gRPC
> - Read ADRs (Architecture Decision Records) if they exist in either repo
>
> **Cross-reference:**
> - For each handbook diagram/doc, compare what it describes vs what the code actually implements
> - Note divergences, missing components, extra components not in docs
>
> Output a structured Architecture Summary with: component map, layer structure, execution flows, and diagram-to-code cross-reference.

### Agent B: Code Patterns & Conventions

Provide Agent B with the Discovery Summary and these instructions:

> Analyze coding patterns and conventions in the code repository at `$0`.
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

### Agent C: API Surface, Data Models & Dependencies

Provide Agent C with the Discovery Summary and these instructions:

> Analyze the complete API surface, data models, and dependencies in the code repository at `$0`. Also read relevant API docs from the handbook at `$HANDBOOK_PATH`.
>
> - Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` for what to read vs skip
> - Read ALL route/endpoint definition files (every controller, handler, route file)
> - Read ALL data model/schema definitions (ORM models, protobuf, JSON schemas, GraphQL schemas, migration files)
> - Map the complete public API surface: every endpoint, every exported function/class
> - Read ALL database migration files to understand schema evolution
> - Identify the full persistence layer by reading config and connection code
> - Analyze the complete dependency manifest: every dependency, categorized (core framework, utilities, dev tools, testing, deployment)
> - Read ALL external service integration code (third-party API clients, SDK usage)
> - Read any API documentation from the handbook
> - **Git analysis**: Run `git log --oneline --since='6 months ago' -- <api-paths>` to track how the API surface and data models have evolved recently
>
> Output a Complete API & Data Summary with every endpoint, every data model, full dependency analysis, and evolution history.

### Agent D: Documentation, DevOps & Code Git History

Provide Agent D with the Discovery Summary and these instructions:

> Analyze documentation quality, DevOps setup, and code repo git history for the code repository at `$0` and the handbook repository at `$1`.
>
> - Read `${CLAUDE_SKILL_DIR}/references/docs-analysis-checklist.md` for handbook quality heuristics
> - Read `${CLAUDE_SKILL_DIR}/references/file-reading-strategy.md` for what to read vs skip
> - **Read ALL remaining handbook files** not covered by Agent A (operational docs, runbooks, onboarding guides, troubleshooting docs outside "The Ansible Engineering Handbook" directory)
> - Read ALL documentation images not handled by Agent A
> - Read ALL CI/CD configuration files (GitHub Actions workflows, Jenkinsfile, .gitlab-ci.yml, Makefile, scripts/)
> - Read ALL containerization files (every Dockerfile, docker-compose.yml, K8s manifests, Helm charts)
> - Analyze complete developer setup: prerequisites, setup scripts, environment variables
>
> **Code repo git history analysis (`$0`):**
> - `git log --oneline -50` for recent commits
> - `git shortlog -sn --no-merges` for contributor analysis
> - `git log --numstat --since='90 days ago'` for recent areas of active development
> - Branching strategy and merge patterns
>
> Synthesize a "Getting Started" guide from code setup files + handbook onboarding docs.
>
> Output a Documentation & DevOps Summary with code repo git analysis.

## Phase 3: Correlation & Cross-Reference

After all 4 agents complete, this is the most critical phase. Read `${CLAUDE_SKILL_DIR}/references/correlation-guide.md` for the detailed methodology.

### 3.1 Build the Correlation Matrix

Create a bidirectional map connecting every handbook page to its corresponding code areas:

**Handbook to Code mapping**: For each handbook page, extract all references to code constructs (file paths, module names, class names, function names, service names, API endpoints, database table names, config keys). Verify each reference exists in the actual code using Grep. Produce a table:

```
| Handbook Page | Referenced Code | Exists? |
```

**Code to Handbook mapping**: For each code module/directory, list all handbook pages that reference it. Produce a table:

```
| Code Module | Handbook Pages | Coverage Level | Gaps |
```

**Semantic correlation**: Match handbook pages to code areas by topic/domain keywords even when explicit references are absent. If a handbook page discusses "task execution" and the code has a `task_executor/` module, correlate them.

### 3.2 Deep Cross-Reference Analysis

Using the correlation matrix, analyze:
- Architecture diagrams vs actual code structure
- API docs vs actual endpoints
- Getting-started docs vs actual setup requirements
- Code modules with **zero handbook coverage** (orphaned code)
- Handbook pages referencing **nonexistent code** (stale docs)
- **Design proposals**: implemented vs pending vs abandoned
- **Major code components** with no design doc explaining the "why"
- **Consistency**: Do different handbook pages describe the same code area consistently or contradict each other?

### 3.3 Produce Connected Summary

- Aggregate the 4 agent summaries
- Overlay the correlation matrix
- For each major code area, produce a mini-summary combining: what the code does + what the handbook says + where they align or diverge
- Identify top 10 key findings for new engineers

### 3.4 Verification Against Source of Truth

**This is a mandatory gate. No report is generated until verification passes.**

Read `${CLAUDE_SKILL_DIR}/references/verification-checklist.md` for the detailed verification procedures.

Every factual claim from the 4 agent summaries and the correlation matrix must be traced back to an actual file in one of the two repos. Launch a **Verification Agent** with these instructions:

> Verify every factual claim in the analysis against the actual source files. Read `${CLAUDE_SKILL_DIR}/references/verification-checklist.md` for procedures.
>
> **File existence:** For every file path cited anywhere in the analysis, run Glob to confirm it exists. For every handbook page referenced, confirm it exists in `The Ansible Engineering Handbook/`. If a file is not found, flag it for removal.
>
> **Code snippets:** For every code example in the conventions section, Grep for that exact text in the cited file. If the snippet doesn't match, re-read the file and correct or remove it.
>
> **API endpoints:** For every endpoint in the API surface table, Grep for the route pattern in the code repo. Confirm method, path, and handler all exist.
>
> **Dependencies:** For every dependency listed, Read the package manifest and confirm the name and version match.
>
> **Data models:** For every model/schema described, Read the model file and confirm fields and relationships exist.
>
> **Handbook claims:** For every claim about what a handbook page says, Read that page and confirm the claim is accurate. For correlation matrix entries, confirm the handbook page actually references or describes the correlated code area.
>
> **Git statistics:** Re-run key git commands (commit count, contributor count, recent velocity) and compare with reported numbers. Replace any mismatches with the verified numbers.
>
> **Architecture claims:** For claims like "Service A calls Service B via HTTP", Grep for the actual HTTP call in code.
>
> **Diagram analysis:** For claims about what diagrams depict, re-read the image to confirm.
>
> **Design proposal status:** For proposals marked "implemented", verify the claimed code exists via Glob + Grep.
>
> For each claim, record: PASSED (confirmed), CORRECTED (fixed minor inaccuracy), REMOVED (unverifiable), or FLAGGED (needs manual review).
>
> **Auto-correct:** If a file path has a typo but a similar file exists, correct it. If a snippet is slightly off, replace with actual text. If a git stat is wrong, replace with the re-verified number. If a claim cannot be verified at all, remove it from the analysis rather than include unverified data.
>
> Output a Verification Summary:
> ```
> TOTAL CLAIMS CHECKED: X
> PASSED: N (confirmed against source)
> CORRECTED: N (auto-fixed minor inaccuracies)
> REMOVED: N (unverifiable, excluded from report)
> FLAGGED: N (need manual review)
> ```
> Also output the corrected versions of any claims that were fixed, and the list of claims that were removed.

After the verification agent completes, merge its corrections into the analysis data. Remove all unverified claims. The verification summary will be included in the final report.

### 3.5 Generate Final Report (Markdown)

Read `${CLAUDE_SKILL_DIR}/references/report-template.md` for the exact output structure. Produce the complete report with all 17 sections in the conversation as markdown, including the correlation matrix and verification summary as core artifacts. Only include data that passed verification.

### 3.6 Generate HTML Report

After producing the markdown report, also generate an interactive HTML version:

1. Read the HTML template at `${CLAUDE_SKILL_DIR}/assets/report-template.html`
2. Create a filled-in copy of the template with all analysis data. Replace:
   - `__PROJECT_NAME__` with the project name (throughout)
   - `__DATE__` with today's date
   - `__CODE_REPO_PATH__` and `__HANDBOOK_REPO_PATH__` with actual paths
   - `__FILES_COUNT__`, `__DOCS_COUNT__`, `__IMAGES_COUNT__` with actual counts
   - Each `<!-- __CONTENT_xxx__ -->` comment with the actual HTML content for that section

3. Use the template's built-in CSS classes for rich rendering:
   - `.kv-list` + `.kv-row` + `.kv-key`/`.kv-val` for key-value pairs (Project Identity)
   - `.table-wrap` + `<table>` for data tables. Add `data-filter-table="tableId"` on filter inputs for searchable tables (API endpoints, correlation matrices)
   - `.badge` + `.badge-green`/`.badge-yellow`/`.badge-red`/`.badge-blue`/`.badge-gray` for status indicators
   - `<pre>` for code snippets and directory trees
   - `<details>` + `<summary>` + `.details-body` for collapsible module descriptions and diagram analyses
   - `.callout`, `.callout-warn`, `.callout-error` for findings and divergences
   - `.coverage-bar` with `.fill-green`/`.fill-yellow`/`.fill-red` for documentation coverage visualization

4. Write the HTML file to `/tmp/groundwork-report.html`
5. Open it in the browser: `open /tmp/groundwork-report.html`
6. Tell the user the file path

## Phase 4: Interactive Q&A

After producing both reports, end with this message:

---
**Groundwork complete.** Read {N} source files across {M} modules in the code repo and {P} documents in The Ansible Engineering Handbook. {V} claims verified against source files ({pass_rate}% pass rate).

HTML report: `/tmp/groundwork-report.html` (opened in browser)

Ask follow-up questions about any aspect of this project:
- "How is [feature] implemented?"
- "Walk me through the [X] execution flow"
- "What does the handbook say about [component] vs what the code does?"
- "Which handbook pages are most out of date?"
- "What would I need to do to add a new [endpoint/feature/module]?"
- "Show me the correlation between [handbook page] and [code module]"

The full analysis context is available for deep follow-ups.
---
