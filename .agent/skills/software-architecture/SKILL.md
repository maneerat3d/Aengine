---
name: software-architecture
description: Design or review A-Engine module boundaries, ownership, lifecycle, composition roots, and vertical slices without creating God classes or duplicate state.
---

# Software Architecture

Use for new modules/subsystems, Phase planning, ownership changes, lifecycle design, composition roots, or refactors that cross module boundaries.

## Required sources

Read `AGENTS.md`, `docs/AENGINE_API_ARCHITECTURE.md`, `docs/ARCHITECTURE_SAFETY_BASELINE.md`, `docs/CODE_SHAPE_POLICY.md`, `.agent/code-map/current/AI_CONTEXT.md`, and `INDEX.json`. Load only the relevant `modules/<target>.json`. Read feature-specific contracts when the slice touches UI, APaint migration, renderer, or another governed boundary.

## Workflow

1. State current phase and concrete user outcome.
2. Use the AI code map to locate the declared owner, then verify it against current public headers/CMake/source before proposing a new class or subsystem.
3. Define public contract, implementation owner, dependency direction, state owner, lifetime, threading, mutation gateway, invariants, tests, diagnostics, and stop line.
4. Prefer a vertical slice with one real consumer over broad scaffolding.
5. Use composition for replaceable policies/adapters; keep composition roots to wiring only.
6. Split state ownership, orchestration, policy/strategy, backend adaptation, persistence, and presentation when they have independent reasons to change.
7. Reject duplicate mutable state, global service locators, manager aggregates, circular dependencies, and product policy inside reusable engine owners.
8. Update `MODULE.json` schema v2 when ownership, lifetime, threading, mutation gateway, invariant, dependency, entry point, test, skill routing, or stop line changes.
9. Treat invariant IDs as executable contracts; update semantics and focused tests together rather than weakening a guard.
10. Finish through `build.bat`; generated AI map changes belong in the same slice.

## God-class / safety checks

Stop and redesign when one class owns unrelated subsystem state, mixes orchestration with backend lifetime, becomes the mutation gateway for unrelated domains, requires unrelated systems to unit test it, or creates a second active route to the same mutable state.

A module must also stop if its dependency direction becomes cyclic, a public header has ambiguous ownership, lifecycle/thread affinity cannot be stated precisely, or its stop line is being crossed without a new owner.

Line budgets in `docs/CODE_SHAPE_POLICY.md` are hard stops, not design targets. Split earlier when responsibility becomes unclear.

## Output

Record: outcome, owner/API, dependencies, state/lifetime/threading, mutation gateway, invariant IDs, files, module manifest, focused tests, validation lane, migration/deletion condition, and excluded scopeค่ะ
