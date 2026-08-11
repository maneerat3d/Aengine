# A-Engine Agent Instructions

## ภาษา

- คุยกับผู้ใช้เป็นภาษาไทย
- ชื่อ API, symbol, file และ technical terms ใช้ภาษาอังกฤษตามจริง
- PowerShell ใช้ `;` แทน `&&`

## สถานะโครงการ

- A-Engine เป็น open-source C++ 3D engine สำหรับ game และ 3D application
- repository นี้ถูกสร้างใหม่แบบ docs-first เมื่อ 2026-08-11
- canonical architecture คือ `docs/AENGINE_API_ARCHITECTURE.md`
- architecture/OOP safety baseline คือ `docs/ARCHITECTURE_SAFETY_BASELINE.md`
- A-Engine/APaint ownership contract คือ `docs/AENGINE_APAINT_BOUNDARY.md`
- High-level UI/ImGui contract คือ `docs/AENGINE_UI_ARCHITECTURE.md`
- code shape/AI reviewability contract คือ `docs/CODE_SHAPE_POLICY.md`
- project-specific AI skills อยู่ที่ `.agent/skills/`
- generated AI navigation map อยู่ที่ `.agent/code-map/current/`
- research evidence คือ `docs/RESEARCH_BRIEF.md`
- APaint เป็น donor/reference consumer ไม่ใช่ dependency ของ A-Engine

## New chat / new session bootstrap

ห้ามพึ่งความจำจาก chat ก่อนหน้าเป็น architecture source of truth ทุก session ใหม่ต้อง reconstruct จาก repository:

1. อ่าน `AGENTS.md`;
2. อ่าน `.agent/code-map/current/AI_CONTEXT.md` และ `INDEX.json`;
3. เปิด `modules/<target>.json` เฉพาะ module ที่เกี่ยวข้อง;
4. โหลด skill ที่ module route ไว้;
5. ตรวจ public contract, focused tests และ implementation owner ก่อนแก้ code;
6. จบ validation ผ่าน repository-root `build.bat`.

ถ้าการตัดสินใจสำคัญมีอยู่แค่ในบทสนทนาแต่ไม่มีใน source/canonical docs/`MODULE.json`/tests/AI map ให้ encode ลง repository ก่อนพึ่งการตัดสินใจนั้นค่ะ

## Architecture Pre-Code Gate

ก่อนสร้างหรือแก้ production code:

1. อ่าน canonical architecture และ section ของ phase ปัจจุบัน; งาน APaint/migration อ่าน `docs/AENGINE_APAINT_BOUNDARY.md` เพิ่ม และงาน UI อ่าน `docs/AENGINE_UI_ARCHITECTURE.md`
2. อ่าน `docs/ARCHITECTURE_SAFETY_BASELINE.md` และ `docs/CODE_SHAPE_POLICY.md`
3. ระบุ current phase, user outcome, target module(s), owner/API, dependency direction, lifetime/state, threading, mutation gateway, invariants, exact files, tests และ stop line
4. รักษา MIT license และห้ามเดา platform/toolchain/ECS หรือ license compatibility ของ donor/third-party code
5. สร้าง vertical slice ที่มี consumer จริง ห้าม scaffold ทุก module ล่วงหน้า
6. public API ห้าม expose Vulkan, SDL, ImGui, ECS implementation pointer หรือ global service locator
7. เลือกอ่าน skill ที่เกี่ยวข้องจาก `.agent/skills/README.md`; อย่าโหลดทุก skillโดยไม่จำเป็น
8. อ่าน AI code map แล้วเปิดเฉพาะ implementation route ที่เกี่ยวข้อง

ถ้า docs ขัดกับ source หรือไม่มี proof ที่วัด behavior ได้ ให้หยุด production change และทำ docs/diagnostic/characterization slice ก่อน

## AI navigation / module contract

