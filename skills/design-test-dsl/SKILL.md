---
name: design-test-dsl
description: Design fluent, behaviour-driven test DSLs (Given/When/Then) for acceptance and unit tests against stable interfaces. Use when tests should be added or modified.
version: "0.1.0"
---

# Designing Behaviour-Driven Test DSLs

Design fluent, composable test DSLs that express behaviour at stable system boundaries using the Given/When/Then pattern. Applies to acceptance tests (CLI, server APIs) and unit tests against stable interfaces.

## When to Use This Skill

- Designing acceptance tests for CLI tools, servers, or external APIs
- Creating unit tests that verify behaviour, not implementation
- Building reusable test patterns across multiple test files
- Tests require complex setup or assertions worth encapsulating

## Core Principles

### 1. Design for Behaviour, Not Implementation

Test DSLs operate at stable interfaces—the public API of a component. Avoid exposing internal state or implementation details in your DSL.

**Good**: `when_user_submits_valid_form().then_success_response()`  
**Avoid**: `when_form_state_is_valid_and_handler_called().then_response_status_equals(200)`

### 2. Keep Assertions Plain

DSL methods should return objects or values, not perform assertions. Callers use plain assertions:

```rust
// DSL provides fluent setup, assertions stay explicit
let session = given_logged_in_user();
let response = when_user_requests_profile(&session);
assert_eq!(response.status(), Status::Ok);
```

### 3. Compose Through Method Chains

Design composable builders where each method returns `self` or a transition object:

```
given_*() → returns Context
when_*()  → returns Action Result
then_*()  → returns AssertionHelper (rare; prefer plain assertions)
```

### 4. Hide Complexity Behind Simple Names

Complex setup becomes one-liners:

```rust
// Instead of: temp_dir().with_config(write_config()).spawn_server();
let _server = given_server_running().with_tls_config().at_port(8443);
```

---

## DSL Structure

### Given: Preconditions and Fixtures

`given_*` methods establish test preconditions. Return context objects that carry state.

```typescript
interface TestContext {
  tempDir: Path;
  config: Config;
  server?: Server;
}

function givenTempDirectory(): TestContext {
  const dir = createTempDir();
  return { tempDir: dir, config: defaultConfig() };
}

function givenServerRunning(ctx: TestContext): TestContext {
  const server = startServer(ctx.config);
  return { ...ctx, server };
}
```

### When: Actions and Stimuli

`when_*` methods perform the action under test. Return results or response objects.

```typescript
interface Response {
  status: number;
  body: unknown;
}

function whenUserPostsForm(ctx: TestContext, form: FormData): Response {
  return ctx.server!.post('/submit', form);
}

function whenCliExecutes(args: string[]): CliResult {
  return Command::new("app").args(args).output();
}
```

### Then: Assertions (Optional)

Prefer plain assertions. If DSL assertions are essential, keep them simple:

```typescript
function thenStatusIs(response: Response, expected: number): void {
  assert_eq!(response.status, expected);
}
```

---

## Design Patterns

### Pattern 1: Context Builder

Chain `given_*` methods to build complex test state:

```rust
let test_env = given_temp_directory()
    .with_config(custom_config())
    .with_database seeded with_users());

let server = given_server_running()
    .on_address("127.0.0.1:0")
    .with_middleware(auth);

let response = when_client_requests(server.addess(), "/api/data");
assert_eq!(response.status(), 200);
```

### Pattern 2: Transition Objects

Separate concerns by returning typed transition objects:

```rust
// Given stage returns ServerBuilder
let server = given_server_running();

// ServerBuilder provides when_* methods
let response = server.when().get("/health").send();

// Response provides then_* methods
response.then().status_is(200);
```

### Pattern 3: Resource Lifecycle

Handle cleanup through RAII or explicit teardown:

```rust
let _guard = given_server_running().with_auto_cleanup();

#[test]
fn test_server_behavior() {
    // server runs for test duration
    // automatically stopped when guard drops
}
```

### Pattern 4: Custom Matchers

For domain-specific assertions, create matchers:

```rust
fn assert_response_contains(response: &Response, expected: &str) {
    assert!(
        response.body().contains(expected),
        "Response body should contain '{}'\nActual: {}",
        expected,
        response.body()
    );
}
```

---

## Common Patterns by Domain

### CLI Testing

```rust
fn when_cli_runs(args: &[&str]) -> CliOutput {
    Command::new("myapp")
        .args(args)
        .output()
        .expect("CLI execution failed")
}

#[test]
fn cli_shows_help() {
    let output = when_cli_runs(&["--help"]);
    assert!(output.status.success());
    assert!(output.stdout.contains("Usage:"));
}
```

### HTTP/API Testing

```rust
fn given_api_server() -> ApiServer {
    ApiServer::new(default_config())
}

#[test]
fn api_returns_created_user() {
    let server = given_api_server();
    let response = server
        .when()
        .post("/users", json!({"name": "Alice"}))
        .send();
    assert_eq!(response.status(), 201);
    assert!(response.json().contains_key("id"));
}
```

### Database Testing

```rust
fn given_database_with_users(users: &[User]) -> TestDatabase {
    let db = TestDatabase::empty();
    db.insert_users(users);
    db
}

#[test]
fn query_returns_active_users() {
    let db = given_database_with_users(&[user("alice", active()), user("bob", inactive())]);
    let results = db.when().query_active_users();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].name, "alice");
}
```

---

## Anti-Patterns to Avoid

### 1. Leaking Implementation Details

```rust
// Bad: Exposes internal state
when_cache_invalidator_hits_memory();
when_orm_session_flushed();

// Good: Behaviour-focused
when_user_updates_email("new@example.com");
```

### 2. Over-Abstracting

If a DSL hides what the test actually does, it reduces clarity:

```rust
// Bad: Too abstract, can't understand what's being tested
user().performs().accountUpdate();

// Good: Clear what happens
when_user_updates_profile(name = "Alice");
```

### 3. Assertion Methods that Fail Silently

```rust
// Bad: Returns bool, caller might ignore
fn then_response_ok() -> bool { ... }

// Good: Explicit failure
fn assert_response_ok() { ... }
```

### 4. Global State

Avoid DSLs that modify or rely on global state between tests:

```rust
// Bad: Shared mutable state
static mut TEST_SERVER: Option<Server> = None;

// Good: Explicit context passing
let ctx = given_test_server();
```

---

## Testing Your DSL

Validate your DSL design by checking:

1. **Readability**: Can someone read the test and understand the behaviour?
2. **Composability**: Can you combine multiple `given_*` steps naturally?
3. **Debuggability**: When tests fail, is it clear what went wrong?
4. **Maintainability**: Does adding a new test case require changes to the DSL?

---

## Examples

- [Rust CLI DSL](./examples/rust-cli-dsl.md) — CLI testing with `assert_cmd`
- [Rust Server DSL](./examples/rust-server-dsl.md) — Framework-agnostic server testing

---

## References

- [Cucumber: Given-When-Then](https://cucumber.io/docs/gherkin/reference/#given-when-then-then)
- [Martin Fowler: DSLs](https://martinfowler.com/books/dsl.html)
- [Rust Testing Philosophy](https://doc.rust-lang.org/book/ch11-00-testing.html)
