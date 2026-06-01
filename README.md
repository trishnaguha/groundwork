# groundwork

A Claude Code skill that reads every file in one or more code repositories, optionally correlates with an engineering handbook or documentation directory, and produces a structured analysis report. When multiple projects are provided, it identifies overlapping user stories across codebases.

**Personalized for you:** Before analysis, Groundwork asks about your experience level and tech stack familiarity, then tailors the report accordingly:

| Your Level | What You Get |
|------------|--------------|
| **Associate SE** | Getting started guide, glossary, "start here" files, learning resources |
| **Mid-level SE** | Contributor's guide, patterns to follow, code review checklist |
| **Senior SE** | Technical debt assessment, scalability analysis, refactoring recommendations |
| **Principal SE+** | Strategic overview, architectural risks, industry comparisons, recommendations |

Built for teams that need deep codebase understanding -- whether analyzing a single project, correlating code with architecture docs, or finding overlap across related repositories.

## Installation

Copy the `groundwork/` directory into your Claude Code skills folder:

```bash

# Clone the Repository
git clone https://github.com/trishnaguha/groundwork.git

# Create the skills directory if it doesn't exist
mkdir -p ~/.claude/skills

# Copy the skill (from wherever you have the source)
cp -r ./groundwork ~/.claude/skills/
```

The skill directory must end up at `~/.claude/skills/groundwork/` with this structure:

```
~/.claude/skills/groundwork/
    SKILL.md                              # Skill definition (required)
    README.md                             # This file
    assets/
        report-template.html              # Interactive HTML report template
    references/
        code-analysis-checklist.md        # Code pattern heuristics
        correlation-guide.md              # Correlation matrix methodology
        docs-analysis-checklist.md        # Handbook quality framework
        file-reading-strategy.md          # What to read vs skip
        report-template.md                # Markdown report structure
        tech-stack-patterns.md            # Language/framework detection
        verification-checklist.md         # Claim verification procedures
    scripts/
        detect-stack.sh                   # Language + framework detection
        find-images.sh                    # Handbook image manifest
        repo-stats.sh                     # Git + size statistics
```

Make the scripts executable:

```bash
chmod +x ~/.claude/skills/groundwork/scripts/*.sh
```

Once installed, Claude Code automatically picks up the skill -- no config changes needed. Verify by asking Claude Code to "analyze this codebase" or typing `/groundwork`.

### Requirements

- Claude Code CLI
- `git` (for repo statistics and history analysis)
- `bash` (scripts use standard POSIX utilities: `find`, `wc`, `sort`, `awk`)

## Quick start

Single project (code-only):
```
/groundwork /path/to/code-repo
```

Remote GitHub repo:
```
/groundwork github.com/ansible/ansible
```

Short form (assumes GitHub):
```
/groundwork ansible/ansible
```

Single project with docs:
```
/groundwork /path/to/code-repo --docs-dir=/path/to/docs
```

Single project with Ansible Engineering Handbook:
```
/groundwork /path/to/code-repo --handbook=/path/to/handbook-repo
```

Multiple projects (local + remote):
```
/groundwork /path/to/project-a github.com/org/project-b
```

Multiple projects with shared docs:
```
/groundwork /path/to/project-a /path/to/project-b --docs-dir=/path/to/shared-docs
```

Specific branch:
```
/groundwork github.com/org/repo --branch=develop
```

The skill reads all project repos, spins up parallel analysis agents per project, cross-references with docs (if provided), identifies cross-project user story overlaps (if multiple projects), and produces:

1. A **markdown report** in the conversation (interactive Q&A after)
2. An **HTML report** at `/tmp/groundwork-report.html` (opens automatically)

## What it expects

One or more git repositories containing code -- local paths or remote URLs:

