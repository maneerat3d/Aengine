# Phase 1 — Foundation and Build Backbone Slice Ledger

Status: **complete**

Date: 2026-08-11

Authority: [A-Engine API Architecture](AENGINE_API_ARCHITECTURE.md), section
13, Phase 1.  Phase 0 approval is recorded in
[PHASE_0_APPROVAL.md](PHASE_0_APPROVAL.md).

## Ledger

| Field | Decision |
| --- | --- |
| User outcome | Developer can configure, build, test, and run a headless `aengine_info` tool that obtains build identity and capability data through the public A-Engine API. |
| Transform | Establish the dependency-free foundation contract and its first consumer. |
| Current owner/route | This repository previously had no production route. APaint AP4 is reference evidence only: its `apaint_core` target is an aggregate with UI, Vulkan, APaint managers, and third-party dependencies, so it is explicitly excluded as a dependency or code donor. |
| Target owner/API | `aengine_foundation`: typed handles, `OperationId`, `Result<T>`, structured errors, version/capabilities, job value contracts, UTF-8/byte views, and instance-owned diagnostics. `aengine_info` is the first consumer. |
| Dependency direction | `aengine_info` and contract tests may link `aengine_foundation`; foundation links only the C++ standard library. No target may include/link APaint, Vulkan, SDL, ImGui, VMA, volk, Flecs, or a product module. |
| Lifetime/state | Handles are identity values, never ownership. A pool owner creates/invalidates handles; erased slots advance generation. `Result<T>` always has either a value or a structured error. Job state is a value snapshot; it owns no background execution in this slice. Diagnostics are owned by an explicit `DiagnosticLog` instance. |
| Invariants | Wrong-tag, null, forged, and stale handles are rejected; public errors carry code, owner, and operation ID; no exception crosses public contracts; public UTF-8/byte views are non-owning and valid only while their caller-provided storage remains alive; `aengine_info` uses only `sdk/include/AEngine` headers. |
| Exact scope | `CMakeLists.txt`, `CMakePresets.json`, `cmake/`, `engine/foundation/`, `sdk/include/AEngine/`, `tools/aengine_info/`, `tests/contract/`, `tests/architecture/`, `docs/PHASE_1_SLICE.md`, and build instructions in `README.md`. |
| Excluded scope | Application lifecycle, windows, renderer, Vulkan, shader tooling, ECS, scene/assets, importers, commands/workflows, editor UI, add-ons, and all APaint migration code. |
| Baseline | Docs-only repository: no CMake target, source, or tests. MSVC 19.44.35219 was verified in the Visual Studio 2022 x64 developer environment. |
| Verification | CMake configure/build; CTest contract tests for handles/errors/operations/jobs; CTest architecture guard for public forbidden dependencies and APaint borrowing; `aengine_info` output check. |
| Deletion condition | None: no legacy A-Engine production route exists. |
| Rollback | Revert only this slice's new files and the matching README/approval-record changes; no donor or user source is modified. |

## APaint AP4 reference record

- Donor reference: local `C:\Users\manee\Code\AP4\Apaint`, consulted for
  CMake/CTest and evidence-first architecture-guard patterns.
- No APaint source, build logic, dependencies, or headers are copied.
- `src/core/CMakeLists.txt` demonstrates why `apaint_core` cannot be an
  A-Engine foundation dependency: it publicly links SDL, Vulkan tooling, UI,
  managers, and product dependencies.
- `tools/apaint_guard` demonstrates the desired principle that a guard emits
  reproducible failure evidence.  A-Engine implements a new, narrow CMake
  guard appropriate to its dependency-free Phase 1 scope.

## Verification evidence

| Lane | Command | Result |
| --- | --- | --- |
| Debug configure | `cmake --preset windows-x64-debug` | Passed with MSVC 19.44.35219 |
| Debug build | `cmake --build --preset windows-x64-debug --parallel` | Passed; all public-header object checks compiled |
| Debug test | `ctest --preset windows-x64-debug` | Passed 3/3: foundation contract, architecture guard, and `aengine_info` |
| Release configure | `cmake --preset windows-x64-release` | Passed with MSVC 19.44.35219 |
| Release build | `cmake --build --preset windows-x64-release --parallel` | Passed |
| Release test | `ctest --preset windows-x64-release` | Passed 3/3: foundation contract, architecture guard, and `aengine_info` |
| Consumer output | `out/build/windows-x64-debug/tools/aengine_info/aengine_info.exe` | Reported `api=0.1.0`, `compiler=MSVC`, and capability bits `3` (`Foundation | Headless`) |
