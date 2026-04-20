# `.chezmoidata` Schema Design

## Overview

This document defines the recommended schema for `.chezmoidata` in the
cross-platform bootstrap design.

The design assumes `.chezmoidata` serves as the primary data context consumed by
`chezmoi` templates. It intentionally carries both:

- raw inputs and discovered facts
- resolved outputs and final config-facing selections

The goal is to keep templates simple without losing traceability or environment
context.

This document is design-only. It does not define implementation code, migration, or
runtime execution flow.

## Tool Baseline

This design assumes `chezmoi v2.70.2` and relies on its support for:

- `.chezmoidata.<format>` special files
- data consumption from templates
- template rendering using structured data

The design described here targets a canonical `.chezmoidata.yaml` file.

## Boundary With Other Subsystems

### `.chezmoidata` Is Responsible For

- carrying template-consumable environment context
- preserving relevant raw inputs and discovered facts
- exposing resolved, normalized semantics for template use
- exposing final config selection outputs for direct template branching
- providing a shared, explainable context surface across templates

### `.chezmoidata` Is Not Responsible For

- serving as the package registry
- storing secret plaintext
- acting as a verification report
- acting as an execution log or runtime cache dump
- replacing activation state or workflow orchestration
- holding arbitrary host-specific configuration content without schema meaning

### Relationship to Other Subsystems

- the package registry defines package intent and provider mappings
- `.chezmoidata` defines environment and config context for `chezmoi`
- provisioning installs packages
- `chezmoi` renders and materializes configuration using `.chezmoidata`
- verification evaluates the resulting environment at package, config, and workflow levels

## Design Goals

- Keep template inputs explicit and stable.
- Preserve both traceability and template simplicity.
- Prevent templates from re-implementing environment resolution.
- Support both human debugging and Agent consumption.
- Make final config choices visible as data, not just as scattered template logic.

## Canonical File Model

The canonical authoring format should be a single YAML file:

- `.chezmoidata.yaml`

Rationale:

- one canonical data context is easiest for template authors and Agents to reason about
- YAML is suitable for nested records and reviewable by humans
- a single file reduces ambiguity around merge order and source precedence

This design does not forbid future decomposition into `.chezmoidata/`, but the
canonical design target remains a single file.

## Canonical Top-Level Structure

The canonical file should contain exactly these top-level keys, in this order:

1. `metadata`
2. `raw`
3. `resolved`
4. `selections`
5. `notes`

Unknown top-level keys should be treated as schema errors.

### Top-Level Intent

- `metadata`: file identity and schema compatibility
- `raw`: discovered facts and declared inputs
- `resolved`: normalized semantics for template consumption
- `selections`: final config-facing choices and variants
- `notes`: optional human-facing explanatory notes

## Data Layer Model

The schema uses a strict layered model.

### `raw`

`raw` contains:

- discovered environment facts
- declared external inputs
- inventory-sourced context
- source attribution for those values

`raw` should answer: what was observed or provided?

### `resolved`

`resolved` contains:

- normalized platform semantics
- final effective profiles
- final effective policy
- normalized host semantics
- config-relevant capability summaries

`resolved` should answer: how does the system interpret this environment?

### `selections`

`selections` contains:

- final config set decisions
- chosen variants
- feature flags
- configuration-facing package group summaries

`selections` should answer: what config branches should templates actually use?

## `metadata` Section

The `metadata` section defines the data document itself.

Recommended fields:

- `schema_id`
- `schema_version`
- `data_name`
- `description`
- `producer`
- `generated_at`
- `compatibility_notes`

Purpose:

- identify the data contract
- support parser and template compatibility checks
- distinguish source-of-truth schema from incidental data shape

## `raw` Section

The `raw` section should contain four major groups:

1. `environment`
2. `inputs`
3. `inventory`
4. `sources`

### `raw.environment`

This group stores directly observed environment facts.

Recommended subgroups:

- `host`
- `os`
- `shell`
- `paths`
- `runtime`
- `network`
- `session`

Representative fields:

- hostname
- OS family and version as observed
- distro identifier
- shell family and executable
- home/config/state/cache paths
- GUI availability
- VM/container/remote/CI flags
- privilege facts
- network availability

Rules:

- store observations, not conclusions
- preserve raw values when they differ from normalized labels

### `raw.inputs`

This group stores explicit requested inputs.

Representative fields:

- requested profiles
- capability overrides
- policy flags
- host role request
- machine tag overrides
- operator-specified choices

Rules:

- this section records what was requested, not what was finally accepted
- values should stay close to user or upstream intent

### `raw.inventory`

This group stores external inventory or repository-sourced context.

Representative fields:

- host aliases
- machine class
- LAN or site role
- org policy labels
- approved or disallowed tool hints

Rules:

- inventory data is neither autodetected fact nor final resolved meaning
- inventory fields should remain descriptive, not imperative

### `raw.sources`

This group explains where data came from.

Representative source types:

- `autodetect`
- `env-var`
- `inventory`
- `cli-flag`
- `operator-input`
- `default`

