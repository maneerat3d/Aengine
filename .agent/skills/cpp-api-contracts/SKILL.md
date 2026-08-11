---
name: cpp-api-contracts
description: Design and review A-Engine public C++ contracts, handles, Result/Error paths, ABI-safe values, service interfaces, and header dependencies.
---

# C++ API Contracts

Use whenever editing `sdk/include/AEngine`, adding a service interface, changing handles/errors/results, or creating a boundary that may later be exposed through C ABI/C#.

## Required sources

Read `AGENTS.md`, sections 6-9 of `docs/AENGINE_API_ARCHITECTURE.md`, and `docs/CODE_SHAPE_POLICY.md`.

## Rules

- Public APIs expose intent and value contracts, never Vulkan, SDL, ImGui, ECS implementation pointers, allocator ownership, or product managers.
- Fallible public operations use structured `Result<T>`/`Error`; do not return unexplained `bool` and do not throw across module/add-on boundaries.
- Runtime identity uses typed generational handles; persistent serialization IDs are separate.
- Public headers must be self-contained and have one primary contract plus directly related value types.
- Keep STL/C++ ownership away from future stable C ABI boundaries; use fixed-width values, explicit spans/buffers, versioned structs/function tables when that boundary is introduced.
- Service interfaces describe capability and semantics, not backend mechanisms.
- Dependencies flow inward: foundation cannot depend on domain/product/backend code.
- New convenience APIs must delegate to the canonical owner rather than create an alternate state or execution route.

## Review checklist

Check error propagation, invalid/stale handle behavior, ownership/lifetime documentation, thread/callback semantics when relevant, header self-containment, forbidden public types, capability reporting, and focused contract tests.

Any public API change before 1.0 must migrate all in-repository consumers in the same slice.