- `MODULE.json` ใต้ `engine/*` และ `tools/*` คือ declared ownership intent ของ production target
- production target `aengine_*` ใหม่ต้องมี `MODULE.json` schema v2 ใน slice เดียวกัน
- schema v2 ต้องประกาศ owner, responsibility, paths, tests, dependencies, state owners, lifetime, threading, mutation gateway, invariants, entry points, skills และ stop line
- `.agent/code-map/current/` เป็น generated observed map สำหรับ navigation ไม่ใช่ authority เหนือ source/canonical docs
- ถ้า map ขัดกับ source ให้แก้ source/manifest/generator ตาม owner ที่ถูกต้อง ห้ามแก้ generated output ด้วยมือ
- `build.bat` fingerprint source/CMake/tests/manifests และ regenerate map เมื่อ input เปลี่ยน แต่เขียน generated file เฉพาะเมื่อ navigation structure เปลี่ยนจริง
- generated map ที่เปลี่ยนต้อง commit พร้อม production change ใน slice เดียวกัน
- mutable `state_owner` ชื่อเดียวกันห้ามถูกประกาศโดยหลาย module และทุก invariant ต้องมี stable ID + focused test

## Skill routing

Skills เป็น procedural overlay เท่านั้นและห้าม override canonical docs/source-of-truth:

- module boundary, ownership, lifecycle, composition root, new subsystem/refactor -> `.agent/skills/software-architecture/SKILL.md`
- class/state/resource ownership, RAII, composition, DI, interface/inheritance -> `.agent/skills/cpp-oop-design/SKILL.md`
- public C++ API/header, Result/Error, handle, service contract, ABI-facing value -> `.agent/skills/cpp-api-contracts/SKILL.md`
- build/test/CI, failure triage, evidence/completion claim -> `.agent/skills/validation-evidence/SKILL.md`
- dependency/version/license/provenance/SBOM -> `.agent/skills/third-party-governance/SKILL.md`
- Vulkan/GPU/shader/pipeline/backend -> `.agent/skills/vulkan-backend/SKILL.md`
- UI/editor/ImGui/panel/menu/viewport -> `.agent/skills/ui-architecture/SKILL.md`
- APaint donor/reference/migration -> `.agent/skills/apaint-migration/SKILL.md`

งานที่ข้ามหลาย concern ให้อ่านเฉพาะ skill ที่ข้ามจริง และทุก completion claim ต้องใช้ `validation-evidence` ค่ะ

## OOP / code shape / AI reviewability

- OOP ใช้เพื่อ ownership, lifetime, encapsulation และ real polymorphic seam ไม่ใช่ทำทุกอย่างเป็น class
- ใช้ Single Responsibility, Composition และ RAII เป็น default
- ใช้ `struct` สำหรับ simple value/data contract และ `class` เมื่อมี protected invariant/owned lifetime
- แยก state owner, orchestration, policy/strategy, backend adapter, serialization และ UI เมื่อมีเหตุผลเปลี่ยนแยกกัน
- facade delegate ไป canonical owner และห้าม duplicate mutable state
- composition root ทำ wiring เท่านั้น ห้ามซ่อน domain behavior
- interface ต้องมี backend/testing/policy/add-on seam จริง ห้าม speculative abstraction
- inheritance ใช้ substitutable polymorphism ไม่ใช้ reuse implementation; หลีกเลี่ยง deep/multiple concrete inheritance
- constructor/composition injection เป็น default; ห้าม global singleton หรือ service locator
- ห้าม dumping-ground owner เช่น `EngineManager`, `SystemManager`, `GlobalContext`, `ServiceLocator`, `Everything`, `Misc`, `Common` หรือ unscoped `Utils`
- source file ถึง limit ใน `docs/CODE_SHAPE_POLICY.md` ต้อง split ก่อนเพิ่ม behavior

## Dependency / mutation / lifecycle safety

- production dependency graph ต้องไม่มี cycle และ observed `aengine_*` dependency ต้องอยู่ใน declared `allowed_dependencies`
- ทุก public header ใต้ `sdk/include/AEngine` ต้องมี owning module เดียว
- ทุก mutable state มี canonical owner เดียว และ mutation เข้า route ที่ `MODULE.json` ประกาศ
- lifecycle owner ต้องประกาศ creation, shutdown และ safe boundary/order
- threading contract ต้องประกาศ affinity/concurrency ก่อนเพิ่ม async/backend behavior
- invariant สำคัญต้องเป็น executable focused test ห้ามลด test/baseline เพื่อให้ green
- legacy/new mutation route อยู่คู่กันได้เฉพาะ migration slice ที่มี deletion condition ชัดเจน

