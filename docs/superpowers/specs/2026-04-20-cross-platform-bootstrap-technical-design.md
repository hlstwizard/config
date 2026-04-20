# Cross-Platform Bootstrap Technical Design

## Overview

This document refines the higher-level `Cross-Platform Development Bootstrap System`
spec into a concrete recommended design.

The recommended stack is:

- platform-native package managers for provisioning
- `chezmoi` for state materialization and templated configuration
- lightweight activation hooks for post-apply state changes
- an independent verification layer for profile acceptance

The design target is a cross-platform developer environment with layered consistency
across macOS, Linux, Windows, VMs, remote hosts, containers, and CI-like contexts.

## Recommended Stack

### Provisioning Layer

Use platform-native package managers as the default provisioning path.

- macOS: `Homebrew`
- Debian/Ubuntu: `apt`
- Fedora: `dnf`
- Windows: `winget`

This layer is responsible for making tools available. It is not responsible for
rendering configuration or expressing host-specific policy.

### State Materialization Layer

Use `chezmoi` as the primary state materialization system.

`chezmoi` is responsible for:

- storing and applying managed configuration state
- rendering OS-aware, profile-aware, and host-aware templates
- integrating with secret backends when needed
- managing file placement and managed/unmanaged boundaries
- running lightweight scripts where materialized state needs activation help

### Activation Layer

Use lightweight post-materialization actions to make already-rendered state effective.

This layer is responsible for:

- reloading or refreshing user-scope configuration
- creating derived files or caches
- running small post-apply setup actions
- surfacing required manual next steps

### Verification Layer

Use a separate verification layer to determine whether an environment actually meets
the declared profile contract.

This layer is responsible for:

- package-level verification
- config-level verification
- workflow-level verification
- structured output for both humans and Agents

## Tool Baseline

This design assumes `chezmoi v2.70.2`.

The following `chezmoi` capabilities are considered part of the design baseline:

- template system
- `.chezmoidata*`
- scripts and hooks
- externals
- secret manager integrations
- `.chezmoiversion`

Implications:

- implementations should declare a minimum supported `chezmoi` version, preferably with `.chezmoiversion`
- future updates to `chezmoi` should trigger a design review when they affect templates, special files, scripts, externals, or secret behavior
- this document should be revised when `chezmoi` changes in ways that affect the design assumptions below

## Design Rationale

This design intentionally separates concerns.

- Package managers answer: how do required tools become available on this platform?
- `chezmoi` answers: what managed state should exist on this machine?
- activation answers: what minimal actions are required to make that state effective?
- verification answers: does the resulting environment satisfy the declared profile?

This keeps package provisioning, state expression, side effects, and acceptance logic
from collapsing into one opaque bootstrap script.

## Layer Responsibilities

### 1. Platform Provisioning Layer

Responsibilities:

- install or provide required binaries, runtimes, and applications
- resolve platform-specific package names and install channels
- report installation failures in platform terms

Non-responsibilities:

- configuration rendering
- host policy expression
- secret injection
- profile acceptance

Rules:

- prefer the platform-native package manager as the default channel
- allow exceptions only when the native channel is missing, too outdated, or not viable on the target platform
- record exceptions explicitly rather than hiding them inside ad hoc scripts

### 2. State Materialization Layer

Responsibilities:

- define the desired managed configuration state
- render config from shared, profile, platform, and host inputs
- place files at target paths
- keep managed and unmanaged state boundaries explicit

Non-responsibilities:

- full package installation orchestration
- long-running imperative workflows
- complete environment verification

### 3. Activation Layer

Responsibilities:

- enable materialized state to take effect
- generate small derived artifacts
- run lightweight user-scope refresh actions
- communicate required manual follow-up actions

Non-responsibilities:

- package provisioning
- hidden repair logic
- long procedural setup chains

### 4. Verification Layer

Responsibilities:

- check actual availability and usability of tools
- verify config is not only present but effective
- evaluate profile acceptance against observable workflows

Non-responsibilities:

- silently applying fixes
- mutating environment state as part of validation

## Profile Model

The technical design assumes the following stable profile set:

- `base`
- `developer`
- `remote-access`
- `ai-enabled`

Rules:

- profiles express desired capability sets, not package-manager-specific commands
- profiles may extend other profiles
- host overrides may narrow or add local behavior, but should not redefine profile semantics

## Repository and Data Organization

### Logical Organization Model

Configuration should be organized around four logical layers:

- shared
- profile
- platform
- host

These layers should be combined, not duplicated.

The preferred pattern is:

- a stable target file path
- shared content as the default base
- profile-specific additions or subtractions
- platform-specific adjustments
- host-specific overrides only for true machine-local exceptions

