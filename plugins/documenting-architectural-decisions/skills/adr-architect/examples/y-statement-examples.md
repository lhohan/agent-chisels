# Y-Statement Examples

All examples below are from actual production decision logs. They demonstrate varied complexity, different decision types, and various trade-off scenarios.

## Example 1: Infrastructure Technology Choice

### WEB-001: Nginx/Caddy for static sites [Yes]

> **In the context of** hosting multiple static sites on Hetzner,
> **facing** the need for simplicity and efficient resource use,
> **we decided** to serve static sites directly with Nginx or Caddy (reserving Docker for dynamic apps),
> **to achieve** streamlined management and minimized overhead.

**Key features**:
- Clear context (hosting environment)
- Explicit constraint (efficiency)
- Alternatives mentioned (Docker reserved for later)
- Simple, focused decision with minimal trade-offs

## Example 2: Security Hardening Decision

### WEB-013: Enable SSH host key verification [Yes]

> **In the context of** Ansible SSH security,
> **facing** MITM attack risks from disabled host key verification,
> **we decided** to enable host_key_checking=True and remove UserKnownHostsFile=/dev/null,
> **accepting** the one-time manual SSH requirement to ensure cryptographic verification of server identity during all provisioning operations.

**Key features**:
- Security-focused decision
- Clear threat model (MITM attacks)
- Explicit trade-off (one-time manual step)
- Explains what the trade-off achieves (verification)

## Example 3: Process Decision with Deferral

### WEB-009: Defer firewall hardening to Task 3 [Yes]

> **In the context of** server hardening scope definition,
> **facing** the tension between immediate security and task boundaries,
> **we decided** Task 2 covers SSH-only hardening (key auth, root disabled) while deferring firewall/fail2ban to Task 3,
> **accepting** short-term exposure to prioritize systematic verification over rushed comprehensive hardening.

**Key features**:
- Process/scope decision, not technology
- Acknowledges constraints (scope boundaries)
- Clear risk acceptance (short-term exposure)
- Prioritization reasoning (systematic > rushed)

## Example 4: Deferred Decision (Not Yet Implemented)

### WEB-025: Defer WASM migration [No]

> **In the context of** running the Secret Santa Rust service as a WebAssembly module with WasmEdge,
> **facing** the discovery that standard Tokio lacks TCP socket support for wasm32-wasip1 and requires refactoring to wasmedge-async-runtime,
> **we decided** to defer WASM migration and continue running as a traditional container,
> **to achieve** production stability without non-trivial code refactoring (2-4 hours),
> **accepting** larger image size and slower cold starts while WasmEdge async ecosystem matures.

**Key features**:
- Deferral decision (not rejected, just postponed)
- Clear business logic (risk vs. effort calculation)
- Specific effort estimate (2-4 hours)
- Temporary trade-offs with clear reasoning (ecosystem maturity)
- Demonstrates ongoing monitoring of technology readiness

## Example 5: Complex Multi-Component Decision

### WEB-018: Split user responsibilities for CI/CD security [Yes]

> **In the context of** preparing for future CI/CD automation,
> **facing** the tension between simple manual operations and secure automated deployment,
> **we decided** to split user responsibilities into provisioner (full sudo, manual Ansible from laptop) and deployer (restricted sudo for Caddy reload and rsync to /srv/www only) with separate SSH keys (hetzner and hetzner_deploy) and separate playbooks (provision.yml and deploy.yml),
> **to achieve** security boundaries before automation is added,
> **accepting** 30-40 minutes of upfront work to avoid infrastructure changes when deployment credentials will live in CI/CD secrets, ensuring that compromise of CI/CD pipeline cannot escalate to root access or package installation.

**Key features**:
- Complex decision involving multiple components (users, keys, playbooks)
- Anticipatory (building for future CI/CD)
- Strong security rationale (privilege separation)
- Specific effort estimate (30-40 minutes)
- Clear risk model (CI/CD compromise scenario)
- Long but comprehensive—readability acceptable because of importance

## Example 6: Domain Redirect Strategy

### WEB-032: 301 redirect for fractionalarchitect.eu [Yes]

> **In the context of** promoting fractionalarchitect.eu as a branded consulting service domain,
> **facing** the choice between DNS-level redirection, standalone site, or HTTP redirect,
> **we decided** to implement a 301 permanent redirect from fractionalarchitect.eu to hanlho.com/fractional-architect/ with per-domain access logging and dedicated GoAccess analytics,
> **to achieve** SEO authority consolidation on the primary brand, trackable referral source via separate logs + Referer headers, professional appearance with clean URLs, and future flexibility to convert to a standalone site without SEO penalty,
> **accepting** the one-time implementation overhead of Caddy configuration, analytics setup, and DNS propagation in exchange for a sustainable long-term approach that supports both immediate marketing and organizational needs.

**Key features**:
- Marketing/organizational decision
- Multiple alternatives explicitly considered (DNS, standalone, HTTP)
- Balance of immediate and future needs
- Both technical and business reasoning
- SEO considerations mentioned
- Demonstrates thinking beyond technical implementation

## When to Use These Examples

Each demonstrates a different decision type and complexity level. Use them as templates when writing your own decisions:

1. **WEB-001**: Simple infrastructure decisions—clear context and decision
2. **WEB-013**: Security decisions—clear threat model and trade-offs
3. **WEB-009**: Process decisions—scope boundaries and prioritization
4. **WEB-025**: Deferred decisions—risk vs. effort calculation
5. **WEB-018**: Complex decisions—multiple components, forward-thinking
6. **WEB-032**: Business decisions—balance of stakeholder needs
