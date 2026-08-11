---
name: software-architecture
description: Design or review A-Engine module boundaries, ownership, lifecycle, composition roots, and vertical slices without creating God classes or duplicate state.
---

# Software Architecture

Use for new modules/subsystems, Phase planning, ownership changes, lifecycle design, composition roots, or refactors that cross module boundaries.

## Required sources

Read `AGENTS.md`, `docs/AENGINE_API_ARCHITECTURE.md`, and `docs/CODE_SHAPE_POLICY.md`. Read feature-specific contracts when the slice touches UI, APaint migration, renderer, or another governed boundary.

## Workflow

1. State current phase and concrete user outcome.
2. Identify the existing source-of-truth owner before proposing a new class or subsystem.
3. Define public contract, implementation owner, dependency direction, lifetime/state owner, invariants, tests, diagnostics, and stop line.
4. Prefer a vertical slice with one real consumer over broad scaffolding.
5. Use composition for replaceable policies/adapters; keep composition roots to wiring only.
6. Split state ownership, orchestration, policy/strategy, backend adaptation, persistence, and presentation when they have independent reasons to change.
7. Reject duplicate mutable state, global service locators, manager aggregates, circular dependencies, and product policy inside reusable engine owners.
8. Review the diff for deletion/migration conditions and dead parallel routes.

## God-class checks

Stop and redesign when one class owns unrelated subsystem state, mixes orchestration with backend lifetime, becomes the mutation gateway for unrelated domains, or requires unrelated systems to unit test it.

Line budgets in `docs/CODE_SHAPE_POLICY.md` are hard stops, not design targets. Split earlier when responsibility becomes unclear.

## Output

For architecture work, record: outcome, owner/API, dependencies, lifetime, invariants, files, focused tests, validation lane, migration/deletion condition, and excluded scope.