## Canonical build entrypoint

- agent และคนต้องเริ่ม build/test จาก repository root ด้วย `build.bat` เท่านั้น
- normal workflow ห้ามเรียก `cmake`, `ninja`, `ctest` หรือ AI-map PowerShell scripts โดยตรง
- exception มีได้เฉพาะตอน debug/แก้ `build.bat`, CMake integration หรือ generator เอง และ final validation ต้องกลับมาที่ `build.bat`
- `build.bat` default = AI-map update + Debug build/test + Release build/test
- focused commands: `build.bat debug`, `build.bat release`, `build.bat test <regex>`, `build.bat map`
- ใช้ incremental work; ห้าม clean/rebuild ทั้งหมดโดยไม่มีเหตุผล

## Build and verification

- ทุก slice ต้องมี focused test ระหว่างทำ และ final gate ตามความเสี่ยง
- failure ต้องเก็บ first useful failure/fingerprint; ห้าม rerun จนบัง flaky failure
- docs/examples/schema ต้องตรวจ drift กับ public headers
- `.agent/skills` ต้องผ่าน `aengine.architecture.agent_skills`
- `.agent/code-map/current` ต้องผ่าน `aengine.architecture.ai_code_map`
- module contract, dependency cycle, public API ownership และ OOP policy guards ต้องผ่านก่อน completion

## Shader rules

- shader authoring ใช้ textual shader language; ไม่สร้าง shader-node subsystem
- first backend contract คือ Vulkan GLSL 450 -> SPIR-V target Vulkan 1.2
- reusable helper เป็น pure function module ไม่มี descriptor/push constant/hidden global
- host ABI ต้องตรวจด้วย reflection, generated bindings และ focused GPU/runtime tests
- ห้าม copy shader/pipeline boilerplateราย effect; ใช้ library/pipeline helperกลาง

## UI rules

- A-Engine เป็นเจ้าของ High-level UI API, UI host lifecycle, editor UI infrastructure และ canonical Dear ImGui backend รุ่นแรก
- APaint เป็นเจ้าของ product panel/dialog/workspace content, view model, controller, defaults, theme values และ presentation policy
- public boundary ห้าม expose ImGui/SDL/Vulkan native ownership
- UI อ่าน immutable snapshotและส่ง intentลง canonical controller/workflow route ห้าม mutate domain/GPU ownerตรง

## Migration and donor rules

- A-Engine เป็นเจ้าของ reusable mechanism/backend-neutral contract; APaint เป็นเจ้าของ product policy/presets/workspace/`.apaint` semantics
- ห้าม copy APaint manager tree หรือ link APaint product targetเข้า `aengine_*`
- ก่อนย้าย donor code ต้องมี provenance/license, current call-path, consumer inventory, source owner, target owner, contract, verification และ deletion condition
- ย้ายทีละ route ผ่าน adapter; legacy/new routeต้องไม่อยู่คู่กันหลัง consumerเป็นศูนย์
- ห้าม duplicate active state/ownership ระหว่าง APaint กับ A-Engine
- รักษางานผู้ใช้ใน dirty worktree และห้าม destructive actionนอก targetที่สั่งชัดเจน

## KnowMan

- project ของ workspace นี้คือ AEngine `project_id=27`
- เริ่มงานด้วย `nm_session` สำหรับ workspace นี้และ `nm(context_fetch)` ก่อน task ย่อยเมื่อเครื่องมือมีให้ใช้
- หลังจบงานบันทึก `nm(experience_log)` และ `nm(skill_upsert)` เมื่อมี pattern ใหม่เมื่อเครื่องมือมีให้ใช้
- items ที่ AI สร้างอาจเป็น pending และต้องให้ผู้ใช้ approve ใน KnowMan dashboard
