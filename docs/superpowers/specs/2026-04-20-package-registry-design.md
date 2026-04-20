# Package Registry Design

## Overview

This document defines the `package registry` subsystem for the cross-platform
bootstrap design.

The package registry is a single canonical, machine-oriented catalog that expresses:

- logical packages
- profile-to-package selection intent
- platform-specific provider mappings
- package-level verification expectations
- fallback rules and lifecycle status

This document is design-only. It does not define implementation code, migration, or
execution workflows.

## Boundary With Other Subsystems

### The Package Registry Is Responsible For

- defining stable logical package IDs
- defining how profiles reference logical packages
- defining provider mappings for supported platforms and environments
- defining package-level verification metadata
- defining fallback policy and package lifecycle state
- acting as a machine-readable input to resolver and provisioning implementations

### The Package Registry Is Not Responsible For

- executing installation commands
- mutating environment state directly
- rendering configuration files
- managing host-specific config content
- running activation or manual setup workflows
- deciding final profile acceptance at workflow level

### Provisioning Layer Responsibilities

The provisioning layer consumes the registry and is responsible for:

- selecting the appropriate provider for the current environment
- executing actual installation commands
- handling install failures and fallback decisions
- producing observable installation results

### `chezmoi` Responsibilities

`chezmoi` remains responsible for:

- managing configuration state
- rendering shared, profile, platform, and host-aware templates
- materializing target files and directories
- performing lightweight activation-adjacent actions

`chezmoi` is not the package registry and should not become the primary package
selection or installation engine.

## Design Goals

- Provide one canonical source of truth for package intent across platforms.
- Make the data model straightforward for Agents and programs to parse.
- Keep package semantics stable even when platform providers differ.
- Separate package intent from package execution.
- Support explicit fallback behavior and explicit unsupported states.
- Stay close to a catalog that can later be populated directly.

## Canonical File Model

The registry should be authored as a single canonical YAML file.

Recommended future location:

- `registry/package-registry.yaml`

Design rationale:

- YAML is suitable for nested maps and deep records.
- The file should remain machine-first but still reviewable by humans.
- A normalized JSON view may exist later for machine tooling, but YAML remains the source of truth.

## Canonical Top-Level Structure

The canonical file should contain exactly these top-level keys, in this order:

1. `metadata`
2. `rules`
3. `channels`
4. `profiles`
5. `packages`
6. `examples`

Top-level rationale:

- `metadata` identifies the file and schema contract.
- `rules` defines global resolution behavior.
- `channels` defines distribution channel semantics.
- `profiles` defines package selection intent.
- `packages` defines the logical package catalog.
- `examples` provides schema validation examples for humans and tooling.

Unknown top-level keys should be treated as schema errors.

## Authoring Style

### Map-First Structure

Top-level registry entities should use maps, not arrays, for their primary records.

Preferred examples:

- `profiles.base`
- `profiles.developer`
- `packages.git`
- `packages.neovim`

Rationale:

- stable lookup by key
- easy uniqueness checks
- clearer references across sections
- less dependence on record ordering

### Naming Rules

- top-level keys use `kebab-case` where needed
- package IDs use stable logical capability names
- profile IDs use stable semantic names
- channel IDs use a fixed controlled vocabulary

Recommended package IDs:

- `git`
- `openssh-client`
- `nodejs-runtime`
- `neovim`
- `wezterm`
- `bitwarden-cli`

Avoid IDs that encode provider or platform strategy, for example:

- `brew-git`
- `windows-git`
- `apt-neovim`

## `metadata` Section

The `metadata` section should define the registry document itself.

Recommended fields:

- `schema_id`
- `schema_version`
- `registry_name`
- `description`
- `owners`
- `compatibility_notes`

Purpose:

- identify the data contract
- support parser compatibility checks
- make document ownership explicit

This metadata is for schema compatibility, not for a separate annual document version
system.

## `channels` Section

