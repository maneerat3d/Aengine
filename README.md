# A-Engine

A-Engine คือโครงการ open-source C++ 3D engine สำหรับสร้างทั้งเกมและโปรแกรม 3D
เช่น model editor, sculpting tool และ texture painting application โดยออกแบบ API,
diagnostics และ tooling ให้คนกับ AI พัฒนาต่อได้ง่ายและตรวจสอบผลได้จริง

## สถานะ

**Phase 0: docs-first / ยังไม่มี production source**

License: [MIT](LICENSE)

Repository นี้ถูกสร้างใหม่เมื่อ 2026-08-11 หลังนำ prototype เดิมออกไปไว้ใน Windows
Recycle Bin การเริ่มใหม่ครั้งนี้ไม่ใช่การ copy APaint หรือ engine เดิมทั้งก้อน แต่เป็นการ
กำหนด contract ก่อน แล้วค่อยสร้าง vertical slice ที่มี consumer และ test จริง

เอกสารหลัก:

- [A-Engine API Architecture](docs/AENGINE_API_ARCHITECTURE.md)
- [Research Brief](docs/RESEARCH_BRIEF.md)

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

- public API เป็น backend-neutral; Vulkan/SDL/UI implementation อยู่หลัง ports
- low-level typed API และ high-level workflow API ใช้ source of truth เดียวกัน
- shader ใช้ textual shader language และ reusable function library; ไม่ใช้ shader node
- engine-owned modulesเริ่ม static/private link ได้; public add-onใช้ dynamic library
  ผ่าน stable C ABI และ C++/C# SDK wrappers
- APaint เป็น donor/reference consumer ไม่ใช่ dependency ของ A-Engine
- สร้างทีละ vertical slice พร้อม tests, runtime evidence และ deletion condition
- schema, diagnostics และ examples ต้อง machine-readable/ตรวจ drift ได้ เพื่อให้ AI
  ไม่ต้องเดา architecture จากชื่อ class หรือเอกสารเก่า

## ลำดับสร้าง

1. Phase 0 — MIT/third-party policy, platform/toolchain, dependency rules และ project policy
2. Phase 1 — foundation, typed handles, errors/results, jobs และ diagnostics
3. Phase 2 — `App::Init`, `Run`, `PumpFrame`, `Quit` และ headless lifecycle
4. Phase 3 — world, scene, asset และ glTF viewer slice
5. Phase 4 — renderer, shader library, Vulkan backend และ `View3D`
6. Phase 5+ — workflows/editor/add-ons แล้วจึงทยอยย้าย APaint และ feature packs

ยังไม่สร้าง CMake/source scaffold จนกว่า Phase 0 decisions ที่เหลือจะได้รับการอนุมัติ
เพราะ scaffold ที่ไม่มี approved compiler/platform/build policy จะกลายเป็นหนี้ตั้งแต่
วันแรก