```
# Local paths
project-a/                          <-- your application code
project-b/                          <-- another project (optional)

# Remote URLs (any of these formats work)
https://github.com/org/repo
github.com/org/repo
org/repo                            <-- short form, assumes GitHub
git@github.com:org/repo.git         <-- SSH URL
https://gitlab.com/org/repo
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

## What it reads

**Code repos:** every source file, config, test, migration, Dockerfile, CI config, and schema in each project. Skips generated artifacts (`node_modules/`, `dist/`, `vendor/`, lock files, binaries). See `references/file-reading-strategy.md` for the full ruleset.

**Docs directory (if provided):** every markdown file and image. Images are analyzed using Claude's multimodal vision -- architecture diagrams are compared against actual code structure.

**Git history:** per project. Commit velocity, contributor analysis, hot areas, branching patterns.

## Options

```
/groundwork <project-path> [<project-path> ...] [--docs-dir=<path>] [--handbook=<path>] [--focus=<area>] [--branch=<name>] [--depth=<n>]
```

| Flag | Description |
|------|-------------|
| `--docs-dir=<path>` | Path to any documentation directory. Enables correlation analysis. |
| `--handbook=<path>` | Convenience alias. Looks for "The Ansible Engineering Handbook" subdirectory; falls back to generic docs. Mutually exclusive with `--docs-dir`. |
| `--focus=<area>` | Expands a specific section in the report. |
| `--branch=<name>` | Branch to checkout for remote repos (default: default branch). |
| `--depth=<n>` | Shallow clone depth for remote repos. Omit for full clone (recommended for git history analysis). |

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

## How it works

The skill operates in phases, progressively activating features based on arguments:

```
                          /groundwork
                               |
                     Phase 0: User Profiling
                   (experience level, tech
                    stack familiarity)
                               |
                     Phase 1: Discovery
                   (per-project: tech stack,
                    structure, stats)
                   (if docs: image manifest)
                               |
              -----------------+------------------
              |          |          |              |       (x N projects)
          Agent A    Agent B    Agent C        Agent D
         Architecture  Code     API/Data    DevOps/Git
         {+Docs}      Patterns  + Deps      {+Docs}
              |          |          |              |
              -----------------+------------------
                               |
                  Phase 3: Correlation          <-- only if docs provided
                 (bidirectional matrix,
                  cross-reference, gaps)
                               |
                  Phase 3.5: Cross-Project      <-- only if multiple projects
                 (user story overlap,
                  duplicate detection)
                               |
                  Phase 3.6: Verification
                 (every claim checked against
                  source files -- mandatory gate)
                               |
                  Phase 4: Report + Q&A
                  (markdown + HTML output,
                   personalized by user level)
