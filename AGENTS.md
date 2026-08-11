# A-Engine Agent Instructions

## ภาษา

- คุยกับผู้ใช้เป็นภาษาไทย
- ชื่อ API, symbol, file และ technical terms ใช้ภาษาอังกฤษตามจริง
- PowerShell ใช้ `;` แทน `&&`

## สถานะโครงการ

- A-Engine เป็น open-source C++ 3D engine สำหรับ game และ 3D application
- repository นี้ถูกสร้างใหม่แบบ docs-first เมื่อ 2026-08-11
- canonical architecture คือ `docs/AENGINE_API_ARCHITECTURE.md`
- A-Engine/APaint ownership contract คือ `docs/AENGINE_APAINT_BOUNDARY.md`
- High-level UI/ImGui contract คือ `docs/AENGINE_UI_ARCHITECTURE.md`
- code shape/AI reviewability contract คือ `docs/CODE_SHAPE_POLICY.md`
- project-specific AI skills อยู่ที่ `.agent/skills/`
- generated AI navigation map อยู่ที่ `.agent/code-map/current/`
- research evidence คือ `docs/RESEARCH_BRIEF.md`
- APaint เป็น donor/reference consumer ไม่ใช่ dependency ของ A-Engine

## Architecture Pre-Code Gate

ก่อนสร้างหรือแก้ production code:

1. อ่าน canonical architecture ทั้งไฟล์และ section ของ phase ปัจจุบัน; งาน APaint,
   donor หรือ migration ต้องอ่าน `docs/AENGINE_APAINT_BOUNDARY.md` เพิ่ม และงาน UI,
   editor, panel, viewport widget หรือ Dear ImGui ต้องอ่าน
   `docs/AENGINE_UI_ARCHITECTURE.md`
2. ระบุ current phase, user outcome, owner/API, dependency direction, lifetime/state,
   invariants, exact files, tests และ stop line
3. รักษา MIT license ของ repository และห้ามเดา platform/toolchain/ECS หรือ license
   compatibility ของ donor/third-party code
4. สร้าง vertical slice ที่มี consumer จริง ห้าม scaffold ทุก module ล่วงหน้า
5. public API ห้าม expose Vulkan, SDL, ImGui, ECS implementation pointer หรือ global
   service locator
6. อ่าน `docs/CODE_SHAPE_POLICY.md` และรักษา source-shape budgets/semantic split rules
   ทุกครั้งที่เพิ่ม class, public header, implementation owner หรือ composition root
7. เลือกอ่าน skill ที่เกี่ยวข้องจาก `.agent/skills/README.md`; อย่าโหลดทุก skillโดยไม่จำเป็น
8. อ่าน `.agent/code-map/current/AI_CONTEXT.md` และ `INDEX.json` แล้วเปิดเฉพาะ module map
   ที่เกี่ยวข้องก่อนค้น implementation ทั้ง repository

ถ้า docs ขัดกับ source หรือไม่มี proof ที่วัด behavior ได้ ให้หยุด production change และ
ทำ docs/diagnostic/characterization slice ก่อน

## AI navigation / code map

- `MODULE.json` ใต้ `engine/*` และ `tools/*` คือ declared ownership intent ของ production target
- `.agent/code-map/current/` เป็น generated observed map สำหรับ navigation ไม่ใช่ authority
  เหนือ source/canonical docs
- production target `aengine_*` ใหม่ต้องมี `MODULE.json` ใน slice เดียวกัน
- ถ้า map ขัดกับ source ให้แก้ source/manifest/generator ตาม owner ที่ถูกต้อง ห้ามแก้ generated
  `current/*.json` หรือ `AI_CONTEXT.md` ด้วยมือ
- `build.bat` จะ fingerprint source/CMake/tests/manifests และ regenerate map เมื่อ input เปลี่ยน
  แต่จะเขียน generated file เฉพาะเมื่อโครงสร้างที่ AI ต้องรู้เปลี่ยนจริง