The `channels` section defines the allowed distribution channel types and their global
semantics.

Recommended canonical channels:

- `native`
- `language-ecosystem`
- `release-binary`
- `manual`

Each channel record should define:

- `id`
- `description`
- `priority`
- `allowed_for`
- `disallowed_for`
- `verification_expectation`

Recommended priority order:

1. `native`
2. `language-ecosystem`
3. `release-binary`
4. `manual`

Rules:

- lower-priority channels should only be selected when higher-priority channels are unavailable or unsuitable
- `manual` is never a silent fallback
- channel semantics are global and should not be redefined per package

## `rules` Section

The `rules` section defines global resolution behavior that should not be duplicated
inside package records.

Recommended rule groups:

- `provider_selection`
- `environment_gating`
- `fallback_policy`
- `verification_policy`
- `lifecycle_policy`
- `conflict_policy`

### `provider_selection`

This rule group defines how a resolver chooses a provider.

Recommended order:

1. filter by supported and unsupported selectors
2. filter by environment and policy constraints
3. sort by selector specificity
4. sort by channel priority
5. apply package-level preference when still relevant
6. fail with ambiguity if multiple equally valid choices remain

Selector evaluation should consume a normalized environment context rather than raw
template data. The canonical source for that normalized context is the `resolved`
layer of `.chezmoidata`, especially:

- `resolved.platform.family`
- `resolved.platform.distro_family`
- `resolved.platform.execution_context`
- `resolved.platform.gui_class`
- `resolved.policy`

The dedicated `.chezmoidata` schema document defines these normalized fields.

### `environment_gating`

This rule group defines how environment type affects package eligibility.

Representative global rules:

- GUI-only packages should not enter headless targets
- interactive-only packages should not enter CI-like targets
- host-only packages should not enter containers unless explicitly allowed
- manual channels should be rejected in fully automated execution contexts unless explicitly permitted

### `fallback_policy`

This rule group defines when fallback is allowed.

Representative rules:

- fallback may occur only when the preferred provider is missing, unsupported, or disallowed by policy
- fallback must respect the package's own fallback policy
- fallback must not silently change the logical capability semantics

### `verification_policy`

This rule group defines registry-wide validation requirements.

Representative rules:

- every active package must define verification
- manual-channel packages still require verification metadata
- packages without verification cannot be referenced as required profile packages

### `lifecycle_policy`

This rule group defines how package lifecycle state affects selection.

Representative rules:

- `active` packages may be selected normally
- `experimental` packages require explicit acceptance if referenced as required
- `deprecated` packages should not be newly introduced into required profile sets
- `disabled` packages do not participate in normal resolution

### `conflict_policy`

This rule group defines how conflicts are handled.

Representative rules:

- conflicting packages should not be auto-resolved silently by default
- package conflicts should produce explicit resolver output
- capability-equivalent packages may only auto-resolve if a clear global rule exists

## `profiles` Section

The `profiles` section defines package selection intent, not package definitions.

Each profile record should contain:

- `id`
- `display_name`
- `summary`
- `extends`
- `package_sets`
- `constraints`
- `acceptance_hints`

### Profile Composition Rules

- profiles express desired capability sets, not install commands
- `extends` must form a DAG and must not contain cycles
- child profiles inherit parent intent and may extend it
- host overrides should not redefine the core meaning of a profile

### `package_sets`

Each profile should separate package references into:

- `required`
- `optional`
- `conditional`

Rationale:

- required packages define the default package baseline for the profile
- optional packages define known enhancements that are not mandatory
- conditional packages express structured environment- or policy-driven inclusion

### Conditional Entry Shape

Conditional entries should be structured records, not free text.

Recommended fields:

- `package`
- `when`
- `reason`

The `when` clause should reference structured selectors or policy inputs, not prose.

### Profile Capability Coverage

Some profiles require capability coverage beyond “all referenced packages exist”.
The profile schema should therefore support capability-level expectations in
`acceptance_hints`.

