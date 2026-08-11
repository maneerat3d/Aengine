---
name: cpp-oop-design
description: Design and review A-Engine C++ classes, ownership, RAII, composition, dependency injection, interfaces, and inheritance without creating manager aggregates or duplicate state.
---

# C++ OOP Design

Use whenever adding or changing a class, service, state owner, resource owner, interface, policy object, composition root, or inheritance relationship.

## Required sources

Read `AGENTS.md`, `docs/ARCHITECTURE_SAFETY_BASELINE.md`, `docs/CODE_SHAPE_POLICY.md`, the relevant module map, and `cpp-api-contracts` when public SDK types are touched.

## Rules

- OOP expresses ownership, lifetime, encapsulation, and real polymorphic seams; it is not a requirement to make every concept a class.
- Prefer `struct` for simple immutable/value contracts and `class` for behavior with protected invariants or owned lifetime.
- Single Responsibility and Composition are the default.
- Use RAII for resources and make ownership transfer explicit.
- Keep one canonical mutable-state owner; facades and adapters delegate instead of mirroring state.
- Inject dependencies through constructors/composition or narrow bundles; never add global singleton or service-locator access.
- Interfaces require a real backend, testing, policy, or add-on seam. Do not add speculative `I*` abstractions with one implementation and no seam.
- Inheritance is for substitutable polymorphism, not implementation reuse. Keep trees shallow and prefer Strategy/Policy composition.
- Multiple inheritance needs explicit architectural justification and should normally be interface-only.
- Composition roots wire objects only; domain behavior belongs to focused owners.
- Avoid broad `Manager`, `GlobalContext`, generic `Utils`, `Common`, `Misc`, or similar dumping-ground owners.

## Before adding a class

Identify its owner module, responsibility, mutable state, lifetime, thread affinity, dependencies, mutation gateway, invariants, focused tests, and stop line. If two independent reasons to change appear, split before implementation.

## Review stop conditions

Stop and redesign if a class owns unrelated state, mixes orchestration with backend resource lifetime, needs unrelated systems to unit test, becomes a cross-domain mutation gateway, duplicates another owner's state, or grows an inheritance relationship only to share code.

## Completion

Update `MODULE.json` when ownership/lifetime/threading/invariants/mutation gateway or stop line changes. Finish through `build.bat`; do not report completion while OOP/module-safety guards or focused tests failค่ะ
