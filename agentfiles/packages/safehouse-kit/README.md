# safehouse-kit

`safehouse-kit` packages shell wrappers and sandbox policy assets for running
agent commands through a vendored Safehouse runtime.

## Included

- Public interface commands in `.local/bin/`:
  - `safe`, `safe-opencode`/`soc`, `safe-codex`/`scx`
- Internal runtime assets in `.local/lib/safehouse-kit/`:
  - command entrypoints, `sandbox-agent.sh`, `sandbox-agent.fish`
  - local policy profile `agents-local.sb`
- Vendored runtime script:
  - `.local/lib/safehouse-kit/vendor/safehouse`

## Dependency diagram

```mermaid
flowchart LR
  subgraph BIN[".local/bin (public wrappers)"]
    bin_safe["safe"]
    subgraph BIN_O["safe-opencode/soc"]
      bin_safe_opencode["safe-opencode"]
      bin_soc["soc"]
    end
    subgraph BIN_C["safe-codex/scx"]
      bin_safe_codex["safe-codex"]
      bin_scx["scx"]
    end
  end

  subgraph LIB[".local/lib/safehouse-kit (internal scripts)"]
    lib_safe["safe"]
    subgraph LIB_O["safe-opencode/soc"]
      lib_safe_opencode["safe-opencode"]
      lib_soc["soc"]
    end
    subgraph LIB_C["safe-codex/scx"]
      lib_safe_codex["safe-codex"]
      lib_scx["scx"]
    end
    lib_sandbox["sandbox-agent.sh"]
    lib_vendor["vendor/safehouse"]
  end

  bin_safe --> lib_safe
  bin_safe_opencode --> lib_safe_opencode
  bin_soc --> lib_soc
  bin_safe_codex --> lib_safe_codex
  bin_scx --> lib_scx

  lib_safe --> lib_sandbox
  lib_safe_opencode --> lib_sandbox
  lib_soc --> lib_safe_opencode
  lib_safe_codex --> lib_sandbox
  lib_scx --> lib_safe_codex
  lib_sandbox --> lib_vendor
```

## Security posture

Agents are limited by the sandbox and run with all permissions inside it.

- `safe-codex` runs with `--yolo`.
- `safe-opencode` sets broad `OPENCODE_PERMISSION` grants.
- `agents-local.sb` includes local path and Dolt access grants (specific to my own setup).

## What to customize before use

- Remove or narrow broad permission flags and grants.
- Restrict filesystem path grants in `agents-local.sb` to minimum required
  paths.
- Review and tighten environment variable passthrough behavior.
- Validate policy behavior in your own runtime environment before use with
  sensitive repositories.
