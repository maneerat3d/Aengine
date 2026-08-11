# A-Engine

A-Engine คือโครงการ open-source C++ 3D engine สำหรับสร้างทั้งเกมและโปรแกรม 3D
เช่น model editor, sculpting tool และ texture painting application โดยออกแบบ API,
diagnostics และ tooling ให้คนกับ AI พัฒนาต่อได้ง่ายและตรวจสอบผลได้จริง

## สถานะ

**Phase 2A complete: dependency-free headless application lifecycle; architecture/OOP safety baseline before Phase 2B**

License: [MIT](LICENSE)

Repository นี้ถูกสร้างใหม่เมื่อ 2026-08-11 แบบ docs-first การเริ่มใหม่ครั้งนี้ไม่ใช่การ
copy APaint หรือ engine เดิมทั้งก้อน แต่กำหนด contract ก่อนแล้วค่อยสร้าง vertical slice
ที่มี consumer และ test จริง

เอกสารหลัก:

- [A-Engine API Architecture](docs/AENGINE_API_ARCHITECTURE.md)
- [Architecture + OOP Safety Baseline](docs/ARCHITECTURE_SAFETY_BASELINE.md)
- [A-Engine / APaint Ownership Boundary](docs/AENGINE_APAINT_BOUNDARY.md)
- [A-Engine High-level UI Architecture](docs/AENGINE_UI_ARCHITECTURE.md)
- [Code Shape Policy](docs/CODE_SHAPE_POLICY.md)
- [Agent Skills](.agent/skills/README.md)
- [Generated AI Context](.agent/code-map/current/AI_CONTEXT.md)
- [Research Brief](docs/RESEARCH_BRIEF.md)
- [Phase 0 Approval Package](docs/PHASE_0_APPROVAL.md)

## Phase 2A developer experience

```cpp
#include <AEngine/Application.h>

#include <utility>

int main() {
    constexpr char kName[] = "My3DApp";
    auto appResult = aengine::App::Init({
        .name = aengine::Utf8View{kName, sizeof(kName) - 1},
    });
    if (!appResult) {
        return 1;
    }

    auto app = std::move(appResult).Value();
    auto frame = app.PumpFrame();
    if (!frame) {
        return 2;
    }

    app.Quit();
    auto stopped = app.PumpFrame();
    return stopped && !stopped.Value() ? 0 : 3;
}
```

Phase 2A implement `App::Init`, `Run`, `PumpFrame`, `Quit`, lifecycle state และ deterministic
application trace โดยยังไม่เพิ่ม SDL, Vulkan, ImGui หรือ APaint dependency. Window/input/time/
filesystem ports และ `ApplicationServices` injection เป็น Phase 2B

## หลักการ

- public API เป็น backend-neutral; Vulkan, SDL, Dear ImGui และ native resources อยู่หลัง typed contracts/ports
- mutable state มี canonical owner เดียว และ mutation gateway เดียวต่อ responsibility
- lifecycle/threading/invariants ต้องประกาศใน `MODULE.json` ก่อน subsystem ซับซ้อนขึ้น
- OOP ใช้ ownership/lifetime/encapsulation; Composition + RAII เป็น default และหลีกเลี่ยง deep inheritance/manager aggregates
- low-level typed API และ high-level workflow API ใช้ source of truth เดียวกัน
- APaint เป็น donor/reference consumer ไม่ใช่ dependency ของ A-Engine
- สร้างทีละ vertical slice พร้อม tests, runtime evidence และ deletion condition
- schema, diagnostics, examples และ AI code map ต้อง machine-readable/ตรวจ drift ได้

## ลำดับสร้าง

1. Phase 0 — MIT/third-party policy, platform/toolchain, dependency rules และ project policy
2. Phase 1 — foundation, typed handles, errors/results, jobs และ diagnostics
3. Phase 2A — dependency-free Application lifecycle
4. Architecture/OOP Safety Baseline — durable owner/lifetime/threading/invariant/dependency guards
5. Phase 2B — window/input/time/filesystem ports และ `ApplicationServices`
6. Phase 3 — world, scene, asset และ glTF viewer slice
7. Phase 4 — renderer, shader library, Vulkan backend และ `View3D`
8. Phase 5+ — High-level UI/workflows/editor/add-ons แล้วจึงทยอยย้าย APaint และ feature packs

## Build และ test

**ใช้ `build.bat` จาก repository root เป็น entrypoint เดียว** ทั้งคน, AI agent และ CI
ห้ามเรียก CMake/Ninja/CTest โดยตรงใน normal workflow

```bat
build.bat
```

คำสั่งที่รองรับ:

```bat
build.bat                 rem AI map + Debug build/test + Release build/test
build.bat debug           rem AI map + Debug build/test
build.bat release         rem AI map + Release build/test
build.bat test REGEX      rem AI map + Debug build + focused CTest regex
build.bat map             rem update AI navigation map only when needed
```

`build.bat` pin Visual Studio 2022 17.14 / MSVC 19.44 toolset 14.44 / Windows SDK
10.0.26100.0 แล้วใช้ CMake presets + Ninja แบบ incremental ภายใน

## Durable AI context / new chat

A-Engine ไม่พึ่ง chat memory เพื่อรักษา architecture เมื่อเปิดห้องใหม่ Agent ทุก session
reconstruct state จาก repository ตามลำดับนี้:

1. `AGENTS.md`
2. `.agent/code-map/current/AI_CONTEXT.md`
3. `.agent/code-map/current/INDEX.json`
4. `modules/<target>.json` เฉพาะ module ที่เกี่ยวข้อง
5. routed skills เช่น `software-architecture`, `cpp-oop-design`, `cpp-api-contracts`
6. public contract + focused tests
7. implementation เฉพาะ route ที่ต้องแก้

`MODULE.json` schema v2 ประกาศ owner, dependency, state owners, lifetime, threading,
mutation gateway, invariants, tests และ stop line ส่วน AI map วาง declared intent คู่กับ
observed CMake/source/public API. `build.bat` regenerate map เมื่อจำเป็นและ CI fail เมื่อ drift

Safety guards ตรวจ module contract, dependency cycle, public API ownership, OOP anti-pattern,
source shape, agent skills, build entrypoint และ AI-map drift ก่อน completion ค่ะ
