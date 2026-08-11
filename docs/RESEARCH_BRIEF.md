# A-Engine Architecture Research Brief

Status: **Phase 0 evidence / decision input**

Date: 2026-08-11

Scope: module boundaries, extension ABI, scene/assets, ECS และ shader toolchain

เอกสารนี้เก็บ primary-source evidence ที่ใช้ประกอบ
[`AENGINE_API_ARCHITECTURE.md`](AENGINE_API_ARCHITECTURE.md) แหล่งอ้างอิงเหล่านี้
ไม่ใช่คำสั่งให้เลียนแบบ engine ใดทั้งระบบ แต่ใช้แยก pattern ที่พิสูจน์แล้วออกจาก
assumption ของผู้พัฒนา/AI

## 1. Extension boundary

### Evidence

- Godot อธิบาย GDExtension ว่าเป็น native shared library ที่ engine โหลดขณะ runtime
  และใช้ C interface เพื่อให้ extension ไม่ต้อง link กับ engine executable โดยตรง:
  <https://docs.godotengine.org/en/latest/engine_details/engine_api/gdextension/what_is_gdextension.html>
- GDExtension interface JSON เป็น source of truth สำหรับ C header, documentation และ
  versioned function metadata:
  <https://docs.godotengine.org/en/latest/engine_details/engine_api/gdextension/gdextension_interface_json_file.html>

### A-Engine decision

- ภายใน pre-1.0 ใช้ C++ interfaces เพื่อ iterate ได้เร็ว แต่ public add-on ABI 1.0
  ต้องเป็น version-negotiated C ABI function tables พร้อม `structSize`, API version
  และ capabilities
- สร้าง machine-readable schema แล้ว generate C header/docs/compatibility tests จาก
  source เดียวกัน ห้าม maintain ABI declarations หลายชุดด้วยมือ
- add-on รับ scoped services/opaque IDs ห้ามรับ internal pointer หรือ backend handle
- engine-owned modulesเริ่ม static/private ได้ แต่ external native add-onใช้ dynamic
  libraryผ่าน C ABI; C++ SDKเป็น thin wrapper/import target ไม่ static-link engine copy

## 2. Modules and plugins

### Evidence

- Unreal แยก code เป็น modules ที่มี build rules/dependencies และให้ plugin เป็น
  optional collection ของ modules/content:
  <https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-modules>
  และ <https://dev.epicgames.com/documentation/en-us/unreal-engine/plugins-in-unreal-engine>

### A-Engine decision

- ใช้ modular monolith: CMake target ต่อ ownership boundary ไม่ใช่ directory decoration
- feature pack เช่น paint, geometry, editor, animation เป็น optional consumers ของ
  foundation/world/render contracts; foundation ห้าม link ย้อนกลับ
- add-on package อาจมีหนึ่งหรือหลาย modules แต่ lifecycle/resource ownership ต้อง
  track ในระดับ add-on identity

## 3. Scene and interchange

### Evidence

- OpenUSD ออกแบบ scene description สำหรับการประกอบหลาย layers/assets และรักษา
  non-destructive overrides:
  <https://openusd.org/release/intro.html>
- glTF เป็นมาตรฐาน Khronos สำหรับส่งมอบ 3D scenes/models และมี normative registry:
  <https://registry.khronos.org/glTF/>

### A-Engine decision

- Phase 3 ใช้ glTF 2.0 เป็น first import/runtime delivery proof เพราะ scope เล็กกว่า
  full DCC composition
- ห้ามประกาศว่า A-Engine scene format คือ USD โดยอัตโนมัติ ต้องทำ dedicated slice
  เพื่อเลือกบทบาทระหว่าง internal document model, runtime scene และ interchange
- persistent IDs, revisions, transactions และ asset URIs เป็น engine contracts ของเรา
  ไม่ควรเท่ากับ pointer/index ของ importer library

## 4. World/ECS

### Evidence

- Flecs แยก entities, components, systems, queries และ modules พร้อม lifecycle ที่
  documented ใน manual:
  <https://www.flecs.dev/flecs/md_docs_2Manual.html>

### A-Engine decision

- Flecs เป็น candidate implementation ไม่ใช่ public API
- public world API ใช้ typed entity/component IDs, snapshots และ commands เพื่อให้
  เปลี่ยน ECS implementation ได้และป้องกัน caller mutate storage ข้าม thread
