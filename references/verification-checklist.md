# Verification Checklist

Every factual claim in the analysis must be verified against the actual source files in the code repo or handbook repo before it appears in the final report. This checklist defines the verification procedure for each claim type.

## 1. File Existence

**What to check:** Every file path mentioned anywhere in the analysis.

**Procedure:**
- Run `Glob` with the exact path in the appropriate repo
- If not found, try common variations (case differences, extension changes)
- If still not found: REMOVE the claim from the report

**Examples:**
```
Claim: "src/auth/jwt.py handles token validation"
Verify: Glob for src/auth/jwt.py in code repo
Result: PASSED (file exists) or REMOVED (file not found)
```

## 2. Code Snippets

**What to check:** Every code example included in the conventions or patterns section.

**Procedure:**
- Grep for distinctive strings from the snippet in the cited file
- If the snippet doesn't match, Read the file and extract the actual text
- If the file doesn't contain anything similar: REMOVE the example
- If the file contains a slightly different version: CORRECT the snippet

**Examples:**
```
Claim: Code example showing `user_name = get_current_user()` from src/views.py
Verify: Grep "get_current_user" in src/views.py
Result: PASSED (exact match) or CORRECTED (actual line is `current_user = get_current_user()`)
```

## 3. API Endpoints

**What to check:** Every endpoint in the API surface table (method, path, handler, auth).

**Procedure:**
- Grep for the route path pattern in the code repo
- Confirm the HTTP method matches
- Confirm the handler function/class exists
- If the endpoint is not found: REMOVE from the table

**Examples:**
```
Claim: "GET /api/v1/users -> list_users (JWT auth)"
Verify: Grep "/api/v1/users" or "list_users" in route files
Result: PASSED or REMOVED
```

## 4. Dependencies

**What to check:** Every dependency name and version in the dependency table.

**Procedure:**
- Read the package manifest (package.json, requirements.txt, Cargo.toml, etc.)
- Confirm the dependency name exists in the manifest
- Confirm the version matches (or note the actual version)
- If not in manifest: REMOVE or FLAG

**Examples:**
```
Claim: "express 4.18.2 (HTTP server framework)"
Verify: Read package.json, check "express" in dependencies
Result: PASSED or CORRECTED (actual version is 4.19.0)
```

## 5. Data Models

**What to check:** Every model, field, and relationship described.

**Procedure:**
- Read the model definition file
- Confirm the model/class exists
- Confirm each listed field exists with the stated type
- Confirm relationships (foreign keys, references) exist

**Examples:**
```
Claim: "User model has fields: id, email, hashed_password, created_at"
Verify: Read src/models/user.py, check field definitions
Result: PASSED or CORRECTED (field is "password_hash" not "hashed_password")
```

## 6. Handbook Content Claims

**What to check:** Every claim about what a handbook page says or describes.

**Procedure:**
- Read the handbook page
- Confirm the claim accurately represents the content
- For correlation matrix entries: confirm the page actually discusses the correlated code area

**Examples:**
```
Claim: "auth-design.md describes a JWT-based authentication flow"
Verify: Read auth-design.md, check if it discusses JWT authentication
Result: PASSED or CORRECTED (it actually describes OAuth2, not JWT)
```

## 7. Git Statistics

**What to check:** Every git statistic (commit counts, contributor counts, velocity).

**Procedure:**
- Re-run the specific git command that produces the statistic
- Compare with the reported number
- If they don't match: CORRECT with the actual number

**Examples:**
```
Claim: "342 commits, 12 contributors, 45 commits in last 90 days"
Verify: git rev-list --count HEAD; git shortlog -sn | wc -l; git log --since='90 days ago' --oneline | wc -l
Result: PASSED or CORRECTED (actual is 338 commits)
```

## 8. Architecture Claims

**What to check:** Claims about how components communicate or integrate.

**Procedure:**
- Grep for evidence of the claimed integration pattern
- For "Service A calls Service B via HTTP": search for HTTP client calls to Service B's URL/endpoint
- For "uses message queue": search for queue library imports and publish/subscribe calls

**Examples:**
```
Claim: "The task service communicates with the notification service via Redis pub/sub"
Verify: Grep for Redis publish/subscribe patterns in task service code
Result: PASSED (found redis.publish calls) or REMOVED (no evidence found)
```

## 9. Diagram Analysis

**What to check:** Claims about what architecture diagrams depict.

**Procedure:**
- Re-read the image file using Read tool
- Confirm the described components and connections are visible in the diagram
- If the analysis misidentified elements: CORRECT

**Examples:**
```
Claim: "system-overview.png shows 3 microservices connected via API gateway"
Verify: Read system-overview.png, count services and check gateway
Result: PASSED or CORRECTED (actually shows 4 services)
```

## 10. Design Proposal Status

**What to check:** Whether proposals marked as "implemented" have corresponding code.

**Procedure:**
- For "Implemented": Glob + Grep for the key components described in the proposal
- For "Partial": Verify which parts exist and which don't
- For "Pending" or "Abandoned": Confirm no corresponding code exists

**Examples:**
```
Claim: "Auth redesign RFC is fully implemented"
Verify: Check that all components described in the RFC exist in code
Result: PASSED or CORRECTED to "Partial" (OAuth2 provider not implemented yet)
```

## 11. Correlation Matrix Entries

**What to check:** Every handbook-to-code correlation pair.

**Procedure:**
- Confirm the handbook page exists
- Confirm the code module/file exists
- For "Explicit" matches: confirm the handbook page actually contains a reference to the code path
- For "Semantic" matches: confirm the topics genuinely overlap (not a false match)

**Examples:**
```
Claim: "auth-design.md -> src/auth/ (Explicit, Strong)"
Verify: Read auth-design.md, search for "src/auth" or references to auth module
Result: PASSED or CORRECTED (match type should be "Semantic" not "Explicit")
```

## Verification Summary Format

After checking all claims, produce:

```
TOTAL CLAIMS CHECKED: X
PASSED: N (confirmed against source)
CORRECTED: N (auto-fixed, list corrections below)
REMOVED: N (unverifiable, list removals below)
FLAGGED: N (need manual review, list flagged items below)
PASS RATE: X%
CONFIDENCE: High (>95%) / Medium (85-95%) / Low (<85%)
```

## Rules

1. **Never include unverified data.** If a claim cannot be confirmed against either repo, remove it.
2. **Prefer correction over removal.** If a claim is mostly right but has a minor error (wrong version, typo in path), fix it rather than removing it.
3. **Be transparent about changes.** Every correction and removal must be listed in the verification summary so the user knows what was changed and why.
4. **Re-verify git stats fresh.** Git statistics can drift between when the agent ran and when verification happens. Always use the freshest numbers.
5. **Flag ambiguous cases.** If you're not sure whether a claim is accurate, flag it for manual review rather than silently passing or removing it.