Purpose:

- support explainability
- support debugging when raw and resolved values differ

## `resolved` Section

The `resolved` section should contain normalized, template-facing semantics.

Recommended groups:

1. `platform`
2. `paths`
3. `profiles`
4. `policy`
5. `host`
6. `capabilities`

### `resolved.platform`

This group defines normalized platform semantics.

Representative fields:

- platform family
- distro family
- shell target
- execution context class
- GUI class
- containment class
- persistence class

Examples of normalized values:

- `macos`
- `linux`
- `windows`
- `debian`
- `fedora`
- `local-host`
- `remote-host`
- `ci`
- `interactive-gui`
- `headless-interactive`

This normalized platform layer is also the canonical input used by selector-driven
systems such as the package registry resolver.

Recommended projection rules:

- `resolved.platform.family=macos` satisfies selector `macos`
- `resolved.platform.family=linux` satisfies selector `linux`
- `resolved.platform.family=windows` satisfies selector `windows`
- `resolved.platform.distro_family=debian` satisfies selector `linux.debian`
- `resolved.platform.distro_family=fedora` satisfies selector `linux.fedora`
- `resolved.platform.distro_family=rhel` satisfies selector `linux.rhel`
- `resolved.platform.distro_family=opensuse` satisfies selector `linux.opensuse`
- `resolved.platform.distro_family=alpine` satisfies selector `linux.alpine`
- `resolved.platform.distro_family=arch` satisfies selector `linux.arch`
- `resolved.platform.containment_class=container` satisfies selector `container`
- `resolved.platform.execution_context=remote-host` satisfies selector `remote-host`
- `resolved.platform.execution_context=ci` satisfies selector `ci`
- `resolved.platform.gui_class=interactive-gui` satisfies selectors `interactive` and `gui`
- `resolved.platform.gui_class=headless-interactive` satisfies selector `interactive` but not `gui`

These projection rules exist so selectors are derived from normalized semantics, not
from scattered raw-field inspection.

### `resolved.paths`

This group defines stable path semantics that templates may consume directly.

Representative fields:

- home path
- config root
- state root
- cache root
- shell config target
- platform-specific app config roots

Rules:

- paths here should already be normalized for template use
- templates should prefer these values over recomputing path conventions

### `resolved.profiles`

This group defines final profile interpretation.

Recommended fields:

- `requested`
- `enabled`
- `inherited`
- `rejected`
- `reasons`

Rules:

- `requested` may mirror `raw.inputs.requested_profiles`
- `enabled` must represent final effective profiles
- `rejected` must be explicit when requests cannot be honored

### `resolved.policy`

This group defines effective policy after combining raw input, environment facts, and
global rules.

Representative fields:

- `allow_gui_config`
- `allow_ai_config`
- `allow_system_scope_config`
- `offline_mode_effective`
- `manual_steps_allowed`

Rules:

- these are effective values, not raw requested values
- templates should prefer these over raw policy flags

### `resolved.host`

This group defines normalized host semantics used by templates.

Representative fields:

- normalized hostname
- host role
- host tags
- machine class
- local environment class

Rules:

- this section should stay semantically meaningful
- avoid filling it with every raw host detail

### `resolved.capabilities`

This group defines config-relevant capability summaries.

Representative fields:

- has GUI config path
- has remote access layer
- has secret backend path
- has AI tooling layer enabled
- has local shell config support

Rules:

- capabilities here summarize config-relevant meaning
- they are not verification results and should not pretend to be runtime success

## `selections` Section

The `selections` section defines final config-facing choices.

Recommended groups:

1. `config_sets`
2. `variants`
3. `feature_flags`
4. `package_groups`

### `selections.config_sets`

This group identifies which configuration layers should be included.

Representative values:

- shared base config set
- developer config set
- remote-access config set
- ai-enabled config set
- platform-specific config set
- host-specific overlay set

### `selections.variants`

This group names the selected config variants.

Representative fields:

- `shell_variant`
- `terminal_variant`
- `editor_variant`
- `proxy_variant`
- `input_method_variant`

Rules:

- variants should use stable semantic names
- variant names should describe config choice, not implementation action

### `selections.feature_flags`

This group contains final template-facing boolean switches.

Representative fields:

- `enable_gui_config`
- `enable_ai_config`
- `enable_remote_host_aliases`
- `enable_secret_helper_integration`
- `enable_machine_local_extras`

Rules:

- flags should be used only when many templates benefit from the same decision
- flags should not duplicate raw observations without added meaning

### `selections.package_groups`

This group provides configuration-relevant package group summaries.

Representative fields:

- `has_editor_toolchain_group`
- `has_ai_tooling_group`
- `has_secret_access_group`
- `has_gui_terminal_group`
- `has_runtime_or_toolchain_group`

Rules:

- this group summarizes selection outcomes relevant to config
- it must not become a duplicate of the package registry

## Template Consumption Rules

Templates should follow a strict consumption order.

Recommended rule set:

1. prefer `selections` for final branching
2. prefer `resolved` for normalized semantic context
3. read `raw` only when a field is explicitly declared template-visible
4. ignore `notes` in templates

