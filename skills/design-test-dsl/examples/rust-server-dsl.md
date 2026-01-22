# Rust Server DSL Example

Framework-agnostic example of a behaviour-driven DSL for server/API testing using plain assertions.

## Design Philosophy

- No framework-specific abstractions in the DSL
- Plain `assert!` / `assert_eq!` for all assertions
- Context objects carry test state through the DSL chain
- Lifetimes or ownership patterns for resource cleanup

## Core Types

```rust
// Response abstraction (framework-agnostic)
struct Response {
    status: u16,
    headers: HashMap<String, String>,
    body: Vec<u8>,
}

impl Response {
    fn json<T: serde::de::DeserializeOwned>(&self) -> T {
        serde_json::from_slice(&self.body).expect("Valid JSON")
    }

    fn text(&self) -> &str {
        std::str::from_utf8(&self.body).expect("Valid UTF-8")
    }
}

// Test context
struct TestContext {
    server: TestServer,
    temp_dir: TempDir,
}

struct TestServer {
    addr: SocketAddr,
    process: Child, // or JoinHandle for in-process servers
}

struct TempDir(tempfile::TempDir);
```

## Given: Preconditions

```rust
fn given_empty_server() -> TestContextBuilder {
    TestContextBuilder::new()
}

struct TestContextBuilder {
    temp_dir: Option<TempDir>,
    port: Option<u16>,
    tls: bool,
    auth: bool,
}

impl TestContextBuilder {
    fn new() -> Self {
        Self {
            temp_dir: None,
            port: None,
            tls: false,
            auth: false,
        }
    }

    fn with_port(mut self, port: u16) -> Self {
        self.port = Some(port);
        self
    }

    fn with_tls(mut self) -> Self {
        self.tls = true;
        self
    }

    fn with_auth(mut self) -> Self {
        self.auth = true;
        self
    }

    fn build(self) -> TestContext {
        let temp_dir = self.temp_dir.unwrap_or_else(|| {
            TempDir(tempfile::tempdir().unwrap())
        });
        let server = TestServer::start(self.port, self.tls, self.auth);
        TestContext { server, temp_dir }
    }
}
```

## When: Actions

```rust
impl TestContext {
    fn when_get(&self, path: &str) -> Response {
        self.client().get(path).send()
    }

    fn when_post(&self, path: &str, body: &[u8]) -> Response {
        self.client().post(path).body(body).send()
    }

    fn when_put(&self, path: &str, body: &[u8]) -> Response {
        self.client().put(path).body(body).send()
    }

    fn when_delete(&self, path: &str) -> Response {
        self.client().delete(path).send()
    }

    fn client(&self) -> reqwest::blocking::Client {
        let protocol = if self.server.tls { "https" } else { "http" };
        reqwest::blocking::Client::builder()
            .danger_accept_http_certs(true)
            .build()
            .unwrap()
    }
}
```

## Plain Assertions

```rust
#[test]
fn server_returns_health_check() {
    let ctx = given_empty_server().build();

    let response = ctx.when_get("/health");

    assert_eq!(response.status, 200);
    assert_eq!(response.text(), "ok");
}

#[test]
fn server_returns_404_for_unknown_route() {
    let ctx = given_empty_server().build();

    let response = ctx.when_get("/unknown");

    assert_eq!(response.status, 404);
}

#[test]
fn server_accepts_json_post() {
    let ctx = given_empty_server().build();
    let payload = r#"{"name": "test", "value": 42}"#;

    let response = ctx.when_post("/api/items", payload.as_bytes());

    assert_eq!(response.status, 201);
    let json: serde_json::Value = response.json();
    assert_eq!(json["id"], 1);
}
```

## Complete Test Examples

```rust
#[test]
fn create_user_requires_authentication() {
    let ctx = given_empty_server()
        .with_auth()
        .build();

    // Without auth token
    let response = ctx.when_post("/api/users", b"{}");
    assert_eq!(response.status, 401);

    // With auth token (add auth header)
    let response = ctx
        .client()
        .post(&format!("http://{}/api/users", ctx.server.addr))
        .header("Authorization", "Bearer valid-token")
        .body(b"{}")
        .send();

    assert_eq!(response.status, 201);
}

#[test]
fn list_items_returns_paginated_results() {
    let ctx = given_empty_server().build();

    // First page
    let response = ctx.when_get("/api/items?page=1&limit=10");
    assert_eq!(response.status, 200);
    let json: serde_json::Value = response.json();
    assert!(json["items"].is_array());
    assert!(json["items"].as_array().unwrap().len() <= 10);
    assert_eq!(json["total"], 100);
}

#[test]
fn tls_connection_works() {
    let ctx = given_empty_server()
        .with_port(8443)
        .with_tls()
        .build();

    let response = ctx.when_get("/health");

    assert_eq!(response.status, 200);
}
```

## Composition Pattern

```rust
fn given_authenticated_server() -> TestContextBuilder {
    given_empty_server().with_auth()
}

// Usage: chain builder methods, then build
let ctx = given_authenticated_server()
    .with_port(8080)
    .with_tls()
    .build();

let response = ctx.when_get("/api/protected");
assert_eq!(response.status, 200);
```

## Resource Cleanup

```rust
impl Drop for TestContext {
    fn drop(&mut self) {
        // Graceful shutdown
        self.server.process.kill().ok();
        self.server.process.wait().ok();
        // temp_dir automatically cleaned up
    }
}

// Or use guard pattern for explicit cleanup timing
struct ServerGuard {
    server: TestServer,
}

impl Drop for ServerGuard {
    fn drop(&mut self) {
        self.server.stop();
    }
}

fn given_server_running() -> ServerGuard {
    let server = TestServer::start(None, false, false);
    ServerGuard { server }
}
```

## Key Design Choices

| Choice | Rationale |
|--------|-----------|
| Framework-agnostic `Response` | Tests don't depend on specific web framework |
| Builder pattern for setup | Composable, readable precondition setup |
| Plain assertions | Failures show clear error messages |
| Drop trait for cleanup | No manual teardown needed; RAII handles it |
| No custom matchers | Standard Rust assertions are sufficient |
