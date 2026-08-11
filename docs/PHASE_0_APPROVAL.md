# Phase 0 Approval Package

Status: **approved for dependency-free Phase 1 — P0-07 remains deferred until a third-party dependency is introduced**

Date: 2026-08-11

Authority: this document records the decisions needed to pass the Phase 0 gate
defined by [A-Engine API Architecture](AENGINE_API_ARCHITECTURE.md).  Until every
required decision below is marked **Approved** by a maintainer, this repository
remains docs-first: do not add `CMakeLists.txt`, production targets, renderer,
game, editor, or migration scaffolding.

## 1. Approval record

| ID | Decision | Proposed baseline | Status |
| --- | --- | --- | --- |
| P0-01 | First supported platform | Windows 11 x64 only | Approved — user, 2026-08-11 |
| P0-02 | Compiler | MSVC 14.44.35207 from Visual Studio 2022 17.14; C++20 | Approved — user, 2026-08-11 |
| P0-03 | Windows SDK | 10.0.26100.0 | Approved — user, 2026-08-11 |
| P0-04 | Configure generator | Ninja, invoked from a Visual Studio x64 developer environment | Approved — user, 2026-08-11 |
| P0-05 | CMake compatibility | CMake 3.28 or newer; local feasibility environment is CMake 4.1.1 | Approved — user, 2026-08-11 |
| P0-06 | Dependency acquisition and lock policy | The policy in section 3 | Approved — user, 2026-08-11 |
| P0-07 | SBOM serialization and generator | Select an SPDX JSON/JSON-LD version and generator before the first third-party dependency enters the tree | Deferred with trigger |
| P0-08 | Contribution, security, versioning and release policy | The policy in section 5 | Approved — user, 2026-08-11 |

P0-01 through P0-06 and P0-08 require explicit maintainer approval.  P0-07 is
not a reason to block the dependency-free Phase 1, but it becomes a hard gate
before the first third-party dependency is introduced.  It cannot be silently
inferred from the workstation, a donor repository, or a popular toolchain.

The proposed CMake 3.28 floor establishes a known policy baseline and supports
the C++20 target profile without making the locally installed CMake 4.1.1 a
requirement for every contributor.  It must still be validated by the Phase 1
configure/test matrix once the root project exists.

### 1.1 Evidence captured on the current workstation

This is feasibility evidence, not a portability claim or an approval:

| Item | Observed value |
| --- | --- |
| Host OS | Windows 11, build 26200 |
| Visual Studio Community | 2022 17.14.18 |
| MSVC toolset available in that installation | 14.44.35207 |
| Windows SDK installed | 10.0.26100.0 |
| CMake | 4.1.1 |
| Ninja | 1.13.0 |

Visual Studio Build Tools 2026 and its newer toolset are present too, but are
not proposed as the baseline.  Keeping the baseline on the established Visual
Studio 2022 installation avoids making a newly introduced toolchain the
compatibility contract without a dedicated compatibility decision.

## 2. Canonical commands after approval

These commands become valid only after P0-01 through P0-06 and P0-08 are
approved and Phase 1 adds the root CMake project.  They are deliberately
documented now so the first implementation has one reproducible route.

Start a Visual Studio x64 developer PowerShell, then run:

```powershell
cmake -S . -B out/build/windows-x64-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build out/build/windows-x64-debug --parallel
ctest --test-dir out/build/windows-x64-debug --output-on-failure
```

Release verification uses the same generator and an isolated build directory:

```powershell
cmake -S . -B out/build/windows-x64-release -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build out/build/windows-x64-release --parallel
ctest --test-dir out/build/windows-x64-release --output-on-failure
```

The initial platform profile is intentionally headless.  Windowing, GPU
driver, and Vulkan runtime requirements belong to later platform/render slices;
they must not become hidden requirements of `aengine_foundation`.

## 3. Third-party, donor, and SBOM policy

1. Repository-authored source remains MIT under [LICENSE](../LICENSE).
   A repository-level MIT license never relicenses imported code, generated
   output, assets, test data, or binary tools.
2. No dependency, donor source, generated artifact, or binary tool enters the
   repository without a provenance record containing name, version or revision,
   upstream URL, license expression, copyright/notice requirement, acquisition
   method, hash when applicable, owner, and consumer target.