Representative examples:

- `developer` should require at least one satisfied package from `editor-terminal`
- `developer` should require at least one satisfied package from `runtime` or `toolchain`
- `remote-access` should require at least one satisfied package path supporting remote access entry

These expectations do not replace the higher-level verification contract, but they do
prevent profiles from being structurally valid while obviously under-specified.

### Profile Constraints

Profile constraints may express conditions such as:

- interactive-only
- GUI-preferred
- not suitable for minimal containers

These constraints guide resolution and verification but do not replace package-level
constraints.

## `packages` Section

The `packages` section is the core catalog.

Each package should appear as a map entry keyed by stable package ID.

Example form:

- `packages.git`
- `packages.openssh-client`
- `packages.neovim`

Each package record should be divided into the following logical groups:

- `identity`
- `selection`
- `providers`
- `verification`
- `fallback`
- `lifecycle`

### `identity`

Recommended fields:

- `id`
- `display_name`
- `summary`
- `category`
- `capability_domain`

Recommended category vocabulary:

- `core-cli`
- `developer-cli`
- `runtime`
- `toolchain`
- `editor-terminal`
- `gui-utility`
- `secret-access`
- `ai-tooling`

The category and capability domain should come from controlled vocabularies.

Recommended `capability_domain` vocabulary, aligned to the higher-level system spec:

- `Base System Readiness`
- `Package and Binary Provisioning`
- `Config Materialization`
- `Shell and Command UX`
- `Editor and Terminal Readiness`
- `Identity, Credentials, and Secret Access`
- `Remote and Cross-Host Access`
- `Language and Input Productivity`
- `AI and Automation Tooling`
- `Validation and Drift Detection`
- `Recovery and Re-Bootstrap`

Only a subset of these domains will normally appear in package records. The package
registry primarily uses domains that are package-addressable, such as provisioning,
editor/terminal readiness, identity/secret access, remote access, language/input
productivity, and AI tooling.

### `selection`

The selection group defines when a logical package is considered applicable.

Recommended fields:

- `default_scope`
- `supported_on`
- `unsupported_on`
- `constraints`

Representative selection constraints:

- requires GUI
- requires network
- requires interactive session
- requires secret backend
- requires elevated privilege

The registry should represent explicit unsupported states rather than forcing
resolvers to infer them from missing providers.

### `providers`

The providers group defines how the logical package is realized on different targets.

Recommended structure:

- `default`
- `by_selector`

Each provider entry should define at least:

- `channel`
- `manager`
- `package`
- `variant`
- `notes`

`variant` and `notes` are optional.

Provider selectors should use a controlled selector vocabulary rather than arbitrary
strings.

### Selector Vocabulary

Recommended canonical selectors:

- `macos`
- `linux`
- `linux.arch`
- `linux.debian`
- `linux.fedora`
- `linux.opensuse`
- `linux.rhel`
- `linux.alpine`
- `windows`
- `container`
- `remote-host`
- `ci`
- `interactive`
- `gui`

The selector vocabulary is intentionally open to extension through explicit schema
updates when new supported target classes are added. What is forbidden is ad hoc,
unregistered selector invention inside package records.

Rules:

- more specific selectors override more general selectors
- unregistered selectors should be schema errors
- selector semantics are defined globally, not per package

### `verification`

The verification group defines how a package is judged minimally usable.

Recommended fields:

- `primary_check`
- `command`
- `success_signal`
- `scope`
- `failure_class`

Representative verification modes:

- command exists
- version command succeeds
- binary launches non-interactively
- executable is present in the expected context

Package verification should validate minimal usability, not full workflow acceptance.

### `fallback`

The fallback group defines what may happen when the preferred provider is not usable.

Recommended fields:

- `policy`
- `alternatives`
- `fallback_reason_required`

Recommended policy vocabulary:

- `none`
- `allow-listed`
- `manual-only`

Fallback exists to preserve capability under controlled conditions, not to excuse
silent channel drift.