- ก่อนเลือก Flecs ต้องทำ Phase 3 spike วัด hierarchy, serialization, deterministic
  update, editor transactions และ add-on component registration

## 5. Shader language and SPIR-V

### Evidence

- Khronos ระบุ GLSL เป็น high-level language สำหรับ programmable processors และ
  Vulkan GLSL semantics อยู่ใน normative specification:
  <https://github.khronos.org/Vulkan-Site/glsl/latest/chapters/introduction.html>
- SPIR-V เป็น intermediate language/format ของ Khronos พร้อม registry และ grammar:
  <https://registry.khronos.org/SPIR-V/>
- Vulkan guide เปรียบเทียบ shader languages และ toolchains โดยชี้ว่าหลายภาษา
  สามารถ compile ไป SPIR-V ได้:
  <https://github.khronos.org/Vulkan-Site/guide/latest/high_level_shader_language_comparison.html>

### A-Engine decision

- เส้นทางแรกใช้ textual Vulkan GLSL 450 -> SPIR-V target Vulkan 1.2 เพื่อสอดคล้องกับ
  APaint donor/runtime evidence และแก้ source ได้ง่ายด้วย AI
- ไม่สร้าง shader-node authoring subsystem ใน A-Engine
- helper library แยก pure functions ออกจาก entry programs/resource ABI
- reflection ของ SPIR-V ต้อง generate/verify descriptor, format, push-constant และ
  workgroup contracts กับ host code; shader compile ผ่านอย่างเดียวไม่พอ
- architecture เปิดทางให้เพิ่ม language frontend ภายหลังได้ แต่ SPIR-V ABI และ
  shader-library semantics ต้องไม่แตกเพราะเปลี่ยน frontend

## 6. Managed C# layer

### Evidence

- Microsoft ระบุว่า C++ ไม่มี ABI เดียวที่คงที่ข้าม MSVC/Clang/GCC และแนะนำให้ export
  `extern "C"` เพื่อ interop:
  <https://learn.microsoft.com/en-us/dotnet/standard/native-interop/abi-support>
- .NET native interop guidance แนะนำ source-generated `LibraryImport` สำหรับ .NET 7+,
  `SafeHandle` สำหรับ unmanaged resource lifetime และ blittable structsเมื่อเป็นไปได้:
  <https://learn.microsoft.com/en-us/dotnet/standard/native-interop/best-practices>
- Native AOT รองรับ direct P/Invoke/native exports แต่มี deployment/linker/lifetime
  constraints ที่ต้องวัดแยก ไม่ควรถือเป็น default solutionโดยไม่ทำ spike:
  <https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/interop>

### A-Engine decision

- C++ เป็น core + canonical low/high-level workflow implementation
- stable C ABI เป็น language boundary แล้ว generate C# interopจาก schemaเดียวกับ SDK
- C# เป็น optional high-level façadeสำหรับ app/editor/gameplay/add-on ไม่ใช่ renderer
  hot path และไม่สร้าง domain logicชุดที่สอง
- ใช้ batch requests/snapshots/ticketsลด interop chatter และมี layout/lifetime/parity
  tests ข้าม C++/C#
- ตัดสิน Native AOT/runtime distribution หลัง platform matrixและ deployment spike

## 7. Conclusions and non-decisions

สิ่งที่ research รองรับแล้ว:

- modular targets + optional feature/plugin packages
- public extension boundary แบบ versioned C ABI และ generated schema
- opaque public identities แทน internal/ECS/GPU pointers
- glTF เป็น first asset proof; USD ต้องตัดสินบทบาทแยก
- textual shader source, reusable function library, SPIR-V reflection/ABI guard
- C++ canonical workflows + C ABI + optional generated C# high-level façade

สิ่งที่ยังไม่ตัดสินใน Phase 0:

- open-source license ที่แน่นอน
- supported compiler/OS/GPU matrix รุ่นแรก
- Flecs เทียบกับ ECS implementation อื่น
- internal scene serialization และบทบาทของ OpenUSD
- physics/audio backends
- binary compatibility window และ package distribution ของ add-on SDK

ห้ามให้ AI เติม non-decisions เหล่านี้จากความนิยม ความจำ หรือ prototype เก่า ต้องมี
requirements, primary-source license/technical evidence, focused spike และ owner approval
ก่อนแก้ canonical architecture