### Source State Principles

The `chezmoi` source state should stay close to target file intent.

Preferred characteristics:

- target files are recognizable from source state structure
- large files are assembled from clear fragments when necessary
- template logic is concentrated in meaningful composition points

Avoid:

- one full tree per platform
- one full tree per profile combination
- giant all-platform templates when smaller composable fragments would be clearer

### Data Model

Use `.chezmoidata` as the canonical template data context rather than embedding
complex logic directly in templates.

The dedicated `.chezmoidata` schema document is the canonical field-level shape. At
this layer, the important constraint is that `.chezmoidata` is layered into:

- `raw`: discovered facts and declared inputs
- `resolved`: normalized template-facing semantics
- `selections`: final config-facing choices and variants

Recommended data categories:

- `raw.environment`: OS family, distro family, shell family, GUI capability, VM/container facts
- `raw.inputs`: requested profiles, overrides, and policy inputs
- `resolved.platform`: normalized platform and execution-context semantics
- `resolved.host`: normalized host role and tags
- `resolved.policy`: effective policy flags such as GUI, AI tooling, system-scope changes, or offline mode
- `selections`: final config sets, variants, and feature flags used directly by templates

Rules:

- auto-discoverable facts should usually be resolved upstream, not re-derived repeatedly in templates
- intent-bearing overrides should be explicit in data
- templates should prefer `resolved` and `selections` over inspecting `raw`
- host data must not become a catch-all substitute for architecture

## Package Strategy

### Package Model

The package layer should use a logical package registry instead of embedding
platform-specific package commands directly into profile definitions.

Recommended split:

- profile package sets: which logical packages a profile requires
- package registry: how each logical package maps to providers on each platform

The dedicated `Package Registry Design` document is the canonical field-level schema.
At this layer, the important design constraint is that the registry separates:

- profile-to-package intent
- logical package identity and selection constraints
- provider mappings
- verification expectations
- fallback and lifecycle rules

### Logical Package Registry

Each logical package is expected to carry, directly or through its canonical schema,
the following concerns:

- stable identity
- category and capability domain
- selection constraints
- provider mappings
- package-level verification
- fallback policy
- lifecycle status

Profile membership is defined by profile package sets, not by duplicating profile
references inside each package record.

Example provider mappings:

- macOS `brew: git`
- Debian `apt: git`
- Fedora `dnf: git`
- Windows `winget: Git.Git`

### Package Categories

Logical packages should be grouped by role, for example:

- `core-cli`
- `developer-cli`
- `runtime`
- `toolchain`
- `editor-terminal`
- `gui-utility`
- `secret-access`
- `ai-tooling`

This keeps profile design centered on capability rather than on raw app lists.

### Channel Priority

Preferred channel order:

1. platform-native package manager
2. language ecosystem distribution channel
3. official release binary or archive
4. manual installation step

Rules:

- moving to a lower-priority channel must be explicit
- exceptions must state why the preferred channel is insufficient
- verification must remain attached to the logical package regardless of installation channel

## `chezmoi` Design Model

### `chezmoi` Positioning

`chezmoi` is the configuration state engine, not the global workflow engine.

It should be used for:

- expressing and applying managed target state
- handling machine, OS, and profile differences in config
- integrating external secret sources when config needs them
- small activation-adjacent scripts when necessary

It should not be used as:

- the primary package installer
- the full orchestration engine
- the only acceptance mechanism

### Template Strategy

Templates are appropriate for:

- small OS or path differences
- profile switches
- host-specific content where the file meaning remains clear
- secret references
- structured config generation for formats such as JSON, TOML, YAML, or INI

Templates are not appropriate for:

- large imperative install flows
- long branching execution logic
- multi-step state machines
- sprawling platform logic that obscures the target file meaning

Guideline:

- if the template is primarily selecting or composing target state, it fits
- if the template is primarily acting like a program, it should move out of `chezmoi`

### File Composition Strategy

Prefer a main target file composed from meaningful fragments when fragmentation adds
clarity.

Good candidates:

- shell config with shared, profile, platform, and host snippets
- SSH config with shared rules plus host or role additions
- AI-related config with a shared skeleton plus optional `ai-enabled` sections

Avoid fragmenting files that do not have stable sub-responsibilities.

### Scripts and Hooks

Scripts and hooks should stay lightweight.

Appropriate uses:

- refresh generated state
- trigger user-scope reload actions
- initialize first-run caches
- prepare small derived artifacts

Inappropriate uses:

- full package installation pipelines
- long orchestrated workflows
- hidden repair mechanisms
- complex state resolution

### Externals

Use externals for configuration-adjacent external artifacts, not for full dependency
management.

