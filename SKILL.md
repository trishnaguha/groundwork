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
  **Personalized reports**: Asks about user's experience level (Associate SE
  through Principal SE+) and tech stack familiarity to customize depth,
  explanations, and focus areas. Associates get onboarding guides and glossaries;
  Principals get strategic assessments and architectural recommendations.
argument-hint: <project-path> [<project-path> ...] [--docs-dir=<path>] [--handbook=<path>] [--focus=architecture|patterns|api|testing|devops|docs]
tools: Read, Write, Glob, Grep, Bash, AskQuestion
---

# Groundwork: Multi-Project Codebase Analyzer

Perform a comprehensive analysis of one or more code repositories, optionally correlated with an engineering handbook or documentation directory. Read ALL source files in each project. When docs are provided, build a full correlation matrix between code and documentation. When multiple projects are given, identify overlapping user stories across codebases. Analyze git history for each code repo. Every data point is verified against source files before report generation -- nothing makes it into the report without proof it exists in the repos.

**Personalized for you**: Before analysis begins, Groundwork asks about your experience level and familiarity with the detected technologies. The report is then customized:
- **Associate SEs** get detailed explanations, glossaries, "start here" guides, and learning resources
- **Mid-level SEs** get contributor guides, patterns to follow, and step-by-step feature addition guides
- **Senior SEs** get technical debt assessments, scalability analysis, and refactoring recommendations
- **Principal SEs+** get strategic overviews, architectural risk assessments, and industry comparisons

## Inputs

- `<project-path>`: One or more paths to code repositories (at least one required). Can be:
  - **Local path**: `/path/to/repo` or `./relative/path`
  - **GitHub URL**: `https://github.com/org/repo`, `github.com/org/repo`, or `org/repo` (assumes GitHub)
  - **GitLab URL**: `https://gitlab.com/org/repo` or `gitlab.com/org/repo`
  - **Git URL**: Any valid git clone URL (`git@github.com:org/repo.git`)
- `--docs-dir=<path>`: Optional path to a documentation directory. Applied globally for correlation analysis against all projects. Can also be a remote URL.
- `--handbook=<path>`: Optional convenience alias. Looks for "The Ansible Engineering Handbook" subdirectory inside `<path>`. If found, uses that as the docs path. If not found, falls back to using `<path>` directly as a generic docs dir (with a warning). Mutually exclusive with `--docs-dir`.
- `--focus=<area>`: Optional focus area for expanded analysis. Values: architecture, patterns, api, testing, devops, docs.
- `--branch=<name>`: Optional branch to checkout for remote repos (default: default branch).
- `--depth=<n>`: Optional shallow clone depth for remote repos (default: full clone for git history analysis).

Parse `$ARGUMENTS` by splitting on spaces. All non-flag tokens are project paths. Extract `--docs-dir=X`, `--handbook=X`, `--focus=X`, `--branch=X`, and `--depth=X` flags. Error if both `--docs-dir` and `--handbook` are provided.

### Remote Repository Support

For each project path, detect if it's a remote URL and clone if needed:

**URL Detection Patterns:**
- `https://github.com/org/repo` or `http://github.com/org/repo`
- `github.com/org/repo` (no protocol - assumes https)
- `org/repo` (short form - assumes `https://github.com/org/repo`)
- `https://gitlab.com/org/repo` or `gitlab.com/org/repo`
- `git@github.com:org/repo.git` (SSH URL)
- Any URL ending in `.git`

**Clone Process:**
1. Create temp directory: `/tmp/groundwork-repos/<org>-<repo>-<timestamp>/`
2. Clone the repository:
   ```bash
   # Full clone (default - needed for git history analysis)
   git clone <url> /tmp/groundwork-repos/<org>-<repo>-<timestamp>/
   
   # Or shallow clone if --depth specified
   git clone --depth <n> <url> /tmp/groundwork-repos/<org>-<repo>-<timestamp>/
   ```
3. Checkout specific branch if `--branch` specified:
   ```bash
   git checkout <branch>
   ```
4. Update the project path to the cloned location for subsequent phases

**Error Handling:**
- If clone fails (auth required, repo not found, network error), emit error and skip that project
- If all projects fail to clone, abort with error message
- For private repos, suggest: "Clone failed. For private repos, clone locally first and provide the local path."

**Cleanup:**
- At the end of Phase 4 (after report generation), prompt user:
  > "Cloned repos are at `/tmp/groundwork-repos/`. Delete them? (y/n)"
- If user confirms, delete the temp directory
- If user declines, inform them of the location for manual cleanup

### Backward Compatibility

