# A-Engine Architecture Safety Baseline

Status: **normative for production architecture and AI-generated changes**

Date: 2026-08-11

Purpose: keep A-Engine safe to evolve when the codebase becomes large and multiple AI agents work on it across separate chats or sessions. Repository contracts must carry the important context; chat memory is never the architectural source of truth.

## 1. New-session bootstrap

Every agent starts from repository evidence, not remembered conversation context:

1. read `AGENTS.md`;
2. read `.agent/code-map/current/AI_CONTEXT.md` and `INDEX.json`;
3. load only the relevant `modules/<target>.json`;
4. read the skills routed by that module;
5. verify public contract, focused tests, and implementation owner;
6. use repository-root `build.bat` for validation.

If a previous chat contained an important architectural decision that is not represented by source, canonical docs, `MODULE.json`, tests, or generated AI map, that decision is not durable enough and must be encoded before relying on it.

## 2. Module contract v2

Every production `aengine_*` target under `engine/` or `tools/` must have `MODULE.json` with `schema_version: 2` and these fields:

- `owner`: stable subsystem owner, never a person or `TBD`;
- `responsibility`: one primary reason for the module to change;
- `public_api` and `implementation`: owned paths;
- `tests`: focused proof used by this module;
- `allowed_dependencies` and `forbidden_dependencies`;
- `state_owners`: names of mutable-state owners in this module;
- `lifetime`: scope, creation point, and shutdown point/order;
- `threading`: thread affinity and concurrency rule;
- `mutation_gateway`: canonical route(s) that may mutate owned state, or explicit `none` for stateless/read-only modules;
- `invariants`: stable IDs, statements, and tests proving them;
- `entry_points`: public/consumer-facing entry points;
- `skills`: procedural skills an agent must load for this module;
- `stop_line`: behavior explicitly excluded from the module.

Generated AI maps copy these declarations beside observed CMake/source/public-header facts so a new agent can compare intent with reality without scanning the whole repository.

## 3. Single ownership and mutation

- Every mutable state has exactly one canonical owner.
- A facade delegates to owners; it does not copy their mutable state.
- A composition root wires objects only and owns no domain behavior.
- Mutations enter through the module's declared `mutation_gateway`.
- UI, automation, add-ons, tests, and product shells must use the same canonical mutation route as production consumers.
- A second active state machine or alternate mutation route requires a migration/deletion condition in the same slice.

## 4. Lifecycle and threading

Before implementation, every stateful module must declare creation, usable lifetime, safe shutdown boundary/order, thread affinity, and concurrency rule.

Lifecycle rules are invariants, not comments. Important transitions must have focused tests. Async or backend work must make ownership transfer, cancellation, and shutdown behavior explicit before code is added.

## 5. C++ / OOP policy

A-Engine uses OOP to express ownership, lifetime, encapsulation, and replaceable contracts. It does not use classes or inheritance as the default shape for all code.

- Single Responsibility and Composition are the default.
- RAII is the default resource-ownership model.
- `struct` is preferred for simple value/data contracts without ownership behavior.
- A class owns one coherent state/lifetime responsibility.
- Interfaces exist only for a real backend/testing/policy seam; do not create speculative interfaces.
- Prefer constructor/composition injection over global access.
- Inheritance is for substitutable polymorphic contracts, not code reuse; deep inheritance trees are rejected.
- Multiple inheritance requires explicit architectural justification and should normally be limited to interface contracts.
- Public APIs must make owning vs non-owning lifetime semantics unambiguous.
- Generic singleton/service-locator patterns and broad manager aggregates are forbidden.

Names such as `EngineManager`, `SystemManager`, `GlobalContext`, `ServiceLocator`, `Everything`, `Misc`, `Common`, or unscoped `Utils` are architecture warnings and are rejected as central production owners.

## 6. Dependency safety

- Observed `aengine_*` target dependencies must be declared by the owning module.
- Cycles between production targets are forbidden.
- Lower layers cannot reach upward through a convenience include or hidden implementation link.
- Third-party/backend adapters stay private behind backend-neutral public contracts.
- A dependency change requires updating the owner manifest and generated AI map in the same slice.

## 7. Public API ownership

Every header under `sdk/include/AEngine` must have exactly one owning production module. Orphan public headers and headers claimed by multiple modules are forbidden.

Public API changes must therefore change one explicit owner and regenerate the AI map. This does not replace semantic review, but it prevents an agent from silently adding cross-module public surface.

## 8. Invariants as executable safety rails

Each module defines stable invariant IDs such as `APP-001`. Every invariant names at least one focused CTest that proves it.

Tests must prove behavior at the owner boundary, not implementation trivia. Do not weaken an invariant or its test to make a change pass; change the contract explicitly when the intended semantics truly change.

## 9. Change-scope discipline

Before editing production code, the agent states target module(s), expected paths, affected invariants/tests, dependency changes, and stop line.

Unexpected edits outside that scope are a review signal. Changes that span foundation plus two or more upper modules must be split when independent checkpoints are possible.

## 10. Completion gate

A slice is complete only when:

- module contract v2 is valid;
- dependency graph is acyclic;
- public API ownership is unique and complete;
- OOP anti-pattern guard passes;
- source-shape and existing architecture guards pass;
- AI code map has no drift;
- focused behavior tests pass;
- final repository-root `build.bat` passes Debug and Release.

The baseline is designed to make a new chat reconstruct the current architecture from `main` without relying on hidden conversational historyค่ะ
