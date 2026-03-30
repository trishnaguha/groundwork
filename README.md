# groundwork

A Claude Code skill that reads every file in a code repository and its engineering handbook, then produces a structured analysis report with a full correlation matrix between what the docs say and what the code actually does.

Built for teams that maintain architecture docs separately from code and need to know where the two have drifted apart.

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

```
/groundwork /path/to/code-repo /path/to/handbook-repo
```

The skill reads both repos, spins up four parallel analysis agents, cross-references everything, and produces:

1. A **markdown report** in the conversation (17 sections, interactive Q&A after)
2. An **HTML report** at `/tmp/groundwork-report.html` (opens automatically)

## What it expects

Two git repositories:

```
code-repo/           <-- your application code
handbook-repo/
  The Ansible Engineering Handbook/    <-- architecture & design docs (markdown + images)
```

The handbook repo must contain a directory named exactly `The Ansible Engineering Handbook`.

## What it reads

**Code repo:** every source file, config, test, migration, Dockerfile, CI config, and schema. Skips generated artifacts (`node_modules/`, `dist/`, `vendor/`, lock files, binaries). See `references/file-reading-strategy.md` for the full ruleset.

**Handbook repo:** every markdown file and image in `The Ansible Engineering Handbook/`. Images are analyzed using Claude's multimodal vision -- architecture diagrams are compared against actual code structure.

**Git history:** code repo only. Commit velocity, contributor analysis, hot areas, branching patterns.

## Options

```
/groundwork <code-path> <handbook-path> [--focus=<area>]
```

`--focus` expands a specific section in the report:

| Flag | Expands |
|------|---------|
| `--focus=architecture` | Component boundaries, layer structure, execution flows |
| `--focus=patterns` | Naming, error handling, testing, logging conventions |
| `--focus=api` | Every endpoint, auth model, versioning strategy |
| `--focus=testing` | Test framework, coverage, mocking, fixtures |
| `--focus=devops` | CI/CD pipeline, Docker, K8s, deployment |
| `--focus=docs` | Handbook quality, coverage gaps, stale pages |

Without `--focus`, all areas get equal treatment.

## How it works

Four phases:

```
                          /groundwork
                               |
                     Phase 1: Discovery
                   (tech stack, structure,
                    image manifest, stats)
                               |
              -----------------+------------------
              |          |          |              |
          Agent A    Agent B    Agent C        Agent D
         Architecture  Code     API/Data    Docs/DevOps
         + Handbook   Patterns  + Deps      + Git History
              |          |          |              |
              -----------------+------------------
                               |
                   Phase 3: Correlation
                 (bidirectional matrix,
                  cross-reference, gaps)
                               |
                   Phase 3.5: Verification
                 (every claim checked against
                  source files -- mandatory gate)
                               |
                  Phase 4: Report + Q&A
                  (markdown + HTML output)
```

### Phase 1 -- Discovery

Runs shell scripts to orient before heavy reading:

- `detect-stack.sh` -- language, framework, database from manifest files
- `repo-stats.sh` -- git statistics (commits, contributors, velocity)
- `find-images.sh` -- image manifest from handbook

Also reads README, CONTRIBUTING guide, and primary package manifest to build a Discovery Summary passed to all four agents.

### Phase 2 -- Parallel analysis

Four agents launch simultaneously, each receiving the Discovery Summary.

**Agent A (Architecture + Handbook)** reads every handbook markdown file and image, then every code source file. Compares documented architecture against actual code structure and flags divergences.

**Agent B (Code Patterns)** reads every source file and catalogs conventions: naming, error handling, testing, logging, configuration, comments. Includes code snippets and checks whether conventions have evolved over time via git.

**Agent C (API + Data)** maps the complete API surface, every data model, the full dependency tree, and external service integrations. Reads migration files for schema evolution.

**Agent D (Docs + DevOps + Git)** reads CI/CD configs, Dockerfiles, K8s manifests, and remaining handbook files. Runs git log analysis and synthesizes a getting-started guide.

### Phase 3 -- Correlation

Builds a **bidirectional correlation matrix** between handbook pages and code modules:

```
Handbook --> Code                     Code --> Handbook
+-------------------+--------+       +-------------+------------------+----------+
| Handbook Page     | Code   |       | Code Module | Handbook Pages   | Coverage |
+-------------------+--------+       +-------------+------------------+----------+
| auth-design.md    | src/auth/      | src/auth/   | auth-design.md   | Full     |
| scaling-plan.md   | infra/k8s/     | src/api/    | api-reference.md | Partial  |
| task-queue.md     | src/workers/   | src/utils/  | (none)           | None     |
+-------------------+--------+       +-------------+------------------+----------+
```

Correlation methods:

1. **Explicit references** -- file paths, class names, endpoints mentioned in docs
2. **Semantic matching** -- topic/domain keyword matching even without explicit references
3. **Verification** -- every code reference in docs checked against the actual codebase

Cross-reference analysis identifies:
- **Orphaned code** -- modules with zero handbook coverage
- **Stale docs** -- pages referencing renamed or removed code
- **Unimplemented designs** -- proposals with no corresponding code
- **Contradictions** -- handbook pages disagreeing about the same component

### Phase 3.5 -- Verification

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

17-section report:

| # | Section | Covers |
|---|---------|--------|
| -- | Executive Summary | 2-3 paragraph overview |
| 1 | Project Identity | Language, framework, repo stats |
| 2 | Architecture | Component map, layers, diagram analysis, divergences |
| 3 | Directory & Modules | Every directory explained |
| 4 | Tech Stack & Deps | Full dependency table |
| 5 | Entry Points & Flows | Main execution paths |
| 6 | Coding Conventions | Naming, errors, logging -- with code snippets |
| 7 | API Surface | Every endpoint |
| 8 | Data Models | Schema, migrations |
| 9 | Testing | Framework, organization, mocking |
| 10 | Build & CI/CD | Pipeline, containerization |
| 11 | Getting Started | Synthesized setup guide |
| 12 | Handbook Assessment | Per-page inventory, coverage score, proposal status |
| 13 | Correlation Matrix | Bidirectional handbook-to-code mapping |
| 14 | Cross-Reference | Orphaned code, stale docs, contradictions |
| 15 | Verification Summary | Pass rate, corrections, removals |
| 16 | Git History | Velocity, contributors, hot areas |
| 17 | Key Findings | Top 10 things a new engineer should know |

After the report, the conversation stays open for follow-up questions with the full analysis context retained.

### HTML (in browser)

Interactive single-page report at `/tmp/groundwork-report.html`:

- Sidebar navigation with scroll spy
- Collapsible sections, searchable tables
- Color-coded status badges and coverage bars
- Dark/light theme toggle (auto-detects OS preference)
- Print-friendly, mobile-responsive
- Zero external dependencies -- one self-contained file

## Tips

- **Large repos take time.** The skill reads every file. For a 500-file repo with a 30-page handbook, expect 10-15 minutes.
- **Use `--focus` when you know what you need.** Other sections still appear but with less detail.
- **Follow up after the report.** The report gives you the map; follow-up questions let you drill into any corner.
- **The HTML report is shareable.** Single file, no dependencies. Drop it in Slack or host it on a wiki.
- **Re-run after major changes.** The correlation matrix is a snapshot.