Appropriate uses:

- editor resources
- plugin bundles
- pinned third-party static files needed by configuration

Inappropriate uses:

- replacing package management
- pulling large amounts of opaque runtime state
- embedding broad system provisioning behavior

### Secret Handling in `chezmoi`

`chezmoi` should reference secrets, not become the secret store.

Rules:

- templates should pull from supported secret backends or runtime secret sources
- secret-dependent configs should fail or degrade explicitly when secrets are unavailable
- secret access logic should be concentrated rather than spread across many unrelated templates

## Activation Model

`chezmoi apply` success does not mean the target profile is accepted.

Activation exists to make materialized state effective.

### Activation Categories

- `inline activation`: lightweight steps that can happen within or immediately around apply
- `post-apply activation`: explicit follow-up steps after apply
- `manual activation`: user or GUI steps that cannot be fully automated

### Activation Rules

- activation should be short and repeatable
- activation should avoid hidden high-risk side effects
- manual activation requirements must be surfaced clearly
- activation failure should be diagnosable independently from rendering or provisioning failure

## Verification Model

Verification is a separate phase and must remain runnable on its own.

### Verification Levels

- `package-level`: required tools exist and can be invoked
- `config-level`: managed config is present and recognized by the target tool
- `workflow-level`: the profile's main user workflow is actually usable

Profile acceptance should be determined primarily from workflow-level verification,
not only package presence.

### Verification Output

Each check should emit structured output including:

- `capability`
- `status`
- `evidence`
- `message`
- `remediation`
- `scope`

Allowed status values:

- `satisfied`
- `degraded`
- `unsupported`
- `failed`

### Verification Rules

- verification must check observed behavior, not merely completed commands
- manual steps still pending should usually result in `degraded`, not `satisfied`
- unsupported capabilities should be reported as `unsupported`, not `failed`, when the environment genuinely cannot support them
- failed core workflow paths should result in `failed`

## Host Data Model

Host-specific data should be divided into two classes.

### Discovered Host Facts

Examples:

- hostname
- OS and distro
- shell family
- GUI availability
- VM, container, or remote context
- privilege and filesystem limits

### Declared Host Overrides

Examples:

- machine tags
- local role
- enabled extras
- machine-specific proxy or SSH preferences
- whether optional heavy tooling is enabled

Rules:

- discover facts automatically where practical
- use explicit overrides only for intent-bearing exceptions
- do not let host overrides replace profile or platform design

## Secret Strategy

The system should use reference-based secret integration.

Rules:

- secrets are not stored in source control
- secrets are not treated as normal host data
- token, password, and private key material must stay outside ordinary host overrides
- secret-dependent capabilities must define degradation or failure behavior

The design is intentionally secret-backend-agnostic, even though `chezmoi v2.70.2`
supports multiple integrations.

## Drift and Evolution

### Drift Classes

The design recognizes three distinct kinds of drift.

#### Managed Drift

Managed files or managed config no longer match desired state.

Expected response:

- detect with state comparison tools
- repair with normal apply or reconcile flows

#### Environment Drift

The machine facts have changed.

Examples:

- OS upgrade
- package manager change
- GUI availability change
- target path conventions changed

Expected response:

- re-run discovery and resolution before applying state

#### Tooling Drift

Underlying tool behavior changes.

Examples:

- `chezmoi` upgrades
- package source behavior changes
- secret backend changes

Expected response:

- review and, if necessary, update the technical design itself

### Versioning Guidance

The long-term system should track at least:

- spec version
- technical design version
- tool baseline version

This allows the high-level spec to remain stable while the concrete design evolves.

### Migration Principles

- keep profile semantics stable when possible
- allow underlying tools to change if acceptance and security boundaries remain stable
- preserve managed versus unmanaged state boundaries across migrations
- preserve verifier semantics across migrations when possible

## Testing Guidance

Even before implementation, the design assumes four test layers:

- template or render tests
- activation smoke tests
- verification contract tests
- profile acceptance tests on representative environments

The verification system itself must be testable, or it will degrade into untrustworthy
log inspection.

## Anti-Patterns

Avoid the following:

- stuffing package install logic into `chezmoi` templates
- treating `chezmoi` as the full orchestration engine
- allowing host data to become an unstructured junk drawer
- letting hooks become a hidden primary execution path
- duplicating entire config trees for each platform or profile combination
- treating `apply` success as equivalent to accepted environment state
- mixing secrets into normal host override data

## Recommended Next Design Areas

If this design is accepted, the next useful design documents would be:

- package registry schema and profile-package mapping
- `.chezmoidata` schema and resolution contract
- verification contract format and reporter schema
- migration design from the current repository layout into the new model