If exactly two non-flag paths are given and the second contains a directory named "The Ansible Engineering Handbook", treat the second as `--handbook=<path>` and emit a deprecation notice: "Note: Detected handbook repo as second argument. In the future, please use --handbook=<path> explicitly. Treating second path as handbook."

### Internal State

After parsing and cloning (if needed), set:
- `PROJECTS` = list of project entries, each containing:
  - `path`: resolved local path (either original or cloned location)
  - `original_input`: what the user provided (URL or path)
  - `is_remote`: true if cloned from remote
  - `remote_url`: the clone URL (if remote)
  - `branch`: checked out branch
- `DOCS_PATH` = resolved docs directory path, or null if no docs provided
- `DOCS_MODE` = "handbook" (--handbook with Ansible handbook found), "generic" (--docs-dir or --handbook fallback), or null
- `FOCUS` = focus area string or null
- `MULTI_PROJECT` = true if len(PROJECTS) > 1
- `HAS_REMOTE_REPOS` = true if any project was cloned from remote
- `CLONE_DIR` = path to temp clone directory (if any remotes)

## Phase 0: User Profiling

Before analysis begins, gather information about the user to customize the report output. This ensures the analysis is tailored to their experience level and familiarity with the technologies involved.

### 0.1 Gather User Profile

Ask the user the following questions using structured prompts:

**Question 1: Experience Level**

> What is your current role/designation?
>
> - Associate Software Engineer (0-2 years experience)
> - Software Engineer (2-4 years experience)
> - Senior Software Engineer (4-7 years experience)
> - Principal Software Engineer and above (7+ years experience)

**Question 2: Tech Stack Familiarity**

After Phase 1.2.1 (Detect Tech Stack) completes, present the detected technologies and ask:

> How comfortable are you with the following technologies detected in this codebase?
>
> For each technology, rate your familiarity:
> - **New to me**: Never used it, need explanations of concepts
> - **Learning**: Used it a few times, understand basics
> - **Comfortable**: Use it regularly, understand patterns
> - **Expert**: Deep knowledge, can mentor others

### 0.2 User Profile Configuration

Based on responses, set internal configuration flags:

```
USER_LEVEL = "associate" | "mid" | "senior" | "principal"
TECH_COMFORT = {
  "<technology>": "new" | "learning" | "comfortable" | "expert",
  ...
}
```

### 0.3 Report Customization Rules

The user profile affects report generation as follows:

#### By Experience Level

| Level | Report Characteristics |
|-------|----------------------|
| **Associate** | Detailed explanations of architectural patterns. Step-by-step onboarding guidance. Glossary of domain terms. "Why it matters" context for each section. Links to learning resources. Explicit "what to read first" recommendations. |
| **Mid-level** | Balanced depth. Focus on conventions and patterns to follow. Integration points highlighted. Common pitfalls called out. "How to contribute" guidance. |
| **Senior** | Architecture-first view. Design decision rationale. Technical debt assessment. Scalability considerations. Areas needing refactoring. Cross-cutting concerns. |
| **Principal+** | Executive summary focus. Strategic technical insights. System-wide patterns and anti-patterns. Architectural risks. Recommendations for improvement. Comparison with industry best practices. |

#### By Tech Stack Familiarity

For technologies marked as **"New to me"** or **"Learning"**:
- Include a "Technology Primer" subsection explaining core concepts
- Add code examples with inline explanations
- Link to official documentation and tutorials
- Highlight common gotchas for beginners

For technologies marked as **"Comfortable"** or **"Expert"**:
- Focus on project-specific patterns and deviations from standard practices
- Highlight advanced usage patterns found in the codebase
- Note any unusual or innovative approaches worth studying

### 0.4 Store Profile for Session

Store the user profile so it persists throughout the analysis and can be referenced by all agents in Phase 2.

```
USER_PROFILE = {
  "level": USER_LEVEL,
  "tech_comfort": TECH_COMFORT,
  "customization_flags": {
    "include_primers": true/false,
    "explanation_depth": "detailed" | "balanced" | "concise" | "executive",
    "focus_areas": ["onboarding", "contributing", "architecture", "strategy"],
    "include_learning_resources": true/false
  }
}
```

---

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

Launch Agent sub-agents concurrently in a single message. Pass each agent the Discovery Summary from Phase 1 **and the User Profile from Phase 0**. **Critical: agents must read ALL files in their domain, not samples.**

### Agent Allocation

For each project in `PROJECTS`, launch 4 agents (A, B, C, D). All agents across all projects run in parallel in a single message. For N projects, this means 4×N agents.

When `DOCS_PATH` is null, agents A and D use their code-only variants (handbook instructions are omitted). When `DOCS_PATH` is set, agents A and D include docs analysis instructions.

