# Cross-Platform Development Bootstrap System Spec

## Overview

This document defines a tool-agnostic `cross-platform development bootstrap system`.
Its purpose is to initialize heterogeneous execution environments into a repeatable,
verifiable development setup with layered consistency across local machines, VMs,
remote hosts, containers, and CI-like environments.

This spec is intended for two readers:

- human maintainers deciding scope, boundaries, and trade-offs
- Agents or automation systems choosing concrete implementation methods such as shell scripts, package managers, configuration management, IaC, images, or orchestration workflows

This spec is distilled from the current repository's concerns and patterns, but it
does not bind future implementations to this repository's current tools.

## Goals

- Provide a reusable bootstrap model for macOS, Linux, Windows, VMs, remote hosts, containers, and CI-like environments.
- Produce a usable and verifiable developer experience rather than merely executing setup steps.
- Preserve a stable abstraction boundary so different tools and methodologies can implement the same system.
- Support repeated execution, migration to new machines, partial reconfiguration, and recovery.
- Allow environment-specific extensions while keeping a shared core experience.

## Non-Goals

- This spec does not mandate specific tools such as `brew`, `apt`, `winget`, `Ansible`, `Nix`, `chezmoi`, `Docker`, or `PowerShell`.
- This spec does not require every environment to expose identical UX or identical software.
- This spec does not require all personalization to be managed; only development-relevant state is in scope.
- This spec does not allow secrets to be stored in source control, reusable templates, or images by default.
- This spec does not require one-shot full setup; staged bootstrap is allowed if each stage is verifiable.

## Design Principles

- Define required outcomes before defining implementation methods.
- Prefer explicit capability declarations over implicit platform assumptions.
- Treat verification as a first-class concern, not a post-install convenience.
- Separate managed state from unmanaged user state.
- Make degradation explicit when a capability cannot be provided in a given environment.
- Optimize for reusability across machines and execution contexts.

## Core Concepts

### Environment

An `Environment` is any target to be initialized, such as a laptop, workstation, VM,
remote host, container, or CI runner.

Each environment has observable properties including:

- operating system and distribution
- interactivity level
- GUI availability
- network availability
- privilege level
- filesystem constraints
- secret access method
- whether it is persistent or ephemeral

### Bootstrap Profile

A `Bootstrap Profile` describes the desired capability set for a use case, not the
implementation mechanism. A profile may depend on other profiles.

Representative examples:

- `base`
- `developer`
- `remote-access`
- `ai-enabled`

### Capability Domain

A `Capability Domain` is a bounded area of responsibility in the bootstrap system.
Each domain MUST define its purpose, inputs, outputs, dependency assumptions,
degradation behavior, and verification contract.

### State Source

A `State Source` is any authoritative source of desired state, including:

- version-controlled configuration
- templates or generators
- inventory or host metadata
- environment parameters
- secret backends
- prebuilt image baselines

### Verification Contract

A `Verification Contract` is the observable definition of success for a capability,
profile, or environment. Success MUST be based on runtime-observable outcomes, not
merely on whether a command was executed.

## Consistency Model

The system uses layered consistency rather than absolute sameness.

### Core Consistency

All target environments SHOULD provide a minimum common development baseline:

- environment identity can be discovered
- configuration roots can be resolved
- a usable shell or command entrypoint exists
- version control can operate
- credentials can be attached through an approved mechanism
- validation commands can run and report structured results

### Profile Consistency

Environments that claim the same profile MUST expose the same capability set at the
spec level, even if tooling differs underneath.

Example: a `developer` profile may use different package managers across operating
systems, but it MUST still yield a working editor/terminal/runtime/toolchain path.

### Environment-Specific Extensions

Some capabilities MAY exist only in specific environments, such as:

- GUI applications
- input methods
- system tray integrations
- system startup hooks
- host-only networking helpers

Such extensions MUST be declared as optional or environment-scoped rather than
assumed globally.

### Degradation Rules

The system MAY degrade capabilities when necessary, but MUST:

- report degradation explicitly
- preserve the main success path for the declared profile when possible
- distinguish `satisfied`, `degraded`, `unsupported`, and `failed`
- avoid reporting unsupported capabilities as successful

## Lifecycle Model

The bootstrap lifecycle consists of the following phases.

### 1. Discover

Detect environment facts, constraints, and existing assets.

This phase MUST identify, when relevant:

- target OS and runtime context
- privilege model
- connectivity and external dependency availability
- existing managed or unmanaged configuration
- whether GUI-dependent capabilities are possible
- secret access options