Rationale:

- avoids repeated reasoning inside templates
- keeps template logic stable and reviewable
- preserves raw data for debugging without making it the default template API

## Representative Example Shapes

The following samples are schema examples, not full implementation files.

### Example A: Local macOS Developer With AI Tooling

```yaml
metadata:
  schema_id: opencode.chezmoidata
  schema_version: 1
  data_name: local-macos-dev

raw:
  environment:
    host:
      hostname: macbook-pro
    os:
      family: Darwin
      version: "15"
    shell:
      family: zsh
    session:
      gui_available: true
      container: false
      remote: false
  inputs:
    requested_profiles: [base, developer, ai-enabled]
    policy_flags:
      allow_ai: true
  inventory:
    machine_class: laptop
    site_role: personal-primary
  sources:
    requested_profiles: operator-input
    machine_class: inventory

resolved:
  platform:
    family: macos
    gui_class: interactive-gui
    execution_context: local-host
  paths:
    config_root: /Users/example/.config
  profiles:
    requested: [base, developer, ai-enabled]
    enabled: [base, developer, ai-enabled]
    inherited: [base]
    rejected: []
  policy:
    allow_gui_config: true
    allow_ai_config: true
    manual_steps_allowed: true
  host:
    role: personal-primary
    machine_class: laptop
  capabilities:
    has_gui_config_path: true
    has_ai_tooling_layer_enabled: true

selections:
  config_sets: [shared-base, developer, macos-gui, ai-enabled]
  variants:
    shell_variant: zsh
    terminal_variant: wezterm
    editor_variant: neovim
  feature_flags:
    enable_gui_config: true
    enable_ai_config: true
  package_groups:
    has_editor_toolchain_group: true
    has_ai_tooling_group: true
```

### Example B: Fedora Remote Headless Host

```yaml
raw:
  environment:
    os:
      family: Linux
      distro: fedora
    session:
      gui_available: false
      remote: true
      container: false
  inputs:
    requested_profiles: [base, developer, remote-access]

resolved:
  platform:
    family: linux
    distro_family: fedora
    gui_class: headless-interactive
    execution_context: remote-host
  profiles:
    enabled: [base, developer, remote-access]
  policy:
    allow_gui_config: false
  capabilities:
    has_gui_config_path: false
    has_remote_access_layer: true

selections:
  config_sets: [shared-base, developer, remote-access, linux-headless]
  variants:
    terminal_variant: headless-none
    editor_variant: neovim
  feature_flags:
    enable_gui_config: false
    enable_remote_host_aliases: true
```

### Example C: Windows Interactive Developer Without AI Layer

```yaml
raw:
  environment:
    os:
      family: Windows_NT
    shell:
      family: pwsh
    session:
      gui_available: true
  inputs:
    requested_profiles: [base, developer]
    policy_flags:
      allow_ai: false

resolved:
  platform:
    family: windows
    gui_class: interactive-gui
  profiles:
    enabled: [base, developer]
  policy:
    allow_ai_config: false
  host:
    role: workstation

selections:
  config_sets: [shared-base, developer, windows-gui]
  variants:
    shell_variant: pwsh
    terminal_variant: wezterm
  feature_flags:
    enable_ai_config: false
```

## Schema Constraints

### Top-Level Constraints

- only `metadata`, `raw`, `resolved`, `selections`, and `notes` are allowed
- `raw`, `resolved`, and `selections` must be maps
- `notes` is optional and must not replace structured fields

### `raw` Constraints

- `raw` must not contain derived config-facing booleans that belong in `resolved` or `selections`
- `raw.inputs` must represent requested intent, not final accepted state
- `raw.sources` must not conflict with the actual presence of fields it describes

### `resolved` Constraints

- `resolved` must contain only normalized semantics or effective values
- `resolved.profiles.enabled` must represent final effective profile state
- `resolved.policy` must not merely duplicate raw policy input without interpretation
- `resolved.capabilities` must not claim runtime verification success

### `selections` Constraints

- `selections` must be derivable from `resolved`
- `selections` must not invent untraceable facts
- `selections.feature_flags` should remain config-facing and stable
- `selections.package_groups` must not duplicate the full package registry

### Cross-Layer Constraints

- if `resolved.profiles.enabled` differs from `raw.inputs.requested_profiles`, the difference should be explainable
- if `resolved.policy` differs from raw policy input, the effective value should be intentional and traceable
- template-visible branching should be expressible without depending on deep raw inspection

## Anti-Patterns

Avoid the following:

- making templates depend primarily on `raw`
- mixing raw facts and final config choices in the same field group
- storing secret plaintext in any section
- turning `resolved.capabilities` into a fake verification report
- letting `selections` become a global junk drawer of template conveniences
- using `notes` as a substitute for structured schema fields

## Recommended Next Design Areas

The next most natural design documents after this one are:

- verification contract format and reporter schema
- profile catalog semantic design
- activation contract design
- template visibility rules for `raw` fields that are allowed as exceptions