### User Profile Context for All Agents

Every agent receives the `USER_PROFILE` and must adapt their analysis accordingly:

```
USER_PROFILE = {
  "level": "<associate|mid|senior|principal>",
  "tech_comfort": { "<tech>": "<new|learning|comfortable|expert>", ... },
  "customization_flags": { ... }
}
```

**Agent output adaptation rules:**
- If `USER_PROFILE.level == "associate"`: Include explanatory context, define technical terms on first use, add "why this matters" annotations
- If `USER_PROFILE.level == "principal"`: Lead with strategic insights, focus on architectural implications, highlight risks and recommendations
- For each technology where `tech_comfort[tech] in ["new", "learning"]`: Include a brief primer section and annotate code examples with explanations
- For each technology where `tech_comfort[tech] in ["comfortable", "expert"]`: Focus on project-specific deviations and advanced patterns

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

### 3.7.1 User-Personalized Report Sections

Based on `USER_PROFILE`, include or emphasize the following additional sections:

#### For Associate Software Engineers (`USER_PROFILE.level == "associate"`)

Insert after Section 1 (Executive Summary):

**Section 1.5: Getting Started Guide**
- "Your First Day" checklist: environment setup, key files to read, who to ask for help
- Glossary of domain-specific and technical terms used in the codebase
- Annotated directory map: what each folder contains and why it matters
- "Start Here" recommendations: the 5-10 most important files to understand first
- Common beginner mistakes in this codebase and how to avoid them

Insert after the Architecture section:

**Section X.1: Architecture for New Engineers**
- Visual simplified architecture diagram (if complex)
- "How a request flows through the system" walkthrough
- Key abstractions explained with analogies
- Links to learning resources for unfamiliar patterns

#### For Mid-Level Software Engineers (`USER_PROFILE.level == "mid"`)

Insert after the Patterns section:

**Section X.2: Contributor's Guide**
- How to add a new feature (step-by-step with file locations)
- How to add a new API endpoint
- How to add tests (with example patterns from the codebase)
- Code review checklist based on project conventions
- Common patterns to follow (with code snippets)
- Anti-patterns to avoid (with examples from the codebase if found)

#### For Senior Software Engineers (`USER_PROFILE.level == "senior"`)

Insert after the Architecture section:

**Section X.3: Technical Health Assessment**
- Technical debt inventory with severity ratings
- Refactoring opportunities ranked by impact
- Scalability bottlenecks identified
- Security considerations and potential vulnerabilities
- Performance hotspots (based on code patterns, not runtime data)
- Dependency health: outdated, deprecated, or risky dependencies

#### For Principal Engineers and Above (`USER_PROFILE.level == "principal"`)

Insert at the beginning (before Executive Summary):

**Section 0: Strategic Technical Overview**
- One-page architectural assessment
- Alignment with industry best practices (and notable deviations)
- Risks: technical, operational, and organizational
- Recommendations: prioritized list of improvements with estimated impact
- Questions for the team: gaps in understanding that need human context
- Comparison with similar systems/patterns in industry

Insert after Cross-Reference Findings:

**Section X.4: Strategic Recommendations**
- Architecture evolution suggestions
- Build vs buy analysis for key components
- Team structure implications (based on code ownership patterns)
- Long-term maintainability assessment

### 3.7.2 Technology Primers (Based on Tech Comfort)

For each technology in `TECH_COMFORT` where the user indicated **"New to me"** or **"Learning"**, generate a primer section:

**Section Y: Technology Primers**

For each unfamiliar technology:
```
### {Technology Name} Primer

**What it is:** One-paragraph explanation of the technology's purpose.

**Why this project uses it:** Specific reasons this codebase chose this technology.

**Key concepts you'll encounter:**
- Concept 1: Brief explanation
- Concept 2: Brief explanation
- ...

**How it's used in this codebase:**
- Primary usage pattern with code example
- Configuration location and key settings

**Quick reference:**
- Official docs: [link]
- Recommended tutorial: [link]
- Key files to study: [list of 3-5 files in this codebase]

**Common gotchas:**
- Pitfall 1 and how to avoid it
- Pitfall 2 and how to avoid it
```

Place this section after the Tech Stack section but before Architecture.

### 3.8 Generate HTML Report

After producing the markdown report, also generate an interactive HTML version:

1. Read the HTML template at `${CLAUDE_SKILL_DIR}/assets/report-template.html`
2. Create a filled-in copy of the template with all analysis data. Replace:
   - `__PROJECT_NAME__` with the project name (or "Multi-Project Analysis" if multiple projects)
   - `__DATE__` with today's date
   - `__REPO_PATHS__` with the project paths (replaces `__CODE_REPO_PATH__`)
   - `__DOCS_PATH__` with the docs path (or "N/A" if no docs; replaces `__HANDBOOK_REPO_PATH__`)
   - `__FILES_COUNT__`, `__DOCS_COUNT__`, `__IMAGES_COUNT__` with actual counts (DOCS_COUNT and IMAGES_COUNT are 0 if no docs)
   - `__USER_LEVEL__` with the user's experience level display name
   - `__USER_LEVEL_BADGE__` with appropriate badge class (associate, mid, senior, principal)
   - `__TECH_COMFORT_SUMMARY__` with the technology familiarity summary
   - Each `<!-- __CONTENT_xxx__ -->` comment with the actual HTML content for that section
   - For multi-project: populate `<!-- __CONTENT_PROJECTS__ -->` with per-project section HTML
   - For multi-project: populate `<!-- __CONTENT_OVERLAP__ -->` with cross-project overlap HTML
   - Omit docs-related sections from sidebar and body when `DOCS_PATH` is null
   - **User-personalized sections based on USER_PROFILE.level:**
     - `<!-- __CONTENT_GETTING_STARTED__ -->` for Associate SE (Section 1.5)
     - `<!-- __CONTENT_TECH_PRIMERS__ -->` for users with unfamiliar technologies
     - `<!-- __CONTENT_CONTRIBUTOR_GUIDE__ -->` for Mid-level SE
     - `<!-- __CONTENT_TECH_HEALTH__ -->` for Senior SE
     - `<!-- __CONTENT_STRATEGIC_OVERVIEW__ -->` for Principal SE+
     - `<!-- __CONTENT_STRATEGIC_RECOMMENDATIONS__ -->` for Principal SE+

3. Use the template's built-in CSS classes for rich rendering (same as current behavior).

4. Add a "Report Personalization" banner at the top of the report showing:
   - User level with appropriate styling/badge
   - Technologies the user is learning (highlighted for easy reference)
   - A note explaining the report has been customized

5. Write the HTML file to `/tmp/groundwork-report.html`
6. Open it in the browser: `open /tmp/groundwork-report.html`
7. Tell the user the file path

## Phase 4: Interactive Q&A

After producing both reports, end with this message:

---

**Single project, no docs:**

**Groundwork complete.** Read {N} source files across {M} modules. {V} claims verified against source files ({pass_rate}% pass rate).

Report customized for: **{USER_LEVEL_DISPLAY}** | Tech familiarity: {TECH_COMFORT_SUMMARY}

HTML report: `/tmp/groundwork-report.html` (opened in browser)

---

**Single project, with docs:**

**Groundwork complete.** Read {N} source files across {M} modules and {P} documents in the docs directory. {V} claims verified against source files ({pass_rate}% pass rate).

Report customized for: **{USER_LEVEL_DISPLAY}** | Tech familiarity: {TECH_COMFORT_SUMMARY}

HTML report: `/tmp/groundwork-report.html` (opened in browser)

---

**Multiple projects:**

**Groundwork complete.** Analyzed {num_projects} projects: {project_names}. Read {N} total source files{IF DOCS_PATH is set} and {P} documents{/IF}. Identified {overlap_count} user story overlaps. {V} claims verified ({pass_rate}% pass rate).

Report customized for: **{USER_LEVEL_DISPLAY}** | Tech familiarity: {TECH_COMFORT_SUMMARY}

HTML report: `/tmp/groundwork-report.html` (opened in browser)

---

Where:
- `USER_LEVEL_DISPLAY` = "Associate SE" | "Software Engineer" | "Senior SE" | "Principal SE+"
- `TECH_COMFORT_SUMMARY` = e.g., "Comfortable with Python, Go | Learning Kubernetes | New to gRPC"

Follow-up prompts (customized by user level):

**For all users:**
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

**For Associate SE:**
- "Explain [concept] in simpler terms"
- "What should I learn first to understand this codebase?"
- "Show me a simple example of [pattern] from this codebase"
- "What are common mistakes to avoid?"

**For Mid-level SE:**
- "What would I need to do to add a new [endpoint/feature/module]?"
- "What patterns should I follow when adding [X]?"
- "Show me similar implementations I can reference"

**For Senior SE:**
- "What technical debt should be prioritized?"
- "What are the scalability concerns?"
- "Where are the security considerations?"

**For Principal SE+:**
- "What are the strategic risks in this architecture?"
- "How does this compare to industry best practices?"
- "What would you recommend changing first?"

The full analysis context is available for deep follow-ups.