- generated map ที่เปลี่ยนต้อง commit พร้อม production change ใน slice เดียวกัน
- เริ่มอ่านจาก `INDEX.json` แล้วโหลด `modules/<target>.json` เฉพาะ target ที่เกี่ยวข้อง
  เพื่อลด context และหลีกเลี่ยงการ grep ทั้ง repository โดยไม่จำเป็น

## Skill routing

Skills เป็น procedural overlay เท่านั้นและห้าม override canonical docs/source-of-truth:

- module boundary, ownership, lifecycle, composition root, new subsystem/refactor ->
  `.agent/skills/software-architecture/SKILL.md`
- public C++ API/header, Result/Error, handle, service contract, ABI-facing value ->
  `.agent/skills/cpp-api-contracts/SKILL.md`
- build/test/CI, failure triage, evidence/completion claim ->
  `.agent/skills/validation-evidence/SKILL.md`
- dependency/version/license/provenance/SBOM ->
  `.agent/skills/third-party-governance/SKILL.md`
- Vulkan/GPU/shader/pipeline/backend -> `.agent/skills/vulkan-backend/SKILL.md`
- UI/editor/ImGui/panel/menu/viewport -> `.agent/skills/ui-architecture/SKILL.md`
- APaint donor/reference/migration -> `.agent/skills/apaint-migration/SKILL.md`

งานที่ข้ามหลาย concern ให้อ่านเฉพาะ skill ที่ข้ามจริง และทุกงานที่อ้างว่าเสร็จต้องใช้
`validation-evidence` ตรวจ completion evidence ค่ะ

## Code shape / AI reviewability

- ใช้ Single Responsibility และ Composition เป็น default; ห้าม God class หรือ manager
  กลางที่ถือ mutable state ของหลาย subsystem
- แยก state owner, orchestration, policy/strategy, backend adapter, serialization และ UI
  ออกจากกันเมื่อมีเหตุผลเปลี่ยนแปลงคนละอย่าง
- composition root มีหน้าที่ wiring เท่านั้น ห้ามซ่อน domain behavior
- facade ต้อง delegate ไป service owner และห้ามสร้าง duplicate state
- public header ควรมี primary contract เดียวกับ value types ที่เกี่ยวข้องโดยตรง
- ห้ามสร้าง dumping-ground file เช่น `Common`, `Misc`, `Everything` หรือ unscoped `Utils`
- source file ถึง limit ใน `docs/CODE_SHAPE_POLICY.md` ต้อง split ก่อนเพิ่ม behavior; limit
  เป็น hard stop ไม่ใช่เป้าหมาย
- `aengine.architecture.source_shape` ต้องผ่านทุก slice; exception ต้องมี owner,
  rationale, temporary budget และ removal/review phase แบบ explicit

## Canonical build entrypoint

- agent และคนต้องเริ่ม build/test จาก repository root ด้วย `build.bat` เท่านั้น
- normal workflow ห้ามเรียก `cmake`, `ninja`, `ctest` หรือ AI-map PowerShell scripts โดยตรง
- exception มีได้เฉพาะตอน debug/แก้ `build.bat`, CMake integration หรือ generator เอง;
  ต้องระบุเหตุผลและจบ validation ด้วย `build.bat` อีกครั้ง
- `build.bat` default = AI-map update + Debug build/test + Release build/test
- focused commands ที่อนุญาตผ่าน entrypoint เดียวกัน: `build.bat debug`,
  `build.bat release`, `build.bat test <regex>`, `build.bat map`
- `build.bat` และ Ninja ทำ incremental work; ห้าม clean/rebuild ทั้งหมดโดยไม่มีเหตุผล

## Build and verification

- Phase 0 ยังไม่มี production source จึงห้ามอ้างว่า build/runtime ผ่าน
- เมื่อ Phase 1 อนุมัติแล้ว canonical configure/build/test route คือ `build.bat` เท่านั้น
- ทุก slice ต้องมี focused test ระหว่างทำ และ final gate ตามความเสี่ยง
- failure ต้องเก็บ structured evidence/fingerprint; ห้าม rerun จนบัง flaky failure
- docs/examples/schema ต้องตรวจ drift กับ public headers เมื่อ source เริ่มมีจริง
- `.agent/skills` ต้องผ่าน `aengine.architecture.agent_skills`; skill แต่ละไฟล์ต้อง focused
  และไม่เกิน budget ที่ guard กำหนด