3. Before code is copied from APaint or any other donor, record its current
   call path, target owner, public contract, license compatibility, test plan,
   remaining consumer inventory, and deletion condition.  AEngine targets may
   never include, link, or borrow relative source paths from APaint.
4. Dependencies are private implementation details by default.  Public SDK
   headers may not expose their headers, ABI types, or allocator ownership.
   Vulkan, VMA, volk, SDL, ImGui, Flecs, and APaint are forbidden from the
   `aengine_foundation` public surface.
5. Every release candidate must contain an approved SPDX JSON or JSON-LD SBOM
   generated from the provenance ledger and the resolved dependency lock.  A
   release is blocked if an entry is missing, its license is unknown, or its
   recorded version/hash does not match the artifact.
6. The first dependency slice must select and validate the SBOM generator and
   serialization in the same review; it may not defer those controls until
   release time.

## 4. Architecture test specification

The Phase 1 build must implement these checks before adding its second target:

| Guard | Scope | Required failure condition |
| --- | --- | --- |
| Header self-containment | Each public `AEngine/*.h` header | Fails when it needs include order or a private header to compile |
| Forbidden public dependencies | Foundation public headers | Fails on `Vk`, `vma`, `volk`, `SDL`, `ImGui`, APaint, or ECS implementation includes/types |
| Target dependency direction | All `aengine_*` targets | Fails when a foundation/domain target links a product, UI, APaint, or backend target outside its approved dependencies |
| No APaint borrowing | Entire AEngine source/build tree | Fails on APaint include paths, link targets, or sibling-source references |
| API error model | Foundation contracts | Fails when a fallible public operation lacks `Result<T>` or a structured `Error` path |
| First-consumer proof | `aengine_info` | Fails unless version and capabilities are queried through the public API only |

The guard implementation itself is part of the Phase 1 vertical slice.  It
must run under CTest and be documented with the canonical commands above;
manual review alone is not sufficient evidence.

## 5. Project governance proposal

### Contribution and review

- Every production change is one vertical slice with a ledger: user outcome,
  owner/API, dependency direction, lifetime/state, invariants, exact scope,
  test evidence, rollback point, and deletion condition.
- A pull request must state the canonical configure/build/test commands run and
  preserve unrelated dirty-worktree changes.
- Generated files are committed only when their generator, inputs, and
  reproduction command are recorded.

### Versioning and release

- Internal C++ APIs may change before 1.0, but the same slice must migrate all
  in-repository consumers.
- Public ABI/API versioning begins only at the Phase 9 SDK boundary; it uses
  semantic versioning, versioned C function tables, `structSize`, and explicit
  capabilities as defined by the canonical architecture.
- A release requires successful debug and release test evidence, dependency
  guard evidence, third-party notices, the verified SPDX SBOM, and reproducible
  source/build identity metadata.

### Security reporting and operational boundaries

- Do not commit credentials, access tokens, signing keys, private customer
  assets, or unreviewed binaries.
- Report a vulnerability privately to the maintainers; do not publish exploit
  details before a fix and disclosure plan exist.
- Native add-ons are trusted in-process code, not a sandbox.  This restriction
  must be stated in every future add-on distribution surface.

## 6. Phase 1 entry and exit checklist

Phase 1 may begin only after the maintainer approves P0-01 through P0-06 and
P0-08.  P0-07 remains a mandatory gate for the later slice that introduces the
first third-party dependency.
Its single vertical slice owns exactly:

- root CMake project and presets implementing the approved command contract;
- `aengine_foundation` with typed generational handles, `OperationId`, API
  version/capabilities, `ErrorCode`, `Error`, `Result<T>`, job/ticket value
  contracts, minimal diagnostics, and documented ABI ownership rules;
- the headless `aengine_info` consumer; and
- the architecture guards in section 4 plus focused handle/error tests.

Phase 1 exits only when foundation build/test succeeds without SDL, ImGui,
Vulkan, APaint, or a product module, and tests reject stale/wrong-type handles
and preserve structured error propagation.

## 7. Maintainer approval

Approval is an explicit record, not an implication from merging this document.
When approved, replace the status column in section 1 with the approver and
date, and update the architecture or research brief if a decision changes their
assumptions.  Resolve P0-07 in the dependency-introducing slice before any
third-party code or binary is added.
