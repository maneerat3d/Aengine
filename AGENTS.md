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
- research evidence คือ `docs/RESEARCH_BRIEF.md`
- APaint เป็น donor/reference consumer ไม่ใช่ dependency ของ A-Engine

## Architecture Pre-Code Gate

ก่อนสร้างหรือแก้ production code:

1. อ่าน canonical architecture ทั้งไฟล์และ section ของ phase ปัจจุบัน; งาน APaint,
   donor หรือ migration ต้องอ่าน `docs/AENGINE_APAINT_BOUNDARY.md` เพิ่ม
2. ระบุ current phase, user outcome, owner/API, dependency direction, lifetime/state,
   invariants, exact files, tests และ stop line
3. รักษา MIT license ของ repository และห้ามเดา platform/toolchain/ECS หรือ license
   compatibility ของ donor/third-party code
4. สร้าง vertical slice ที่มี consumer จริง ห้าม scaffold ทุก module ล่วงหน้า
5. public API ห้าม expose Vulkan, SDL, ImGui, ECS implementation pointer หรือ global
   service locator

ถ้า docs ขัดกับ source หรือไม่มี proof ที่วัด behavior ได้ ให้หยุด production change และ
ทำ docs/diagnostic/characterization slice ก่อน

## Build and verification

- Phase 0 ยังไม่มี production source จึงห้ามอ้างว่า build/runtime ผ่าน
- เมื่อ Phase 1 อนุมัติแล้ว ต้องระบุ canonical configure/build/test commands ใน
  README และ CI ก่อนเพิ่ม target ที่สอง
- ทุก slice ต้องมี focused test ระหว่างทำ และ final gate ตามความเสี่ยง
- failure ต้องเก็บ structured evidence/fingerprint; ห้าม rerun จนบัง flaky failure
- docs/examples/schema ต้องตรวจ drift กับ public headers เมื่อ source เริ่มมีจริง

## Shader rules

- shader authoring ใช้ textual shader language; ไม่สร้าง shader-node subsystem
- first backend contract คือ Vulkan GLSL 450 -> SPIR-V target Vulkan 1.2
- reusable helper เป็น pure function module ไม่มี descriptor/push constant/hidden global
- host ABI ต้องตรวจด้วย reflection, generated bindings และ focused GPU/runtime tests
- ห้าม copy shader/pipeline boilerplateราย effect; ใช้ library/pipeline helperกลาง

## Migration and donor rules

- A-Engine เป็นเจ้าของ reusable mechanism/backend-neutral contract; APaint เป็นเจ้าของ
  product UI, policy, presets, workspace และ `.apaint` project semantics
- ห้าม copy APaint manager tree หรือ link APaint product targetเข้า `aengine_*`
- ก่อนย้าย donor code ต้องมี provenance/license, current call-path, consumer inventory,
  source owner, target owner/placement, contract, verification และ deletion condition
- ถ้ายังแยก product policy ออกจาก mechanismไม่ได้ ให้คง codeไว้ใน APaint และทำ
  characterization sliceก่อน ห้ามย้ายเพียงเพื่อจัด directoryให้ดูสะอาด
- ย้ายทีละ route ผ่าน adapter; legacy/new route ต้องไม่อยู่คู่กันหลัง consumerเป็นศูนย์
- ห้ามสร้าง duplicate active state/ownership ระหว่าง APaint กับ A-Engine
- รักษางานผู้ใช้ใน dirty worktree และห้าม destructive actionนอก targetที่สั่งชัดเจน

## KnowMan

- project ของ workspace นี้คือ AEngine `project_id=27`
- เริ่มงานด้วย `nm_session` สำหรับ workspace นี้และ `nm(context_fetch)` ก่อน task ย่อย
- หลังจบงานบันทึก `nm(experience_log)` และ `nm(skill_upsert)` เมื่อมี pattern ใหม่
- items ที่ AI สร้างอาจเป็น pending และต้องให้ผู้ใช้ approve ใน KnowMan dashboard
