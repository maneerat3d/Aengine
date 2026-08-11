---
name: ui-architecture
description: Design A-Engine High-level UI/editor infrastructure and Dear ImGui backend boundaries without leaking backend handles or product state.
---

# UI Architecture

Use for UI host lifecycle, panel/menu/shortcut infrastructure, viewport widgets, High-level UI API, Dear ImGui backend, or APaint UI migration.

## Required sources

Read `docs/AENGINE_UI_ARCHITECTURE.md`, `docs/AENGINE_API_ARCHITECTURE.md`, `docs/AENGINE_APAINT_BOUNDARY.md` when APaint is involved, and `docs/CODE_SHAPE_POLICY.md`.

## Ownership

- A-Engine owns reusable High-level UI API, UI host lifecycle, editor infrastructure, and canonical Dear ImGui backend implementation.
- Product applications own panel/dialog/workspace content, view models/controllers, defaults, theme values, and presentation policy.
- Dear ImGui types and renderer resources remain private to the backend.

## Rules

- Prefer semantic High-level UI operations; add limited immediate primitives only for proven consumers.
- Do not build a 1:1 wrapper around all ImGui functions.
- UI reads immutable snapshots and emits user intent to canonical commands/workflows; it does not mutate domain/GPU owners directly.
- Menu, shortcut, automation, and panel actions must converge on the same command/workflow route.
- Separate UI composition, state/view model, command dispatch, backend rendering, and product presentation when they have different lifetimes or reasons to change.
- Temporary direct-ImGui routes require caller inventory, parity proof, diagnostics, and deletion condition.

## Validation

Test semantic UI contracts/headless intent where possible, backend lifecycle separately, and product visual/interaction behavior only where human QA is required.