### 2. Resolve

Translate environment facts, requested profiles, and policies into a resolved target
state.

This phase MUST determine:

- which capability domains are required
- which capabilities are optional
- which capabilities are unsupported in the current context
- which degradations are acceptable
- execution order and dependencies

### 3. Provision

Provide the necessary software, binaries, runtimes, or system prerequisites.

Provisioning MAY be implemented through package managers, images, binary downloads,
host features, or preinstalled baselines.

### 4. Materialize

Place desired configuration and bootstrap artifacts into the environment.

Examples include:

- config files
- generated files
- profile metadata
- command wrappers
- helper scripts
- editor or terminal settings

### 5. Activate

Make the materialized state effective.

Examples include:

- reloading shell startup paths
- enabling services
- creating links or mounts
- refreshing caches
- opening a new session boundary
- generating runtime-specific derived state

### 6. Verify

Evaluate capability, profile, and environment success against verification contracts.

Verification MUST produce structured output suitable for both human review and Agent
consumption.

### 7. Maintain

Support re-entry, drift detection, updates, migrations, and partial recovery.

Bootstrap MUST be treated as an ongoing system, not a single-use installer.

## Capability Domains

The following capability domains define the stable abstraction boundary of the
system.

### Base System Readiness

Purpose: establish minimum environmental viability.

Representative scope:

- detect platform identity
- resolve user and config directories
- confirm writable target locations where applicable
- establish a stable command entrypoint

### Package and Binary Provisioning

Purpose: ensure required development tools are available.

Representative examples:

- `git`
- `ssh`
- editor or terminal binaries
- language runtimes
- auxiliary CLI tools

The spec does not require how tools are obtained, only that required tools become
available in the target execution context.

### Config Materialization

Purpose: bring desired configuration into managed state.

Materialization MAY use copying, linking, templating, rendering, generation,
mounting, or image baking.

Representative examples:

- shell config
- `git` config
- `ssh` config
- editor settings
- terminal settings

### Shell and Command UX

Purpose: provide a predictable command-line working environment.

Representative scope:

- PATH or command discovery setup
- shell startup behavior
- helper commands
- prompt or plugin readiness
- environment module loading

### Editor and Terminal Readiness

Purpose: provide at least one usable development entrypoint.

Representative examples:

- editor configuration
- terminal configuration
- clipboard integration
- workspace helper setup

### Identity, Credentials, and Secret Access

Purpose: attach credentials without embedding long-lived secrets into managed state.

Representative scope:

- `ssh` identity setup
- token access
- session bootstrap
- secret manager integration
- local or remote agent reuse

This domain MUST define behavior when secrets are unavailable.

### Remote and Cross-Host Access

Purpose: allow a developer or Agent to move between environments predictably.

Representative examples:

- SSH host aliases
- proxy settings
- remote workspace entrypoints
- cross-host environment access conventions

### Language and Input Productivity

Purpose: support developer-facing interaction features that affect daily workflow.

Representative examples:

- input method configuration
- locale-sensitive setup
- fonts or rendering prerequisites

This domain MAY be unsupported in headless or ephemeral environments.

### AI and Automation Tooling

Purpose: support Agent-assisted or automation-heavy workflows.

Representative examples:

- AI-oriented CLI tools
- MCP-style service endpoints
- automation helper commands
- execution context adapters

This domain SHOULD be treated as an optional layer unless explicitly required by a
profile.

### Validation and Drift Detection

Purpose: verify expected state and identify divergence over time.

This domain MUST be able to report:

- missing prerequisites
- failed activation
- partial success
- unsupported capabilities
- drift between desired and actual managed state

### Recovery and Re-Bootstrap

Purpose: recover from partial failure or reinitialize a target without destroying
unmanaged assets.

Representative scope:

- rerun safety
- partial rebuilds
- host migration
- machine replacement
- recovery hints after verification failure

## Input Model

An implementation SHOULD accept the following logical inputs.

### Target Descriptor

Describes the target environment, such as:

- OS and distribution
- shell family
- GUI presence
- remote or local status
- container or VM status
- privilege model
- filesystem limitations
- connectivity limitations

### Requested Profile Set

Declares the requested profile combination, such as:

- `base`
- `developer`
- `remote-access`
- `ai-enabled`

### Capability Overrides

Allows explicit deviations from defaults.

Representative examples:

- disable GUI-only capabilities
- prefer a different editor
- force or skip specific shell setup
- disable AI tooling in restricted environments

### State Sources