### `lifecycle`

The lifecycle group defines catalog status.

Recommended fields:

- `status`
- `review_notes`
- `replacement`

Recommended lifecycle vocabulary:

- `active`
- `deprecated`
- `experimental`
- `disabled`

## Representative Example Packages

The design should include a small example set to prove the schema can express common
cases.

Recommended example package types:

- `git` as a universal `core-cli`
- `openssh-client` as a cross-platform capability with uneven provider shapes
- `neovim` as a `developer` editor-terminal tool
- `wezterm` as a GUI-constrained terminal package
- `opencode` as an `ai-tooling` example
- optionally `bitwarden-cli` as a `secret-access` example

These examples are schema validation aids. They should not be treated as the initial
production catalog by default.

## Schema Constraints

### Top-Level Constraints

- only the defined top-level keys are allowed
- `profiles`, `packages`, and `channels` must be non-empty maps
- unknown top-level keys are schema errors

### Reference Constraints

- every package ID referenced by a profile must exist in `packages`
- every channel referenced by a provider must exist in `channels`
- every replacement package ID must exist in `packages` if specified
- every conditional package reference must resolve to an existing package

### Package Constraints

- every active package must define at least one valid provider
- every active package must define verification
- `supported_on` and `unsupported_on` must not conflict
- `fallback.policy=none` must not define alternatives
- deprecated packages should provide a replacement or an explicit justification
- disabled packages do not participate in normal resolution

### Profile Constraints

- a package must not appear in both `required` and `optional` for the same profile
- conditional entries must define structured `when` clauses
- profile inheritance must not contain cycles
- required packages must be verifiable
- profiles with declared capability coverage expectations must reference packages that can satisfy those expectations on at least one supported target

### Provider Constraints

- every provider must define `channel`
- non-manual providers should define both `manager` and `package`
- manual providers must still preserve a verification path
- selector precedence must not create contradictory effective definitions

## Data Flow Role

The registry participates in the larger system as follows:

1. profiles define package intent
2. package records define logical package meaning and provider options
3. rules and channels define global resolver behavior
4. resolver selects the applicable logical packages and concrete providers
5. provisioning executes installation
6. `chezmoi` materializes configuration
7. verification checks package, config, and workflow success

This makes the registry a core input to `resolve` and `provision`, but not the
execution engine itself.

## Capability Mapping Guidance

The package registry should align its `capability_domain` values with the system-wide
capability domains and with config-facing summaries used elsewhere.

Recommended mapping principles:

- `capability_domain` is the canonical package-level semantic label
- profile capability coverage rules should reference package categories and/or capability domains, not provider names
- `.chezmoidata.selections.package_groups` should summarize package-selection outcomes using stable group names derived from these domains and categories

Representative summary mappings:

- `Editor and Terminal Readiness` + category `editor-terminal` -> `has_editor_toolchain_group`
- `AI and Automation Tooling` + category `ai-tooling` -> `has_ai_tooling_group`
- `Identity, Credentials, and Secret Access` + category `secret-access` -> `has_secret_access_group`
- `Editor and Terminal Readiness` + category `gui-utility` or `editor-terminal` with GUI constraints -> `has_gui_terminal_group`
- category `runtime` or `toolchain` -> `has_runtime_or_toolchain_group`

These mappings are summaries for config branching and must not replace the canonical
package records or the higher-level verification contract.

## Anti-Patterns

Avoid the following:

- embedding install commands directly into profile definitions
- encoding package IDs with provider or platform names
- using missing providers as the only way to express unsupported environments
- turning `profiles` into a duplicated package catalog
- treating package verification as equivalent to full workflow readiness
- allowing free-form selectors to proliferate
- using manual fallback as a silent default path

## Recommended Next Design Areas

The next most natural design documents after this one are:

- `.chezmoidata` schema and resolution contract
- verification contract format and reporter schema
- profile catalog semantic design
- activation contract design
