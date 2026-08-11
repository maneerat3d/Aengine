# A-Engine Code Shape Policy

Status: **normative for production code and AI-generated changes**

Date: 2026-08-11

Purpose: keep A-Engine modular, reviewable, and easy for both humans and AI to inspect without creating God classes, dumping-ground files, or hidden ownership.

## 1. Core rule

One file/class should have one clear owner and one primary reason to change.

A file is too large even before it reaches the hard line limit when it starts to own more than one of these responsibilities:

- state/lifetime ownership;
- orchestration/workflow;
- policy/strategy;
- backend/platform adaptation;
- serialization/persistence;
- UI/presentation;
- diagnostics/testing support.

Split by responsibility, not by arbitrary line chunks.

## 2. Mandatory separation rules

- Composition roots may wire several subsystems, but they must not contain domain behavior.
- Facades expose use cases and delegate to injected services; they must not duplicate service state.
- Platform/backend adapters isolate SDL, Vulkan, ImGui, OS, filesystem, or other implementation details from public contracts.
- Policy/strategy objects are separate from state owners when behavior can vary independently.
- A public header should normally expose one primary contract/class plus closely related value types only.
- Avoid generic dumping-ground names such as `Common`, `Misc`, `Everything`, or unscoped `Utils`.
- Do not add a second independent lifecycle/state machine to an existing class; create a separate owner and compose it.
- Do not add product/editor/game policy to foundation/platform owners.
- Umbrella headers may aggregate includes but must not contain implementation or state.

## 3. Hard source-size budgets

The architecture guard counts physical source lines. These are hard stop lines, not targets.

| Scope | Hard maximum |
| --- | ---: |
| Public SDK header under `sdk/include/AEngine` | 220 lines |
| Engine implementation/header under `engine` | 320 lines |
| Tool implementation/header under `tools` | 240 lines |
| Test implementation/header under `tests` | 400 lines |
| CMake/architecture guard script | 300 lines |

A file should be split earlier if responsibility boundaries become unclear, even if it is still below the limit.

Generated code is not automatically exempt. Any future exemption must identify the generator, owner, reason, consumer, temporary budget, and removal/review phase.

## 4. God-class stop conditions

Stop adding behavior and split the owner when any of these becomes true:

- one class coordinates multiple unrelated subsystems and also owns their mutable state;
- one class performs both orchestration and backend resource lifetime management;
- one class becomes the mutation entry point for unrelated domains;
- a facade begins implementing domain rules instead of delegating them;
- a new feature requires broad edits to a central class instead of adding/replacing a focused component;
- tests cannot isolate the class without constructing unrelated subsystems.

Line count alone cannot prove a God class, so semantic review remains mandatory.

## 5. AI-reviewable module shape

Each vertical slice should make it possible to identify quickly:

1. public contract/owner;
2. implementation owner;
3. composition/wiring point;
4. focused tests;
5. dependency direction;
6. lifetime/state owner;
7. diagnostics/evidence path.

Prefer several small named files with explicit dependencies over one large manager file with hidden branches.

## 6. Exception policy

There are no source-shape exceptions in the repository initially.

Any exception must be explicit and reviewed. It must record path, owner, rationale, why splitting would reduce correctness/readability, temporary limit, consumer inventory, and a removal or review phase. Silent exemptions are forbidden.