Provides the desired-state inputs used during resolution and materialization.

### Policy Constraints

Defines non-negotiable operational rules, such as:

- no privilege escalation
- no writes outside user scope
- no persistent secret storage
- offline-only execution
- approved tool restrictions

### Execution Context

Identifies who or what is running the bootstrap flow, such as:

- human operator
- Agent
- CI runner
- remote orchestrator
- image build stage

## Output Model

An implementation SHOULD produce the following logical outputs.

### Resolved Plan

The resolved capability set, dependency graph, platform decisions, and degradation
decisions.

### Materialized State

The managed artifacts placed into the environment.

### Verification Report

A structured report containing per-capability and per-profile status using the
allowed result classes.

### Recovery Hints

Actionable follow-up guidance for manual steps, unmet prerequisites, or policy
conflicts.

## Security and State Rules

### Secret Handling

- Secrets MUST NOT be committed to version control.
- Secrets MUST NOT be baked into reusable templates or images by default.
- Secret-dependent capabilities MUST define behavior for missing or expired secrets.
- Short-lived sessions, external brokers, or environment-native secret systems SHOULD be preferred over static plaintext distribution.

### Scope and Privilege

- Implementations MUST distinguish `user-scope` and `system-scope` changes.
- System-scope changes SHOULD require explicit intent or policy allowance.
- The resolved plan SHOULD state where elevated privilege is required.

### Managed vs Unmanaged State

- The system MUST define which files, directories, services, and generated artifacts it manages.
- The system MUST avoid silently overwriting unmanaged user state.
- Conflict handling SHOULD use explicit strategies such as `reuse`, `replace-with-backup`, `merge-if-supported`, or `leave-unmanaged`.

### Idempotence and Re-Entry

- Repeated execution SHOULD converge on the same managed result.
- Re-running bootstrap MUST NOT require a pristine machine.
- Partial success MUST remain diagnosable and recoverable.

### Drift Awareness

- Implementations SHOULD detect when managed state diverges from desired state.
- Drift reporting SHOULD be specific enough for an Agent or human to decide whether to repair, replace, or leave local customizations untouched.

## Acceptance Criteria

Acceptance is defined at three levels.

### Capability-Level Acceptance

Each capability domain MUST define observable success. Examples:

- a required CLI is invocable in the target context
- a managed config can be located and loaded by the target tool
- a shell session can access expected helper behavior
- a secret access pathway can be exercised without exposing secret material

### Profile-Level Acceptance

A profile is accepted only when all required capabilities are either:

- `satisfied`, or
- `degraded` in a manner explicitly allowed by the profile contract

Any required capability marked `failed` causes profile failure.

### Environment-Level Acceptance

An environment is accepted only when it can complete the main workflow implied by
its declared profile set.

Representative profile expectations:

- `base`: target identity can be discovered, configuration roots can be resolved, shell or command entry is usable, and core validation can run
- `developer`: `base` plus at least one working editor/terminal/runtime/toolchain path
- `remote-access`: at least one working remote access path and a defined credential attachment method
- `ai-enabled`: AI-related tooling works when dependencies are present and degrades explicitly when they are not

## Implementation Freedom

This spec intentionally leaves room for multiple implementation strategies.

Implementations MAY differ in:

- provisioning tools
- config transport mechanisms
- activation mechanisms
- orchestration approach
- host inventory format
- verification implementation details

Implementations MUST remain stable in:

- capability semantics
- lifecycle responsibilities
- status model
- security boundaries
- acceptance criteria shape
- managed vs unmanaged state rules

## Appendix: Example Profile Shapes

### `base`

Minimum profile for any managed environment.

Required domains:

- Base System Readiness
- Config Materialization
- Shell and Command UX
- Validation and Drift Detection

### `developer`

Primary profile for daily interactive development.

Required domains:

- all `base` domains
- Package and Binary Provisioning
- Editor and Terminal Readiness
- Identity, Credentials, and Secret Access

Optional domains:

- Language and Input Productivity
- AI and Automation Tooling

### `remote-access`

Profile for predictable cross-host workflows.

Required domains:

- all `base` domains relevant to the target
- Identity, Credentials, and Secret Access
- Remote and Cross-Host Access
- Validation and Drift Detection

### `ai-enabled`

Profile for Agent-assisted development workflows.

Required domains:

- all domains required by the parent profile it extends
- AI and Automation Tooling

Typical additional constraints:

- secret-backed service access may be required
- remote endpoint discovery may be required
- explicit degradation is required when external services are unavailable