- `.agent/code-map/current` ต้องผ่าน `aengine.architecture.ai_code_map`; CI ต้อง fail
  เมื่อ source/manifests กับ committed AI navigation map drift กัน

## Shader rules

- shader authoring ใช้ textual shader language; ไม่สร้าง shader-node subsystem
- first backend contract คือ Vulkan GLSL 450 -> SPIR-V target Vulkan 1.2
- reusable helper เป็น pure function module ไม่มี descriptor/push constant/hidden global
- host ABI ต้องตรวจด้วย reflection, generated bindings และ focused GPU/runtime tests
- ห้าม copy shader/pipeline boilerplateราย effect; ใช้ library/pipeline helperกลาง

## UI rules

- A-Engine เป็นเจ้าของ High-level UI API, UI host lifecycle, editor UI infrastructure
  และ canonical Dear ImGui backend รุ่นแรก
- APaint เป็นเจ้าของ product panel/dialog/workspace content, view model, controller,
  defaults, theme values และ presentation policy โดยสร้างผ่าน A-Engine UI API
- public A-Engine/APaint boundary ห้าม expose `ImGuiContext`, `ImDrawList`, `ImTextureID`,
  SDL pointer, Vulkan handle หรือ UI descriptor ownership
- Dear ImGui typesอยู่ใน private `aengine_ui_imgui` implementation; APaint ห้ามถือหรือ
  ทำลาย UI renderer resourcesใน routeที่ migrateแล้ว
- ใช้ semantic High-level APIเป็น default และเพิ่ม limited immediate primitivesตาม
  consumerจริง ห้ามสร้าง wrapper 1:1 ครบทุก Dear ImGui function
- UI อ่าน immutable snapshotและส่ง user intentไป controller/workflow ห้าม mutate
  document/layer/paint/GPU ownerตรงหรือเก็บ persistent domain stateสำเนาคู่แข่ง
- panel/menu/shortcut commandต้อง dispatchลง canonical command/workflow routeเดียวกัน
- direct ImGui routeชั่วคราวต้องมี caller inventory, diagnostics, parity proof และ
  deletion condition ห้ามคงคู่กับ A-Engine UI routeหลัง consumerเป็นศูนย์

## Migration and donor rules

- A-Engine เป็นเจ้าของ reusable mechanism/backend-neutral contract; APaint เป็นเจ้าของ
  product UI content/composition, policy, presets, workspace และ `.apaint` semantics
- ห้าม copy APaint manager tree หรือ link APaint product targetเข้า `aengine_*`
- ก่อนย้าย donor code ต้องมี provenance/license, current call-path, consumer inventory,
  source owner, target owner/placement, contract, verification และ deletion condition
- ถ้ายังแยก product policy ออกจาก mechanismไม่ได้ ให้คง codeไว้ใน APaint และทำ
  characterization sliceก่อน ห้ามย้ายเพียงเพื่อจัด directoryให้ดูสะอาด
- ย้ายทีละ route ผ่าน adapter; legacy/new routeต้องไม่อยู่คู่กันหลัง consumerเป็นศูนย์
- ห้ามสร้าง duplicate active state/ownership ระหว่าง APaint กับ A-Engine
- รักษางานผู้ใช้ใน dirty worktree และห้าม destructive actionนอก targetที่สั่งชัดเจน

## KnowMan

- project ของ workspace นี้คือ AEngine `project_id=27`
- เริ่มงานด้วย `nm_session` สำหรับ workspace นี้และ `nm(context_fetch)` ก่อน task ย่อย
- หลังจบงานบันทึก `nm(experience_log)` และ `nm(skill_upsert)` เมื่อมี pattern ใหม่
- items ที่ AI สร้างอาจเป็น pending และต้องให้ผู้ใช้ approve ใน KnowMan dashboard
