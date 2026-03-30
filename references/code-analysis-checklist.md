# Code Analysis Checklist

Detailed heuristics for analyzing coding patterns and conventions. For each category, examine files across multiple directories to determine if patterns are consistent project-wide.

## 1. Naming Conventions

### Variables & Functions
- [ ] Identify dominant style: camelCase, snake_case, PascalCase, kebab-case
- [ ] Check consistency across modules -- do different areas use different styles?
- [ ] Look for naming prefixes/suffixes: `is_`, `has_`, `get_`, `set_`, `_private`, `__dunder__`
- [ ] Check boolean naming: `isActive`, `has_permission`, `should_retry`
- [ ] Check constant naming: UPPER_SNAKE_CASE, Title_Case, or same as variables?

### Files & Directories
- [ ] File naming convention: camelCase.js, snake_case.py, kebab-case.ts, PascalCase.java
- [ ] Do file names match the primary export/class? (e.g., `UserService.ts` exports `UserService`)
- [ ] Directory naming: singular vs plural (model/ vs models/, route/ vs routes/)
- [ ] Index/barrel files usage

### Classes & Types
- [ ] PascalCase for classes/types (most languages)
- [ ] Interface naming: `IUser`, `UserInterface`, or just `User`?
- [ ] Generic type parameters: single letter `T`, descriptive `TResult`, or constrained?
- [ ] Enum naming and member naming conventions

### Examples to Capture
For each pattern found, include a 3-5 line code snippet showing the actual convention in use. Format:
```
Convention: [description]
File: [path]
```

## 2. Error Handling

### Exception Patterns
- [ ] Try/catch usage: broad catches vs specific exception types
- [ ] Custom error classes: do they exist? What hierarchy?
- [ ] Error wrapping: do errors preserve context/stack trace?
- [ ] Result/Either types: used instead of exceptions? (Rust Result, Go error, fp-ts Either)

### Error Propagation
- [ ] Are errors swallowed silently? (empty catch blocks)
- [ ] Are errors re-thrown, wrapped, or transformed?
- [ ] Centralized error handler vs per-module handling
- [ ] Error response format for APIs: `{ error: message }`, `{ errors: [] }`, problem+json?

### Recovery & Fallbacks
- [ ] Retry logic: exponential backoff, circuit breakers?
- [ ] Graceful degradation patterns
- [ ] Default values on failure

### Logging on Error
- [ ] Are errors logged with context (request ID, user, operation)?
- [ ] Stack trace inclusion policy
- [ ] Error severity classification

## 3. Testing Patterns

### Framework & Organization
- [ ] Test framework: Jest, Mocha, pytest, Go testing, JUnit, RSpec, etc.
- [ ] Test file location: co-located (`*.test.ts` next to source) or separate (`tests/` directory)?
- [ ] Test naming convention: `test_<function>`, `describe('<Component>')`, `should <behavior>`

### Test Types
- [ ] Unit tests: present? What ratio to source code?
- [ ] Integration tests: testing real dependencies or mocked?
- [ ] End-to-end tests: Playwright, Cypress, Selenium?
- [ ] Snapshot tests: used for UI components?
- [ ] Property-based tests: hypothesis, fast-check?

### Mocking Approach
- [ ] Mocking library: jest.mock, unittest.mock, testify.mock, Mockito?
- [ ] Dependency injection for testability?
- [ ] Test doubles: mocks, stubs, fakes, spies -- which are preferred?
- [ ] External service mocking: nock, responses, WireMock?

### Fixtures & Setup
- [ ] Test fixture pattern: factory functions, fixtures files, builders?
- [ ] Setup/teardown: beforeEach, setUp, test decorators?
- [ ] Database seeding approach for integration tests
- [ ] Shared test utilities or helpers

### Assertion Style
- [ ] Assertion library and style: expect().toBe(), assert.equal(), assertThat()
- [ ] Custom matchers present?
- [ ] Assertion message quality

## 4. Logging & Observability

### Logging
- [ ] Structured logging (JSON) vs unstructured (plain text)?
- [ ] Logging library: winston, pino, logrus, zerolog, logging (Python), log4j?
- [ ] Log levels: how are DEBUG, INFO, WARN, ERROR used?
- [ ] Contextual fields: request ID, user ID, operation name?
- [ ] Sensitive data redaction in logs?

### Tracing
- [ ] Distributed tracing: OpenTelemetry, Jaeger, Zipkin, X-Ray?
- [ ] Span creation patterns
- [ ] Trace context propagation

### Metrics
- [ ] Metrics library: prometheus, statsd, datadog?
- [ ] Custom metrics defined?
- [ ] Health check endpoints

## 5. Configuration Management

### Environment Variables
- [ ] How are env vars accessed? Direct `process.env`, `os.environ`, or via config module?
- [ ] Validation on startup: are required vars checked?
- [ ] `.env.example` or `.env.sample` present with documentation?
- [ ] Secret management: Vault, AWS Secrets Manager, or plain env vars?

### Config Files
- [ ] Config file format: JSON, YAML, TOML, INI?
- [ ] Environment-specific configs: `config/production.yml`, `config/development.yml`?
- [ ] Config merging/override strategy

### Feature Flags
- [ ] Feature flag system: LaunchDarkly, Unleash, custom?
- [ ] Flag naming conventions
- [ ] Flag cleanup process

## 6. Code Comments

### Density & Style
- [ ] Comment density: heavily commented, sparse, or none?
- [ ] Documentation comment format: JSDoc, docstrings, Rustdoc, Javadoc, GoDoc?
- [ ] Inline comments: when are they used? (explaining "why" vs "what")
- [ ] TODO/FIXME/HACK/XXX comments: how many? Are they tracked?

### What Gets Documented
- [ ] Public API documentation: comprehensive or missing?
- [ ] Complex algorithm explanations
- [ ] Workaround explanations with issue references
- [ ] License headers

## 7. Linting & Formatting

### Configuration
- [ ] Linter: ESLint, Ruff, golangci-lint, Clippy, RuboCop, Checkstyle?
- [ ] Formatter: Prettier, Black, gofmt, rustfmt?
- [ ] Config file presence and customization level
- [ ] Pre-commit hooks enforcing lint/format?

### Key Rules
- [ ] Line length limit
- [ ] Import ordering rules
- [ ] Unused variable/import rules
- [ ] Type annotation requirements

## 8. Code Organization

### Module Structure
- [ ] How are modules/packages organized? By feature, by layer, by domain?
- [ ] Barrel/index files: re-exporting from a single entry point?
- [ ] Circular dependency prevention
- [ ] Internal vs public module boundaries

### Dependency Direction
- [ ] Clean architecture layers? Domain -> Application -> Infrastructure?
- [ ] Are dependencies inverted (interfaces in domain, implementations in infrastructure)?
- [ ] Import restrictions between modules

### Common Patterns
- [ ] Repository pattern for data access?
- [ ] Service layer pattern?
- [ ] Factory, Builder, Strategy patterns?
- [ ] Middleware/pipeline patterns?
- [ ] Event-driven patterns (pub/sub, event bus)?

## Git-Based Convention Analysis

To assess whether conventions are consistent over time:

```bash
# Find the oldest source files
git log --diff-filter=A --format='%ci %s' --name-only -- '*.py' | head -50

# Find the newest source files
git log --diff-filter=A --format='%ci %s' --name-only -- '*.py' --since='6 months ago' | head -50
```

Compare conventions in old files vs new files. Note any evolution in style:
- Did naming conventions change?
- Did error handling patterns evolve?
- Were new testing patterns adopted?
- Did a linter/formatter get added at some point (visible as a large formatting commit)?