```

### Phase 0 -- User Profiling

Before analysis begins, Groundwork asks two questions:

1. **Experience Level:** Associate SE, SE, Senior SE, or Principal SE+
2. **Tech Stack Familiarity:** For each detected technology, rate as New/Learning/Comfortable/Expert

This profile customizes the entire report:
- **Associates** get detailed explanations, glossaries, and "start here" guides
- **Mid-level** engineers get contributor guides and patterns to follow
- **Seniors** get technical debt assessments and scalability analysis
- **Principals** get strategic overviews and architectural recommendations

Technologies marked as unfamiliar automatically include "Technology Primer" sections with concepts, examples, and learning resources.

### Phase 1 -- Discovery

Runs shell scripts to orient before heavy reading, looping over each project:

- `detect-stack.sh` -- language, framework, database from manifest files (per project)
- `repo-stats.sh` -- git statistics (per project, and for docs if provided)
- `find-images.sh` -- image manifest (only if docs are provided)

Also reads README, CONTRIBUTING guide, and primary package manifest from each project to build a Discovery Summary passed to all agents.

### Phase 2 -- Parallel analysis

Launches 4 agents per project, all running simultaneously.

**Agent A (Architecture)** reads every code source file in the project. When docs are provided, also reads every doc and image, comparing documented architecture against actual code structure.

**Agent B (Code Patterns)** reads every source file and catalogs conventions: naming, error handling, testing, logging, configuration, comments. Includes code snippets and checks convention evolution via git.

**Agent C (API + Data)** maps the complete API surface, every data model, the full dependency tree, and external service integrations. Reads migration files for schema evolution.

**Agent D (DevOps + Git)** reads CI/CD configs, Dockerfiles, K8s manifests. Runs git log analysis. When docs are provided, also reads operational docs and synthesizes a getting-started guide from both sources.

### Phase 3 -- Correlation (when docs are provided)

Only runs when `--docs-dir` or `--handbook` is used. Builds a **bidirectional correlation matrix** between docs pages and code modules. When multiple projects are analyzed, the matrix maps docs against all projects with a Project column.

Correlation methods, gap analysis, and cross-reference work the same as before, but generalized from "handbook" to any docs directory.

### Phase 3.5 -- Cross-Project Overlap (when multiple projects)

Only runs when more than one project path is provided. A Cross-Project Agent analyzes all per-project summaries to:

1. **Infer user stories** per project from code (API endpoints, modules, README) and docs (if provided)
2. **Find overlaps** -- matching by feature names, API surface, domain concepts, module structure
3. **Classify** each overlap: Shared dependency, Duplicate implementation, Complementary, Potential conflict
4. **Gather evidence** -- grep across all projects for concrete proof

The result is a user story inventory, overlap matrix, and actionable recommendations.

### Phase 3.6 -- Verification

Every factual claim goes through a mandatory verification gate before report generation:

- File paths -- confirmed via Glob
- Code snippets -- confirmed via Grep against cited files
- API endpoints -- route definitions located
- Dependencies and versions -- manifest checked
- Data models -- model files confirmed
- Handbook claims -- pages re-read for accuracy
- Git statistics -- commands re-run
- Correlation matrix entries -- both sides confirmed

Claims that pass stay. Minor inaccuracies get auto-corrected. Unverifiable claims are removed. The verification summary appears in section 15 of the report.

## Output

### Markdown (in conversation)

Sections 12-14 only appear when docs are provided. Section 13.5 only appears with multiple projects. Personalized sections appear based on user level.

| # | Section | Covers |
|---|---------|--------|
| 0 | Strategic Overview | One-page assessment, risks, recommendations *(Principal+ only)* |
| -- | Executive Summary | 2-3 paragraph overview |
| 1.5 | Getting Started Guide | First day checklist, glossary, "start here" files *(Associate only)* |
| -- | Technology Primers | Concepts, examples, resources for unfamiliar tech *(based on profile)* |
| 1 | Project Identity | Language, framework, repo stats |
| 2 | Architecture | Component map, layers, diagram analysis, divergences |
| 3 | Directory & Modules | Every directory explained |
| 4 | Tech Stack & Deps | Full dependency table |
| 5 | Entry Points & Flows | Main execution paths |
| 6 | Coding Conventions | Naming, errors, logging -- with code snippets |
| 6.5 | Contributor's Guide | How to add features, patterns, code review checklist *(Mid-level only)* |
| 6.5 | Technical Health | Tech debt, scalability, security, dependency health *(Senior only)* |
| 7 | API Surface | Every endpoint |
| 8 | Data Models | Schema, migrations |
| 9 | Testing | Framework, organization, mocking |
| 10 | Build & CI/CD | Pipeline, containerization |
| 11 | Getting Started | Synthesized setup guide |
| 12 | Handbook Assessment | Per-page inventory, coverage score, proposal status |
| 13 | Correlation Matrix | Bidirectional handbook-to-code mapping |
| 13.5 | Cross-Project Overlap | User story inventory, overlap matrix, recommendations *(multi-project only)* |
| 14 | Cross-Reference | Orphaned code, stale docs, contradictions |
| 14.5 | Strategic Recommendations | Architecture evolution, build vs buy, team structure *(Principal+ only)* |
| 15 | Verification Summary | Pass rate, corrections, removals |
| 16 | Git History | Velocity, contributors, hot areas |
| 17 | Key Findings | Top 10 things a new engineer should know |

After the report, the conversation stays open for follow-up questions with the full analysis context retained.

### HTML (in browser)

Interactive single-page report at `/tmp/groundwork-report.html`:

- **Personalization banner** showing your level and tech familiarity
- Sidebar navigation with scroll spy (includes personalized sections)
- Collapsible sections, searchable tables
- Color-coded status badges and coverage bars
- User level badges (Associate/Mid/Senior/Principal)
- Dark/light theme toggle (auto-detects OS preference)
- Print-friendly, mobile-responsive
- Zero external dependencies -- one self-contained file

## Tips

- **Answer the profiling questions honestly.** The report is tailored to your level -- Associates get onboarding help, Principals get strategic insights. Misrepresenting your level gives you a less useful report.
- **Mark unfamiliar tech accurately.** Technologies you mark as "New" or "Learning" get primer sections with concepts and learning resources. Don't skip these if you need them.
- **Remote repos are cloned to `/tmp`.** After analysis, you'll be asked if you want to delete them. Say yes unless you plan to explore the code locally.
- **Private repos need local clone.** For repos requiring authentication, clone locally first and provide the local path.
- **Skip `--depth` for full git analysis.** Shallow clones (`--depth=1`) are faster but skip git history analysis in section 16.
- **Large repos take time.** The skill reads every file. For a 500-file repo, expect 10-15 minutes. Multiple projects multiply this.
- **Start without docs.** You can always re-run with `--docs-dir` later for correlation analysis.
- **Use `--focus` when you know what you need.** Other sections still appear but with less detail.
- **Follow up after the report.** The report gives you the map; follow-up questions let you drill into any corner.
- **The HTML report is shareable.** Single file, no dependencies. Drop it in Slack or host it on a wiki.
- **Re-run after major changes.** The correlation matrix and overlap analysis are snapshots.
- **Multi-project analysis shines for microservices.** Related services often share user stories -- groundwork finds where.
