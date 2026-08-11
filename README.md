# A-Engine

A-Engine คือโครงการ open-source C++ 3D engine สำหรับสร้างทั้งเกมและโปรแกรม 3D
เช่น model editor, sculpting tool และ texture painting application โดยออกแบบ API,
diagnostics และ tooling ให้คนกับ AI พัฒนาต่อได้ง่ายและตรวจสอบผลได้จริง

## สถานะ

**Phase 1: foundation slice complete**

License: [MIT](LICENSE)

Repository นี้ถูกสร้างใหม่เมื่อ 2026-08-11 หลังนำ prototype เดิมออกไปไว้ใน Windows
Recycle Bin การเริ่มใหม่ครั้งนี้ไม่ใช่การ copy APaint หรือ engine เดิมทั้งก้อน แต่เป็นการ
กำหนด contract ก่อน แล้วค่อยสร้าง vertical slice ที่มี consumer และ test จริง

เอกสารหลัก:

- [A-Engine API Architecture](docs/AENGINE_API_ARCHITECTURE.md)
- [A-Engine / APaint Ownership Boundary](docs/AENGINE_APAINT_BOUNDARY.md)
- [A-Engine High-level UI Architecture](docs/AENGINE_UI_ARCHITECTURE.md)
- [Code Shape Policy](docs/CODE_SHAPE_POLICY.md)
- [Agent Skills](.agent/skills/README.md)
- [Generated AI Context](.agent/code-map/current/AI_CONTEXT.md)
- [Research Brief](docs/RESEARCH_BRIEF.md)
- [Phase 0 Approval Package](docs/PHASE_0_APPROVAL.md)

## Developer experience เป้าหมาย

```cpp
#include <AEngine/App.h>

int main() {
    auto appResult = aengine::App::Init({
        .name = "My3DApp",
    });
    if (!appResult) {
        return appResult.Error().ExitCode();
    }

    auto app = std::move(appResult.Value());
    auto view3D = app.CreateView3D();
    view3D.Update();
    return app.Run();
}
```

API ด้านบนเป็น target contract ยังไม่ใช่ API ที่ build ได้ใน repository ปัจจุบัน
ความเรียบง่ายของ façade ต้องลง execution path เดียวกับ low-level API และห้ามซ่อน
global singleton, Vulkan handle หรือ privileged path

## หลักการ

- public API เป็น backend-neutral; Vulkan, SDL, Dear ImGui และ UI-renderer resources
  อยู่หลัง typed contracts/ports
- low-level typed API และ high-level workflow API ใช้ source of truth เดียวกัน
- shader ใช้ textual shader language และ reusable function library; ไม่ใช้ shader node
- engine-owned modulesเริ่ม static/private link ได้; public add-onใช้ dynamic library
  ผ่าน stable C ABI และ C++/C# SDK wrappers
- A-Engine เป็นเจ้าของ High-level UI API และ canonical Dear ImGui backend รุ่นแรก;
  APaint สร้าง product panels/dialogs/workspacesผ่าน API นี้โดยไม่ถือ native UI/GPU state
- A-Engine เป็นเจ้าของ reusable mechanisms; APaint เป็นเจ้าของ product UI content,
  policy, presets และ `.apaint` project semantics
- APaint เป็น donor/reference consumer ไม่ใช่ dependency ของ A-Engine
- สร้างทีละ vertical slice พร้อม tests, runtime evidence และ deletion condition
- schema, diagnostics, examples และ AI code map ต้อง machine-readable/ตรวจ drift ได้
  เพื่อให้ AI ไม่ต้องเดา architecture จากชื่อ class หรือเอกสารเก่า

## ลำดับสร้าง

1. Phase 0 — MIT/third-party policy, platform/toolchain, dependency rules และ project policy
2. Phase 1 — foundation, typed handles, errors/results, jobs และ diagnostics
3. Phase 2 — `App::Init`, `Run`, `PumpFrame`, `Quit` และ headless lifecycle
4. Phase 3 — world, scene, asset และ glTF viewer slice
5. Phase 4 — renderer, shader library, Vulkan backend และ `View3D`
6. Phase 5+ — High-level UI/workflows/editor/add-ons แล้วจึงทยอยย้าย APaint และ feature packs

Phase 0 approval ถูกบันทึกใน [Phase 0 Approval Package](docs/PHASE_0_APPROVAL.md)
และ Phase 1 เริ่มจาก foundation แบบ dependency-free ก่อนเพิ่ม platform, renderer หรือ
product scaffold.

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

## AI Code Map

production target ใต้ `engine/` และ `tools/` ต้องมี `MODULE.json` ที่ประกาศ ownership,
dependency, tests, entry points และ skill routing ส่วน source/CMake/tests คือ observed reality

`build.bat` จะ fingerprint input เหล่านี้และ regenerate `.agent/code-map/current/` เมื่อมี
การเปลี่ยนแปลง แต่จะเขียนไฟล์ใหม่เฉพาะเมื่อ navigation structure ที่ AI ต้องรู้เปลี่ยนจริง
จึงไม่สร้าง Git noise เมื่อแก้ body ของ implementation ธรรมดา

AI ควรเริ่มจาก:

1. `AGENTS.md`
2. skill ที่เกี่ยวข้อง
3. `.agent/code-map/current/AI_CONTEXT.md`
4. `.agent/code-map/current/INDEX.json`
5. `modules/<target>.json` ของ module ที่เกี่ยวข้อง
6. public contract + focused tests
7. implementation เฉพาะ route ที่ต้องแก้

consumer แรกคือ `aengine_info` ซึ่งอ่าน version/capabilities ผ่าน public header เท่านั้น
และ Phase 1 ไม่มี dependency นอก C++ standard library.
