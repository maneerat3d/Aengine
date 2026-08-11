# A-Engine API Architecture

Status: **canonical target / docs-first / not fully implemented**

Architecture ID: `AE-APPLICATION-ENGINE-API`

Repository rebuilt and document reviewed: 2026-08-11

Scope: Low-level Engine API, High-level Workflow API, C++/C# SDK และ Add-on SDK/Host

เอกสารนี้กำหนดสถาปัตยกรรมเป้าหมายของ **A-Engine**: open-source C++ 3D engine
สำหรับสร้างทั้ง game และ application เช่น model editor, sculpting tool, texture
painting tool, animation tool และ custom DCC application โดยออกแบบ public API,
diagnostics และ tooling ให้ AI และคนสามารถพัฒนา application/add-on ได้ง่าย

APaint เป็น donor/reference application และ migration consumer สำคัญ แต่ไม่ใช่ owner
หรือ dependency ของ A-Engine API ส่วน repository AEngine ใหม่เริ่มแบบ docs-first และ
ยังไม่มี production source จนกว่า Phase 0 จะผ่าน

เอกสารนี้ไม่ใช่หลักฐานว่า source ปัจจุบัน implement target architecture ครบแล้ว
สถานะจริงต้องยืนยันจาก source/header, dependency guard, focused tests และ runtime
evidence ของ working tree ปัจจุบันเสมอ

## 1. Decision

ใช้ **modular monolith + API-first + ports/adapters + strangler migration** ใน
repository AEngine ใหม่ โดยทยอยย้ายเฉพาะ behavior ที่พิสูจน์ owner/contract/consumer
ได้จาก donor ห้าม copy legacy repository ทั้งก้อน และไม่สร้าง engine ทุก moduleให้ครบ
ก่อนมี consumer จริง

โครงสร้างมีสามชั้นหลัก:

1. **Low-level Engine API** — typed identity, document/scene/layer/paint contracts,
   commands, jobs และ backend-neutral render intent
2. **High-level Workflow API** — use case ที่ game/app, editor UI, automation และ add-on
   เรียกใช้ง่าย เช่น paint stroke, layer operation, open/save/export
3. **Add-on SDK/Host** — version negotiation, manifest, lifecycle, capability,
   extension registration และ fault boundary

Renderer ใช้ **text-based shader language + reusable shader function library**
ไม่ใช้ shader node graph เป็น authoring/source-of-truth ของ engine ใหม่

ภาษาแบ่งตาม boundary ไม่แบ่ง behavior เป็นคนละชุด: core/low-level/workflow canonical
implementation ใช้ C++; public binary boundary ใช้ stable C ABI; C++ และ C# เป็น
ergonomic SDK façades เหนือ workflow เดียวกัน C# เป็น optional managed layer ไม่ใช่
engine core หรือ implementation route คู่แข่ง

ทุก executable เช่น APaint, model editor, sculpt application หรือ game เป็น product
shell ที่ประกอบ service implementations เข้าด้วยกัน ห้ามเป็นเจ้าของ domain behavior
ที่ควรอยู่ใน engine หรือ workflow

### 1.1 สิ่งที่เรียกว่า Engine ในเอกสารนี้

A-Engine เป็น modular 3D engine สำหรับทั้ง game และ application โดยมี foundation
ร่วมกันสำหรับ application lifecycle, scene/world, asset, renderer/shader, input,
commands, jobs, diagnostics และ add-ons แล้วเปิด feature packs ตามชนิดผลิตภัณฑ์:

- DCC/editor: document, undo/redo, viewport, gizmo, selection, import/export
- Paint/sculpt/model: paint, layer, geometry editing, mesh processing, brush/session
- Game/runtime: world update, component/system, animation, physics, audio และ gameplay

feature pack ไม่ได้แปลว่าต้อง implement ทุกระบบพร้อมกัน แต่ architecture ต้องไม่ผูก
foundation กับ APaint หรือ editor UI จน game/runtime นำไปใช้ไม่ได้

### 1.2 Clean repository and APaint donor boundary

วันที่ 2026-08-11 prototype AEngine เดิมถูกนำออกตามคำสั่งเจ้าของโครงการ และสร้าง
`C:\Users\manee\Code\AP4\AEngine` เป็น Git repository ใหม่บน branch `main` แบบ
docs-first สถานะเริ่มต้นจึงมีเพียง project contract/architecture/research ไม่มี CMake,
production source หรือ compatibility burden จาก prototype เดิม

APaint ใช้เป็นหลักฐาน donor สำหรับ behavior ที่ผ่านการตรวจ source/call path เท่านั้น
การนำกลับมาใช้ต้องย้ายเป็น A-Engine-owned module หรือเชื่อมผ่าน explicit adapter และ
ต้องมี license/provenance ledger ห้ามให้ target `aengine_*` include/link APaint product,
manager aggregate หรือ path แบบ relative source borrowing

### 1.3 เหตุผลที่ไม่ใช้ `apaint_core` เดิมเป็น Low-level API

target `apaint_core` ปัจจุบันเป็น legacy application aggregate และ public-link กับ
ImGui, SDL, volk, Vulkan Memory Allocator, AppMan, RenderMan, UI-related dependencies
และ managers จำนวนมาก จึงไม่ใช่ dependency-free core ตามความหมายของเอกสารนี้

ระหว่าง migration:

- `apaint_core` เดิมคงทำงานเป็น compatibility aggregate
- A-Engine targets ใหม่ใช้ชื่อ `aengine_*` เพื่อไม่อ้างความสะอาดที่ยังไม่มีจริง
- consumer ต้องย้ายออกทีละ route
- ลบหรือลด `apaint_core` ได้เมื่อ consumer inventory เป็นศูนย์เท่านั้น

### 1.4 Open-source and AI-first mission

A-Engine source repository ใช้ **MIT License** ตาม `LICENSE` ซึ่งอยู่ใน initial remote
commit `f04f069` ส่วน third-party dependency, donor code, asset และ generated artifact
ทุกชิ้นยังต้องมี provenance/license ledger และ compatibility audit แยก ห้ามถือว่า MIT
ของ repositoryทำให้ donor codeนำเข้าได้อัตโนมัติ

AI-first หมายถึง API และ tooling มีข้อมูลที่ AI อ่าน/ตรวจ/เรียกได้ ไม่ใช่ให้ AI bypass
architecture:

- API schema, capabilities, errors และ lifecycle เป็น machine-readable
- operation ทุกชนิดมี stable ID, request/result schema และ deterministic trace
- headless runner/control surface ใช้ workflowเดียวกับ GUI
- generated API docs/examples compileและ testได้
- repository code map, ownership map และ dependency guard updateพร้อม source
- diagnostics ระบุ owner, inputs, state transition, resource/job และ evidence path
- scaffolder สร้าง app/add-on/shader templateที่ buildได้และไม่มี hidden singleton
- AI ต้องผ่าน contract/focused testsเหมือน contributorคนอื่น

## 2. Authority and related contracts

ลำดับ authority เมื่อข้อมูลขัดกัน:

1. เอกสารนี้สำหรับ approved target boundaries/API/migration order
2. source/header และ production call path หลัง phaseนั้น implementแล้ว
3. focused tests, dependency/ABI guards และ runtime evidence
4. feature-specific normative contracts เช่น APaint paint pipeline
5. audit, dependency map, donor notes และ legacy API references

ถ้า implementation ขัดกับ approved target contract ให้หยุด sliceและแก้ contractหรือ
implementationอย่างชัดเจน ห้ามเปลี่ยนเอกสารย้อนหลังเพื่อประกาศว่า bugเป็น behaviorที่ถูกต้อง

เอกสารที่ต้องอ่านร่วมกันตาม scope:

- `docs/RESEARCH_BRIEF.md`
- APaint adoption scope: `../../Apaint/.agent/workflows/paint-pipeline.md`
- APaint Normal Paint: `../../Apaint/docs/architecture/TEXTURE_BRUSH_CONTRACT.md`
- APaint current/migration evidence: `../../Apaint/docs/architecture/ARCHITECTURE_V2.md`
  และ `ARCHITECTURE_V2_MIGRATION.md`

feature-specific contract มีอำนาจเหนือ generic convenience API เสมอ เช่น
Normal Paint ต้องใช้ texture tip, frozen projection semantics และ preview/commit
footprint เดียวกัน แม้ High-level API จะซ่อนรายละเอียดจาก caller

## 3. User and developer outcomes

เมื่อ architecture นี้เสร็จ ผู้พัฒนา game, application หรือ add-on ควรทำสิ่งเหล่านี้ได้
โดยไม่รู้จัก manager ภายในหรือ Vulkan:

- เปิด document, import model, query scene และเลือก object/material
- สร้าง world/entity/component/system และกำหนด deterministic update phases
- สร้าง runtime game loop หรือ editor loop จาก application façade เดียวกัน
- สร้าง/ลบ/ย้าย layer ผ่าน undoable workflow
- เริ่ม/append/commit/cancel stroke ด้วย contract เดียวกับ APaint UI
- อ่านภาพ composite หรือขอ export ผ่าน asynchronous job
- ลงทะเบียน command, menu, panel, importer, exporter หรือ paint tool add-on
- ตรวจ capability ก่อนใช้ feature และรับ structured error เมื่อระบบไม่พร้อม
- ทดสอบ workflow ด้วย fake/headless service โดยไม่เปิด APaint window หรือ GPU
- replay operation trace เดิมกับ fake backend และ production Vulkan backend
- สร้าง application ด้วย C++ facade แบบ `App::Init()`, `Run()`, `Save()`,
  `Quit()` และ `View3D::Update()` โดยไม่ต้องรู้ service wiring ภายใน
- สร้าง application/editor tool/gameplay/add-on ด้วย C# façade ที่มี semantics,
  operation ID และผลลัพธ์ตรงกับ C++ workflow โดยไม่เรียก native backendตรง
- เพิ่ม Noise, Color Grading หรือ shader helper ใหม่เป็น text function module แล้ว
  reuse จากหลาย shader โดยไม่สร้าง descriptor/pipeline boilerplate ซ้ำ

## 4. Current-state evidence and reusable owners

| พื้นที่ | Current fact | Target action |
| --- | --- | --- |
| AEngine repository | clean docs-first repository; ยังไม่มี production target | สร้าง targetแรกเฉพาะหลัง Phase 0 และใช้ small reference appเป็น first consumer |
| UI paint | APaint `View2DPaintController.cpp` ยังเป็น compatibility seam ขนาดใหญ่มาก | ลดให้เหลือ input adapter/orchestrator แล้วให้ workflow เป็น owner ของ use case |
| Stroke lifecycle | `PaintStrokeSession` มี typed state และ diagnostics แล้ว | ขยาย/ห่อด้วย `IPaintService`; ห้ามสร้าง session semantics คู่แข่ง |
| Projection | `PaintStrokeProjectionPlan`, planner และ footprint มี production caller | ใช้เป็น source of truth ของ paint low-level API |
| Channel | `PaintChannelDescriptor` แยก logical channel จาก physical storage แล้ว | ใช้ descriptor เดิม ไม่สร้าง channel enum/registry ซ้ำ |
| Commands | `CommandManager` ห่อ ComMan และ persistent layer routes หลายส่วนเป็น command แล้ว | ย้ายเป็น per-document command service; ตัด singleton access จาก public API |
| Render | RenderMan มี `IRenderDevice`, `BackendHandle` และ opaque paint history transaction บางส่วน | ขยายเป็น intent/resource/job API; เก็บ native handle ใน implementation |
| Shader | มี shader-language files 142 ไฟล์ (`.comp` 35, `.frag` 21, `.vert` 17, `.glsl` 69) และ shared includes อยู่แล้ว | รวม pure helper เป็น versioned shader library และเพิ่ม include/reflection/cache/ABI tooling |
| Shader compiler | APaint donor ShaderMan พิสูจน์ว่า compile GLSL เป็น SPIR-V ได้ แต่ยังไม่มี canonical include graph, reflection contract และ content cache ครบชุด | ใช้เป็น behavioral evidence แล้วสร้าง A-Engine-owned toolchain/adapter; ห้าม link donor manager |
| Pipeline | PipelineMan มี per-pipeline classes แต่ `PipelineBase` ยังรับ/คืน native Vulkan types | สร้าง backend-neutral program/pipeline/effect helpers แล้ว migrate หนึ่ง pipeline ต่อ slice |
| Composite | `LayerCompositePlan` ยังรับ `VkImageView` ใน public records | ย้ายทีละ consumerไป opaque resource ID โดยรักษา composite semantics |
| App | APaint `Application`/AppMan และ AEngine `main.cpp` มี startup/frame/shutdown seams | ย้าย contractกลางไป A-Engine App/Platform modules; productเป็น composition root |

ข้อสรุป: target architecture ต้องต่อยอด owner เหล่านี้ ไม่สร้าง `EngineManager`,
`APaintApi` หรือ compositor/stroke pipeline ชุดใหม่ครอบทุกอย่าง

## 5. Architecture layers

```text
Third-party Add-ons      Games/Applications      Editors/APaint      Automation/AI
         |                       |                    |                 |
         +-----------------------+--------------------+-----------------+
                                 |
                    High-level Workflow API
        Paint | Layer | Scene | Project | Export | Viewport
                                 |
                 Commands / Transactions / Jobs
                                 |
          Low-level Domain and Render Intent APIs
 Foundation | Document | Scene | Layer | Paint | Asset | Render
                                 |
                     Backend Implementations
 Existing APaint/AEngine adapters | Vulkan | Asset/Project IO | Platform
                                 |
                       App composition root
```

Dependency ลงได้ทางเดียวจาก consumer ไป contract และจาก composition root ไป
implementation ห้าม domain ย้อนกลับไปหา UI, product shell หรือ add-on host

## 6. Target modules and dependency rules

ชื่อ target ต่อไปนี้เป็น target architecture แต่ให้สร้างทีละ target เมื่อมี production
consumer ใน migration slice เดียวกันเท่านั้น

| Target | Responsibility | Allowed dependencies | Forbidden |
| --- | --- | --- | --- |
| `aengine_foundation` | IDs, handles, Result/Error, version, capabilities, spans, time/operation metadata | C++ standard library และ math value typesที่อนุมัติ | Vulkan, SDL, ImGui, singleton managers, file dialogs |
| `aengine_platform` | process/window/input/time/filesystem abstraction และ app runner | foundation, platform adaptersแบบ private | scene/game/editor/domain behavior |
| `aengine_world` | entities/components/systems, hierarchy, transform และ deterministic update phases | foundation; Flecs adapterได้แบบ private | render handles, editor UI, product-specific component |
| `aengine_scene` | scene/object/mesh/material/camera/light metadata และ snapshots | foundation, world, asset IDs | GPU resource, editor UI, backend headers |
| `aengine_commands` | mutation gateway, transaction, undo/redo และ gesture coalescing | foundation, scene/domain contracts | raw GPU handles, UI, global singleton access |
| `aengine_render_api` | texture/render/readback/compute intent, opaque resources, queue tickets | foundation และ scene value typesที่จำเป็น | `Vk*`, VMA, ImGui, document mutation policy |
| `aengine_shader_library` | reusable GLSL function modules เช่น math/noise/color/blend/PBR/paint | shader language only | descriptor bindings, push constants, entry point, backend lifetime |
| `aengine_shader` | source/include resolution, compile, reflection, ABI generation, variants และ cache | foundation, ShaderMan compiler implementationแบบ private | UI, document mutation, raw Vulkanใน public API, node graph |
| `aengine_renderer` | pipeline/effect/view orchestration เหนือ render intent + shader contracts | foundation, scene snapshots, render API, engine shader | manager singleton, product UI, direct document mutation |
| `aengine_assets` | asset identity, URI/resolver, import/cache/dependency/package contracts | foundation, scene schemas, IO librariesแบบ private | product UI และ mutable world accessโดยพลการ |
| `aengine_workflows` | user-facing game/app/editor use cases และ orchestration | public APIs ของ engine modules | backend implementation, managers, `Vk*`, ImGui |
| `aengine_addon_sdk` | versioned add-on ABI และ C++ convenience wrapper | foundation และ versioned workflow interfaces | internal headers, STL across binary ABI, native backend |
| `aengine_addon_host` | discovery, validation, load/activate/deactivate/unload, capability grants | addon SDK, workflow interfaces, platform loader | domain policy, paint math, hidden mutation |
| `aengine_vulkan_backend` | Vulkan device/resources/pipelines/sync/readback และ render API implementation | render API, shader contracts, platform bootstrap | UI decisions, command history policy, scene ownership |
| `aengine_editor` | reusable viewport, docking, inspector, selection, gizmo และ command UI | workflows, query snapshots, display handles | raw managers, direct model writes, native GPU handles |
| `aengine_animation` | skeleton, clips, blending, skinning intent | foundation, scene; ozz adapterแบบ private | UI/product policy |
| `aengine_physics` | collision/rigid-body/queries contract และ backend adapter | foundation, world/scene | renderer/UI ownership |
| `aengine_audio` | clip/source/listener/mixer intent และ backend adapter | foundation, world/scene | gameplay policy |
| `aengine_paint` | reusable typed stroke/projection/paint contracts | foundation, scene, commands, render API | APaint UI และ native backend |
| `aengine_geometry` | mesh edit, topology, sculpt/brush geometry transactions | foundation, scene, commands, render intent | editor widget state |
| `aengine_viewer` | first sample/host composition root | public APIs และ concrete implementations | duplicated business logic |
| `APaint` และ reference apps | productsสร้างบน A-Engine feature packs | public SDK/workflows | include A-Engine private/backend implementation |

### 6.1 Dependency enforcement

ทุก target ใหม่ต้องมี static rules ตั้งแต่วันแรก:

- public headers ของ foundation/domain/commands/workflows/addon SDK ห้าม include
  Vulkan, VMA, volk, SDL หรือ ImGui
- `aengine_*` ห้าม link `apaint_core` legacy aggregateหรือ APaint product target
- UI, automation และ add-on ห้าม include manager implementation headers
- backend implementationห้าม include UI หรือ command concrete classes
- shader library modulesห้าม declare descriptor, push constant หรือ `main()`
- engine shader/renderer public headersห้าม depend on GraphMan/NodeMan/CompileMan
- exception ต้องมี owner, rationale, consumer inventory และ removal phase
- no-new-debt guard ต้อง fail เมื่อเพิ่ม dependency หรือ native symbol ใหม่

### 6.2 Repository layout

```text
AEngine/
  CMakeLists.txt
  LICENSE                       # MIT; third-party noticesแยกตาม provenance
  README.md
  cmake/
  docs/
    AENGINE_API_ARCHITECTURE.md
    RESEARCH_BRIEF.md
    api/
  engine/
    foundation/
    platform/
    world/
    scene/
    assets/
    commands/
    render_api/
    shader/
    renderer/
    workflows/
    addon_sdk/
    addon_host/
  features/
    editor/
    geometry/
    paint/
    animation/
    physics/
    audio/
    gameplay/
  backends/
    vulkan/
    platform_windows/
  apps/
    viewer/
    editor/
    tests/
  sdk/
    include/AEngine/
    schemas/
    templates/
  tests/
    contract/
    integration/
    compatibility/
  tools/
```

กฎ:

- `engine/` buildได้โดยไม่ include `apps/`, APaint หรือ product repository
- `features/` เป็น optional packs; foundation/runtimeขั้นต่ำไม่ link editor/paint/sculpt
- `backends/` implement ports ใน engine และไม่มี product behavior
- `apps/` เป็น composition examples/reference applications ไม่ใช่ที่เก็บ reusable logic
- `sdk/` มีเฉพาะ public/versioned artifacts ห้าม symlink internal headers
- อย่าสร้าง directory/targetล่วงหน้าทั้งหมด; layout นี้เป็น routing contractและสร้าง
  pathเมื่อ phaseนั้นมี consumerจริง

## 7. Low-level Engine API

Low-level API ให้ primitive ที่ถูกต้องและประกอบกันได้ แต่ไม่บังคับ caller เข้าใจ
implementation ภายใน API ทุกชุดต้องมี owner, explicit lifetime, explicit error และ
diagnostic identity

### 7.1 Strong opaque handles

ห้ามใช้ raw pointer, array index หรือ `uint32_t layerId` ที่ข้าม subsystem โดยไม่มี
ชนิดกำกับ เป้าหมาย C++ API ใช้ generational handle:

```cpp
template <class Tag>
struct Handle {
  uint32_t slot = 0;
  uint32_t generation = 0;

  bool IsValid() const;
};

using DocumentHandle = Handle<DocumentTag>;
using SceneObjectHandle = Handle<SceneObjectTag>;
using MaterialHandle = Handle<MaterialTag>;
using LayerHandle = Handle<LayerTag>;
using TextureHandle = Handle<TextureTag>;
using StrokeHandle = Handle<StrokeTag>;
using JobHandle = Handle<JobTag>;
using SubscriptionHandle = Handle<SubscriptionTag>;
```

กฎ:

- owner เท่านั้นที่สร้าง/ทำลาย handle
- stale generation ต้องได้ `ErrorCode::StaleHandle` ไม่ dereference memory เก่า
- handle เป็น identity ไม่ใช่ resource ownership
- native add-on ABI encode เป็น fixed-width value; ห้าม expose template layout
- serialization ใช้ persistent stable ID แยกจาก runtime handle

### 7.2 Result and error contract

public operation ห้ามคืน `bool` ที่ไม่มีสาเหตุ และห้ามโยน exception ข้าม module/add-on
boundary

```cpp
enum class ErrorCode : uint32_t {
  Ok,
  InvalidArgument,
  InvalidState,
  NotFound,
  StaleHandle,
  Unsupported,
  PermissionDenied,
  Busy,
  Cancelled,
  BackendUnavailable,
  ResourceExhausted,
  IoFailure,
  InternalFailure,
};

struct Error {
  ErrorCode code;
  OperationId operationId;
  std::string message;
  std::string owner;
  bool retryable = false;
};

template <class T>
class Result;
```

error ต้องบอก owner และ operation ID เพื่อเชื่อม log/bugpack ห้าม fallback เงียบ

### 7.3 Snapshot, query and mutation separation

- query คืน immutable snapshot/value object ไม่คืน mutable model pointer
- persistent mutation ผ่าน command transaction เท่านั้น
- transient preview ใช้ session/preview API และต้องมี explicit finalize/cancel
- snapshot มี `revision`; mutation ที่ต้องการ consistency รับ expected revision
- conflict คืน `InvalidState`/revision conflict ไม่ overwrite เงียบ

ตัวอย่าง low-level contracts:

```cpp
class IDocumentQuery {
public:
  virtual Result<DocumentSnapshot> Get(DocumentHandle document) const = 0;
};

class ICommandService {
public:
  virtual Result<TransactionHandle> Begin(const TransactionDesc&) = 0;
  virtual Result<CommandReceipt> Execute(TransactionHandle,
                                         const CommandRequest&) = 0;
  virtual Result<CommitReceipt> Commit(TransactionHandle) = 0;
  virtual Result<void> Rollback(TransactionHandle) = 0;
};
```

destructor ของ transaction/session ที่ยังไม่จบต้อง cancel/rollback แบบ fail-safe
ห้าม implicit commit

### 7.4 Async jobs and tickets

งาน GPU, import, save, bake, export และ readback ใช้ ticket/job contract เดียว:

```cpp
enum class JobState { Queued, Running, Succeeded, Failed, Cancelled };

struct JobStatus {
  JobState state;
  float progress;
  OperationId operationId;
  Error error;
};

class IJobService {
public:
  virtual Result<JobStatus> GetStatus(JobHandle) const = 0;
  virtual Result<void> Cancel(JobHandle) = 0;
};
```

กฎ:

- async method ลงท้าย `Async` หรือคืน `JobHandle`/typed ticket ชัดเจน
- job owner เก็บ resource จน terminal state
- cancellation เป็น request; receipt ต้องบอก cleanup disposition
- add-on unload ไม่ได้ขณะยังมี owned job/resource/subscription
- callback delivery thread ต้องประกาศ; default คือ main application thread

### 7.5 Event contract

event ใช้สำหรับ notification หลัง state เปลี่ยน ไม่ใช้แทน command หรือซ่อน workflow

- event payload เป็น immutable value + revision + operation ID
- subscription คืน handle และต้อง unsubscribe ได้
- ไม่มี global event bus ที่ใคร publish domain event ได้เอง
- แต่ละ owner publish เฉพาะ event ของ state ที่ตนเป็นเจ้าของ
- event handler ห้าม re-enter mutation โดยไม่ผ่าน workflow/command queue

### 7.6 World, document, scene, layer and asset APIs

Low-level query owners:

| API | Owns/returns | Does not do |
| --- | --- | --- |
| `IWorldService` | entity/component/system registration, hierarchy และ update schedule | expose Flecs world/pointer ผ่าน public API |
| `IDocumentQuery` | document identity, revision, active scene/texture set | mutation, GPU access |
| `ISceneQuery` | object/mesh/material/camera snapshots และ paint target capability | direct mesh GPU handle |
| `ILayerQuery` | hierarchy, visibility, opacity, masks, channel descriptors | mutate layer หรือ return `Layer*` |
| `IAssetQuery` | stable asset ID, URI, hash/revision, decode status | UI file dialog |
| `ISelectionQuery` | immutable current selection | document mutation |

mutation requests เช่น create/delete/move/rename layer, bind material และ change
selection ที่ต้อง undo ต้องถูกสร้างเป็น typed command ผ่าน `ICommandService`

World API ใช้สองชั้น:

- low-level typed world/component API สำหรับ engine/game systems
- high-level scene/game workflows สำหรับ application/add-on

Flecs ที่ APaint ใช้อยู่เป็น candidate implementation หลัง `IWorldService` ไม่ใช่
public identity/ABI ของ A-Engine และต้องพิสูจน์ component lifetime, module loading,
serialization และ deterministic phase order ก่อนย้ายเข้า core

### 7.7 Render intent API

public render API รับ intent และ opaque resource handle ไม่รับ `VkImage`,
`VkImageView`, `VkBuffer`, descriptor set, queue หรือ command pool

ขั้นต่ำที่สร้างเมื่อมี consumer:

```cpp
class ITextureService {
public:
  virtual Result<TextureHandle> Create(const TextureDesc&) = 0;
  virtual Result<void> Release(TextureHandle) = 0;
};

class IReadbackService {
public:
  virtual Result<ReadbackTicket> ReadbackAsync(const ReadbackRequest&) = 0;
};

class ICompositeService {
public:
  virtual Result<CompositeTicket> ExecuteAsync(const CompositePlan&) = 0;
};
```

backend เป็น owner ของ allocation, format mapping, image layout, descriptor,
barrier, queue submission, synchronization และ destruction order

`BackendHandle` ปัจจุบันเป็น migration seam ภายใน ไม่ถือเป็น public add-on resource
handle และต้องไม่ถูกส่งออกผ่าน SDK

### 7.8 Paint low-level API

`IPaintService` ต้องใช้ `PaintStrokeSession`, `PaintStrokeProjectionPlan`,
`PaintStrokeFootprint` และ `PaintChannelDescriptor` ที่มีอยู่เป็น source of truth

```cpp
struct BeginStrokeRequest {
  DocumentHandle document;
  SceneObjectHandle object;
  LayerHandle layer;
  ToolId tool;
  InputSource inputSource;
  BrushSnapshot brush;
  MaterialPaintPayload material;
};

struct StrokeSample {
  InputSampleId id;
  RawUv rawUv;
  std::optional<SurfaceHit> surface;
  Pressure pressure;
  Timestamp timestamp;
};

class IPaintService {
public:
  virtual Result<StrokeHandle> Begin(const BeginStrokeRequest&) = 0;
  virtual Result<StrokeUpdateReceipt> Append(StrokeHandle,
                                             const StrokeSample&) = 0;
  virtual Result<PaintCommitTicket> CommitAsync(StrokeHandle) = 0;
  virtual Result<void> Cancel(StrokeHandle, CancelReason) = 0;
};
```

invariants:

- Begin freeze target, tip identity, material, channel mask, metric และ tool state
- View2D/View3D ส่ง raw input/target context เท่านั้น
- overlay, transient และ commit consume plan เดียวกัน
- preview/commit footprint ต้องเท่ากันตาม contract
- one gesture มี terminal commit หรือ cancel ครั้งเดียว
- renderer เลือก execution route ได้ แต่เปลี่ยน semantics ไม่ได้
- failure ต้อง fail closed พร้อม diagnostics; ห้าม procedural/neutral fallback ของ
  Normal Paint
- commit สำเร็จต้องสร้าง command/history receipt แบบ atomic

## 8. High-level Workflow API

High-level API เป็นเส้นทางหลักของ games/applications, editor UI, APaint,
automation, tests และ add-on
มันรวมหลาย low-level calls เป็น use case ที่ปลอดภัย แต่ไม่เป็น owner ของ GPU details
หรือคัดลอก domain formulas

### 8.1 Design rules for easy use

- method ชื่อจาก user intent เช่น `CreatePaintLayer`, `PaintStroke`, `ExportTextureSet`
- ใช้ request/result structs แทน positional parameters จำนวนมาก
- safe defaults อยู่ใน request builder/schema กลาง
- validation ทำก่อน mutation และคืน errors ทั้งหมดที่รู้ได้ใน preflight
- sync method ใช้เฉพาะงานสั้นบน owning thread
- งาน IO/GPU ระยะยาวคืน typed ticket
- convenience method ต้องเรียก primitive route เดียวกัน ไม่สร้าง semantics อีกชุด
- query แยกจาก command เพื่อให้ add-on อ่าน state โดยไม่เผลอ mutate
- workflow result มี operation ID, affected handles, revision และ diagnostic summary
- API ทุกชุดมี capability query และ `Unsupported` ที่ deterministic

### 8.2 Workflow services

| Service | High-level use cases |
| --- | --- |
| `ApplicationWorkflow` | new/open/close document, readiness, shutdown coordination |
| `WorldWorkflow` | create/destroy entity, component composition, update/pause/step |
| `SceneWorkflow` | import model, create/remove object, set active camera/paint target |
| `LayerWorkflow` | create/delete/duplicate/move/group/mask/merge/property mutation |
| `PaintWorkflow` | preflight, streaming stroke, batch stroke, cancel, tool session |
| `ProjectWorkflow` | open/save/save-as, dirty state, package migration |
| `ExportWorkflow` | validate export, bake/composite/readback/write files |
| `ViewportWorkflow` | create view, camera/navigation intent, display channel, capture |
| `GeometryWorkflow` | mesh selection/edit/sculpt transaction และ topology validation |
| `AnimationWorkflow` | skeleton/clip/state playback, record และ bake/export |
| `PhysicsWorkflow` | world queries, rigid-body/character configuration และ simulation step |
| `GameWorkflow` | runtime state, level/session loading และ gameplay system composition |
| `AddonWorkflow` | query installed add-ons, enable/disable/reload under lifecycle rules |

### 8.3 PaintWorkflow example

C++ convenience wrapper สำหรับ APaint/product/add-on:

```cpp
auto session = api.Paint().BeginStroke({
    .document = document,
    .target = target,
    .layer = layer,
    .tool = ToolId::NormalPaint,
    .brush = brush,
    .material = material,
});
if (!session) {
  return ShowError(session.Error());
}

for (const auto& sample : inputSamples) {
  if (auto appended = session->Append(sample); !appended) {
    session->Cancel(CancelReason::InputRejected);
    return ShowError(appended.Error());
  }
}

auto commit = session->CommitAsync();
```

`StrokeSession` ใน C++ SDK เป็น RAII convenience wrapper รอบ `StrokeHandle`
destructor cancel เท่านั้น ไม่ commit

batch helper สำหรับ automation:

```cpp
Result<PaintCommitTicket> PaintWorkflow::PaintStroke(
    const PaintStrokeRequest& request,
    std::span<const StrokeSample> samples);
```

helper นี้ต้องเรียก Begin → Append → Commit route เดียวกับ streaming API

### 8.4 LayerWorkflow example

```cpp
auto created = api.Layers().CreatePaintLayer({
    .document = document,
    .parent = group,
    .name = "Details",
    .selectAfterCreate = true,
});
```

workflow ต้องทำ validation, command transaction, active-selection update และ event
publication เป็นหนึ่ง atomic operation และคืน `LayerMutationReceipt`

### 8.5 Project/Export example

```cpp
auto validation = api.Export().Validate({document, preset});
if (!validation) {
  return ShowError(validation.Error());
}
auto job = api.Export().ExportTextureSetAsync({document, preset, outputUri});
```

export workflow ห้ามอ่าน `LayerManager` หรือ Vulkan backend ตรง ต้องใช้ document
snapshot, compositor plan และ readback service

### 8.6 Host service access

ห้ามสร้าง god interface ที่มี method ทุกอย่าง ใช้ `ApplicationServices` เป็น immutable
bundle ของ narrow interfacesที่ composition root inject ให้ consumer:

```cpp
struct ApplicationServices {
  IApplicationWorkflow& application;
  ISceneWorkflow& scene;
  ILayerWorkflow& layers;
  IPaintWorkflow& paint;
  IProjectWorkflow& project;
  IExportWorkflow& exportService;
  IViewportWorkflow& viewports;
};
```

bundle ไม่มี ownership และไม่มี `GetSingleton()` global access

### 8.7 Ergonomic C++ Application façade

ผู้สร้าง 3D application ไม่ควรประกอบ low-level services เองทุกครั้ง ให้ SDK มี
`aengine::App` เป็น ergonomic façade ที่ delegate ไป narrow workflows/services
ด้านใน `App` จึงสะดวกได้โดยไม่เป็น owner ของ paint math, document state หรือ GPU
resource

รูปแบบใช้งานเป้าหมาย:

```cpp
#include <AEngine/App.h>

int main() {
  auto created = aengine::App::Init({
      .name = "My3DTool",
      .width = 1600,
      .height = 900,
  });
  if (!created) {
    return aengine::ReportStartupError(created.Error());
  }

  auto app = std::move(created.Value());
  auto view3d = app.CreateView3D({.name = "Main View"}).Value();

  app.OnStart([&](aengine::StartContext& start) {
    start.NewDocument({.name = "Untitled"});
  });

  app.OnFrame([&](const aengine::FrameContext& frame) {
    view3d.Update(frame);

    if (frame.Commands().WasTriggered("file.save")) {
      app.Save();
    }
    if (frame.Commands().WasTriggered("app.quit")) {
      app.Quit();
    }
  });

  return app.Run();
}
```

API surface ขั้นต่ำ:

```cpp
class App {
public:
  static Result<App> Init(const AppConfig&);

  int Run();
  Result<bool> PumpFrame();
  SaveTicket Save();
  SaveTicket SaveAs(const Uri&);
  void Quit();

  Result<View3D> CreateView3D(const View3DDesc&);
  ApplicationServices Services();
};
```

semantics:

- `Init()` สร้าง platform, backend และ services หรือคืน structured startup error
- `Run()` เป็น blocking owned event loop จนมี `Quit()` request
- `PumpFrame()` เป็น embedded/manual-loop alternative; ห้ามเรียกพร้อม `Run()`
- `Save()` save active document แบบ async และคืน ticket; ไม่ block UI thread
- `Quit()` เป็น request; shutdown จริงเกิดที่ safe frame boundary ตาม ownership order
- `View3D::Update(frame)` ส่ง view/camera/render intent ไม่เรียก Vulkan ตรง
- `App` อาจมี convenience methods แต่ทุก method ต้อง delegate ไป workflow เดียวกับ
  UI/automation/add-on และไม่มี business logic ซ้ำ

สำหรับ application ที่ต้องการสั้นที่สุด:

```cpp
int main() {
  auto app = aengine::App::Init({.name = "Viewer"}).Value();
  return app.Run();
}
```

default app จะสร้าง window/workspace ตาม `AppConfig`; ถ้าต้องการ custom behavior
จึง register callbacks/add-ons เพิ่ม

### 8.8 View façade

`View3D` และ `View2D` เป็น move-only façade/handle ไม่เป็นเจ้าของ scene/document:

```cpp
view3d.SetScene(scene);
view3d.SetCamera(camera);
view3d.Resize({width, height});
view3d.Update(frame);
view3d.SetDisplayChannel(PaintChannelId::Normal);
auto capture = view3d.CaptureAsync();
```

- invalid/stale view handle คืน structured error
- `Resize` สร้าง render-resource intent; backendจัดการ in-flight lifetime
- `Update` ไม่ mutate document และไม่เดิน paint sessionเอง
- input adapter แปลง screen/GBuffer hit เป็น workflow requestเท่านั้น
- registered views อาจถูก auto-updateโดย product shell แต่ explicit `Update` ต้องใช้
  execution pathเดียวกัน

### 8.9 AI-facing developer surface

A-Engine ต้องให้ AI ใช้ public surface เดียวกับ developer ไม่สร้าง privileged debug
mutation path

machine-readable artifacts:

- `aengine_api.json`: versions, handles, requests, results, methods, capabilities,
  thread/lifetime rules และ deprecations
- `aengine_commands.json`: command names, input schema, undoability, preconditions และ
  result/event schema
- `aengine_components.json`: component IDs, fields, defaults, serialization และ update phase
- `aengine_shaders.json`: shader program/function catalog, ABI, variants และ examples
- `aengine_addons.schema.json`: manifest/dependency/capability schema

schema ต้อง generateจาก source-of-truthเดียวกับ headers/bindings หรือถูกตรวจ driftใน
build ห้าม maintainเอกสาร/API/schemaสามชุดด้วยมือ

development tools เป้าหมาย:

```text
ae new app MyViewer --profile viewer
ae new addon MyTool --capability ui.panel,scene.read
ae doctor
ae inspect api PaintWorkflow
ae inspect scene --json
ae replay traces/example.aetrace
ae shader validate <file>
ae test --profile focused
```

ชื่อ commandเป็น proposalจน Phase ที่เกี่ยวข้องเริ่ม implement แต่ behaviorต้องยึด:

- scaffolderสร้าง minimal compiling projectจาก public SDK
- inspectเป็น read-onlyและ output stable JSON
- replayใช้ command/workflow routeจริง
- local control serverเปิดเฉพาะ development/test configuration, bind localhost,
  มี explicit capabilityและปิดใน shipping default
- AI-generated application/add-onต้องผ่าน compile, contract tests, dependency guard
  และ sample runtime proofก่อนส่งงาน

## 9. Renderer and Shader Language Library

### 9.1 Decision: shader language, not shader nodes

canonical shader source ของ engine คือ text-based Vulkan GLSL `#version 450`
compile เป็น SPIR-V target Vulkan 1.2 ตาม production contract ปัจจุบัน

- engine/add-on SDK ใหม่ไม่มี shader-node authoring API
- shader function, effect และ pipeline เขียนเป็น source files ที่ AI/คนอ่านและแก้ได้ตรง
- GraphMan/NodeMan/CompileMan ที่ยังอยู่ใน repository เป็น legacy/independent subsystem
  และห้ามเป็น dependency ของ engine shader API
- การลบ legacy node subsystemทำได้เมื่อ caller/asset compatibility inventory เป็นศูนย์
  ไม่ลบเพียงเพราะ target architecture ไม่ใช้มัน

### 9.2 Two shader levels

แยก shader code เป็นสองระดับเพื่อ reuse โดยไม่ผูก helper กับ pipeline ABI:

1. **Shader Function Library** — pure reusable `.glsl` modules ไม่มี entry point,
   descriptor, push constant หรือ hidden global resource
2. **Shader Programs** — `.comp`, `.vert`, `.frag` ที่มี `#version`, resource ABI,
   entry point และ include function library

target source layout:

```text
engine/shader/
  include/AEngine/Shader/
  src/
  library/aengine/
    math/
    random/
    noise/
    color/
    blend/
    sampling/
    normal/
    pbr/
    paint/
    uv/

engine/renderer/shaders/       # viewport/runtime entry programs
features/paint/shaders/        # reusable paint feature entry programs
features/editor/shaders/       # editor-only entry programs
apps/<name>/shaders/           # product-specific entry programs
```

entry programs อยู่กับ behavior owner แต่ include library มาจาก canonical pathเดียว
APaint shared includesเดิมเป็น donor ที่ย้ายทีละ helperด้วย clean ownership/consumer
contract ห้ามให้ A-Engine package runtime shadersด้วยการ copyทั้ง folderจาก APaint

### 9.3 Shader function module rules

ทุก reusable module ต้อง:

- ใช้ include guard เช่น `AENGINE_NOISE_FBM_GLSL`
- prefix exported symbol ด้วย `ae_` เพื่อกัน collision
- รับ input/parameters ชัดเจน ไม่มี hidden uniform/descriptor
- ระบุ input/output domain, color space, units, valid range และ NaN/Inf policy
- deterministic สำหรับ input/seed เดิม เว้นแต่ contractระบุ temporal noise
- clamp เฉพาะเมื่อ function contractกำหนด ห้ามกลบ invalid dataเงียบ
- ไม่มี `#version`, `layout(...)`, `main()` หรือ backend-specific resource binding
- ไม่มี copy ของ UV, alpha, channel/storage หรือ blend semantics ที่มี ownerกลางแล้ว

ตัวอย่าง Noise:

```glsl
#ifndef AENGINE_NOISE_FBM_GLSL
#define AENGINE_NOISE_FBM_GLSL

struct AeFbmParams {
    int octaves;
    float lacunarity;
    float gain;
    uint seed;
};

float ae_noise_fbm3(vec3 position, AeFbmParams params) {
    // implementation ใช้ ae_hash/ae_noise primitive กลาง
}

#endif
```

ตัวอย่าง Color Grading:

```glsl
#include "aengine/color/space.glsl"
#include "aengine/color/grade.glsl"

vec3 linearColor = ae_srgb_to_linear(sourceColor);
linearColor = ae_color_grade(linearColor, gradeParams);
vec3 outputColor = ae_linear_to_srgb(linearColor);
```

ชื่อ function ต้องสื่อ color space เช่น `ae_srgb_to_linear`; ห้ามใช้ชื่อกว้าง
`convertColor()` ที่ทำให้ callerเดา domain

### 9.4 Initial shader library catalog

สร้างตาม consumer จริง ไม่สร้างทุกไฟล์ล่วงหน้า:

| Category | First useful functions | First consumer candidate |
| --- | --- | --- |
| `math` | safe divide, finite clamp, remap, saturate | existing composite/paint include |
| `random` | integer hash, seeded hash | first procedural noise effect |
| `noise` | value/perlin/simplex primitive และ fBm | material/imperfection shaderหนึ่งตัว |
| `color` | sRGB/linear, exposure, contrast, lift-gamma-gain, HSV | Color Grading compute effect |
| `blend` | canonical color blend functions | layer/compositor contract |
| `sampling` | texel/UV helpers, boundary/addressing helpers | bake/compositor route |
| `normal` | encode/decode, tangent/world conversion | PBR/paint route |
| `pbr` | BRDF/material helpers | Standard View3D pipeline |
| `paint` | coverage/channel helpersที่อ้าง contractกลาง | Normal Paint shader |
| `uv` | explicit raw/local/tile transforms | UDIM-aware program; ห้าม `fract` shortcut |

Noise/Color library ไม่ควรเริ่มก่อน `math` + compiler/include test harness เพราะจะ
ทำให้ helperชุดแรกไม่มี ABI/validation foundation

### 9.5 Shader source, include and compile service

สร้าง `aengine_shader` ให้เป็น owner ของ shader-language toolchain โดยใช้ behavior,
test vectors และข้อจำกัดของ donor ShaderMan เป็นหลักฐาน ไม่ link/include donor manager:

```cpp
struct ShaderSourceDesc {
  ShaderUri uri;
  ShaderStage stage;
  std::string entryPoint = "main";
  std::vector<ShaderDefine> defines;
};

class IShaderLibrary {
public:
  virtual Result<ShaderSource> Resolve(const ShaderUri&) = 0;
  virtual Result<CompiledShader> Compile(const ShaderSourceDesc&) = 0;
  virtual Result<ShaderReflection> Reflect(const CompiledShader&) = 0;
};
```

required behavior:

- canonical URI เช่น `aengine://shaderlib/noise/fbm.glsl`
- deterministic include search order และ cycle/unknown include rejection
- diagnostic แสดง full include stack, file, line, stage และ variant
- content hash ครอบ source, transitive includes, defines, compiler version,
  optimization และ target environment
- cache key เดียวกันต้องได้ SPIR-V/ABI เดิม
- reflection เก็บ descriptor sets/bindings/types, image formats, push constant
  offsets/sizes, specialization constants, stage inputs/outputs และ local workgroup size
- generated ABI report/header มาจาก reflection; ห้าม maintain binding layoutสองชุดด้วยมือ

`CompilationResult` แบบ bool/string ปัจจุบันเป็น compatibility seam เป้าหมายต้องคืน
structured Result + diagnostics โดย adapterเดิมคงได้เฉพาะช่วง migration

### 9.6 Shader ABI contract

shader program ทุกตัวที่ production ใช้ต้องมี reflected contract:

```text
source + transitive include hash
stage + entry point
descriptor set/binding/type/count
storage image format qualifier
push constant member offset/size
local workgroup size
host resource format/usage expectation
shader ABI version
```

build/guard ต้องเปรียบเทียบ reflection กับ host descriptor writes, `VkFormat`,
push-constant `offsetof()` และ dispatch bounds shader source ใหม่กว่า packaged SPIR-V
ถือว่า fail ไม่ใช้ไฟล์เก่าเงียบ

### 9.7 Pipeline and compute helpers

เป้าหมายคือ shader ใหม่ไม่ต้องเขียน descriptor layout, pipeline layout, allocation,
binding, dispatch group calculation และ barrier boilerplateซ้ำทุกไฟล์

```cpp
auto program = renderer.Shaders().Load({
    .uri = "aengine://programs/color/color_grade.comp",
});

auto effect = renderer.Compute().CreateEffect(program.Value());
effect.Bind(ColorGradeBindings::Source, sourceTexture);
effect.Bind(ColorGradeBindings::Destination, destinationTexture);
effect.SetConstants(ColorGradeConstants{
    .exposure = 0.5f,
    .contrast = 1.1f,
});

auto ticket = effect.DispatchFor(destinationTexture);
```

helper layers:

| Helper | Responsibility |
| --- | --- |
| `ShaderLibrary` | resolve/include/compile/reflect/cache |
| `PipelineLibrary` | cache graphics/compute pipelineจาก program ABI + render state |
| `BindingSetBuilder` | validate resource name/type/format/usageจาก reflection |
| `ComputeEffect` | constants, bindings, dispatch size และ submission ticket |
| `RenderPassBuilder` | attachment/load/store/viewport/draw intent |
| `BarrierPlanner` | derive transitionsจาก declared read/write intent; backend executes |
| generated typed bindings | compile-time binding/constants namesสำหรับ built-in shaders |

generic string binding ใช้ได้ใน development/add-on API แต่ built-in production shader
ควรใช้ generated typed binding IDs เพื่อตรวจ typo/type ก่อน runtime ทั้งสองแบบต้องลง
execution pathเดียวกัน

### 9.8 Pipeline cache and hot reload

- pipeline cache key รวม program hashes, shader variants, reflected ABI, attachment
  formats, vertex layout, blend/depth/raster state และ backend identity
- descriptor/pipeline allocation reuse ตาม lifetime owner ห้าม allocateซ้ำใน render loop
- development hot reload compile/reflect/validate pipelineใหม่ก่อน atomic swap
- pipelineเก่าคงอยู่จน in-flight frames/fencesจบ
- compile/ABI failure ให้คง pipelineเดิมเฉพาะ development mode พร้อม errorชัดเจน
- release packageใช้ build-produced, hash-verified SPIR-V ไม่ runtime compileจาก source
- hot reload ไม่เปลี่ยน descriptor/push-constant ABI โดยอัตโนมัติ; incompatible
  changeต้อง rebuild owner pipeline/typed bindings

### 9.9 Adding a new shader function/effect

ขั้นตอนมาตรฐานที่ AI และคนทำตามได้:

1. ค้นหา helper/contractเดิมและกำหนด owner/category
2. เพิ่ม pure `.glsl` function พร้อม domain/range/color-space contract
3. เพิ่ม minimal wrapper shader test ที่ include และเรียก functionจริง
4. validate GLSL, compile SPIR-V และ reflect ABI
5. เพิ่ม deterministic GPU vectors/golden readback; visual screenshotเมื่อเกี่ยวข้อง
6. include จาก production programหนึ่งตัว หรือสร้าง entry programที่มี consumerจริง
7. ใช้ `PipelineLibrary`/`ComputeEffect`; ห้ามสร้าง descriptor/pipeline boilerplateใหม่
8. รัน focused shader/renderer guard และตรวจ source/SPIR-V freshness
9. เมื่อ consumerเก่าย้ายครบ ลบ helper/pipeline pathเดิม

### 9.10 Renderer/View3D route

```text
View3D::Update(FrameContext)
  -> ViewportWorkflow builds immutable ViewFrameRequest
  -> Renderer validates scene/camera/targets/capabilities
  -> RenderPassBuilder creates render intent
  -> PipelineLibrary resolves cached shader programs/pipelines
  -> backend records barriers/descriptors/commands
  -> frame ticket/present/capture diagnostics
```

`View3D` ห้ามสร้าง pipeline, load SPIR-V, allocate descriptor หรือเลือก image layoutเอง

### 9.11 Shader verification

| Evidence | Required |
| --- | --- |
| include/module tests | unknown include, cycle, duplicate symbol และ dependency hash |
| GLSL validation | every entry program and wrapper for include-only modules |
| reflection contract | descriptors, formats, push offsets, local size |
| C++ contract | generated bindings/constants compile + `offsetof()` checks |
| GPU unit | deterministic vectors/readback for math/noise/color functions |
| runtime | pipeline creation, validation layer, target format/layout/sync |
| visual | Standard View3D screenshot/capture for visible effect |
| packaging | source/SPIR-V hash/freshness and required runtime compiler policy |

สำหรับ paint shader ต้องรักษา texture-tip, straight-alpha, channel coverage และ
preview/commit contracts สำหรับ Surface Blur ห้ามสร้าง CPU blur oracle/fallback

## 10. Add-on SDK and Host

Add-on ต้องใช้ High-level Workflow API เป็นค่าเริ่มต้น Low-level API เปิดเฉพาะ query,
value types และ extension contract ที่จำเป็นจริง ไม่เปิด backend internals

### 10.1 Add-on types

| Type | Examples | Default access |
| --- | --- | --- |
| UI extension | panel, menu, toolbar, property editor | snapshots + workflows |
| Command extension | new user action/hotkey | command registration + workflows |
| Import/export extension | file reader/writer, export preset | IO stream + document snapshot + job API |
| Paint tool extension | custom tool/session strategy | typed tool contract + paint/render intent |
| Asset processor | texture/material/model processing | asset/job API |
| Render extension | preview/composite/compute pass | trusted render graph/intent API only |

ไม่มี add-on ชนิดใดได้รับ `VkDevice`, `VkImage`, manager pointer หรือ mutable
`Layer*` จาก public SDK

### 10.2 ABI strategy

ลำดับที่ถูกต้อง:

1. ใช้ internal C++ interfaces เพื่อ dogfood ใน APaint ก่อน
2. เมื่อ API ผ่าน consumer จริงและ compatibility tests แล้ว จึง freeze public C ABI
3. สร้าง C++ convenience wrapper แบบ header-only เหนือ C ABI
4. scripting binding ในอนาคต generate/implement เหนือ contract เดียวกัน

public native ABI ต้องใช้:

- fixed-width integer, plain structs และ function tables
- `structSize` + `apiVersion` สำหรับ version negotiation
- host-owned allocator/string/span rules
- opaque 64-bit handles
- explicit result/error code
- no exception, RTTI, STL container หรือ C++ object ownership ข้าม DLL boundary

entry points เป้าหมาย:

```c
AENGINE_ADDON_EXPORT AEngineAddonQueryResult
AEngineAddon_Query(const AEngineHostQuery* host);

AENGINE_ADDON_EXPORT AEngineResult
AEngineAddon_Load(const AEngineHostApiV1* host, AEngineAddonApiV1* addon);

AENGINE_ADDON_EXPORT void
AEngineAddon_Unload(void);
```

ชื่อ symbol/encoding ที่แน่นอนต้องผ่าน ABI design slice ก่อน implement ห้ามถือ pseudo
code นี้เป็น ABI ที่ freeze แล้ว

#### 10.2.1 Linking and deployment policy

ใช้ hybrid model ตาม ownership:

| Artifact | Default | Reason |
| --- | --- | --- |
| engine-owned internal modules/backends | static/private link เข้า host ระหว่าง pre-1.0 | ลด deployment/ABI surface และให้ optimizeทั้งโปรแกรมได้ |
| A-Engine runtime public boundary | shared libraryเมื่อเริ่ม external SDK | มี process-wide owner/state/allocator และ stable C exportsชุดเดียว |
| public native add-on | dynamic library (`.dll`/`.so`/`.dylib`) | discover/version/check capability/loadโดยไม่ relink host |
| C++ SDK convenience | headers + exported CMake/import target | wrapperบางเหนือ C ABI; ไม่ duplicate engine implementation |
| C# SDK/add-on | managed assembly + dynamic C ABI binding | ใช้ workflowเดียวกันและแยก managed packageจาก native core |
| untrusted extension | out-of-process workerใน future security slice | dynamic in-process libraryไม่ใช่ crash/security sandbox |

Windows package อาจมี `.lib` ที่เป็น **import library** คู่กับ runtime DLL; ต้องตั้งชื่อ
package/targetให้แยกจาก static implementation libraryชัดเจน

ห้าม static-link engine implementationเข้า third-party add-on เพราะเสี่ยงมี global
state, allocator, runtime registration และ resource ownerซ้ำหลายชุด รวมทั้งบังคับ
relink hostเมื่อ add-onเปลี่ยน

internal add-onอาจ static-registerใน test/bootstrap phaseได้ แต่ต้องเรียก lifecycle,
capability และ workflow contractเดียวกับ dynamic host ห้ามใช้ privileged route และต้องมี
dynamic load proofก่อน freeze public ABI

### 10.3 Manifest

manifest ขั้นต่ำ:

```json
{
  "id": "com.example.layer-tools",
  "name": "Layer Tools",
  "version": "1.0.0",
  "engineApi": ">=1.0 <2.0",
  "entry": "layer_tools.dll",
  "capabilities": ["ui.panel", "layer.read", "layer.mutate"],
  "dependencies": []
}
```

host ต้อง reject duplicate ID, invalid version range, missing capability, dependency
cycle, incompatible ABI และ unsigned/untrusted policy ตาม release configuration

### 10.4 Lifecycle

```text
Discovered -> Validated -> Loaded -> Activated
                                  -> Deactivated -> Unloaded
                       failure -> Quarantined
```

กฎ:

- `Load` ใช้ register static extension descriptors; ห้าม mutate document
- `Activate` ได้ scoped services ตาม capabilities
- `Deactivate` ยกเลิก subscriptions, commands, UI registrations และ jobs
- unload ได้เมื่อ owned resources/jobs/sessions เป็นศูนย์
- callback failure ถูกผูกกับ add-on ID และ operation ID
- in-process native crash แยก process ไม่ได้ จึงเริ่มจาก trusted add-ons เท่านั้น
- hot reload ไม่ใช่ v1 requirement จน lifetime audit และ unload stress test ผ่าน

### 10.5 Capability model

ตัวอย่าง capabilities:

- `document.read`, `document.mutate`
- `scene.read`, `scene.mutate`
- `layer.read`, `layer.mutate`
- `paint.execute`, `paint.tool.register`
- `asset.read`, `asset.write`
- `project.read`, `project.write`
- `ui.panel`, `ui.menu`, `ui.command`
- `render.readback`, `render.extension.trusted`

capability ไม่แทน validation ของ workflow และไม่ให้สิทธิ์เข้าถึง implementation header

### 10.6 First internal add-ons

ห้ามประกาศ public SDK จาก sample ที่ไม่มี production path ต้อง dogfood อย่างน้อยสอง
consumer:

1. read-oriented add-on: ย้าย existing read-only diagnostics/inspector panel หนึ่งตัว
   ให้ register ผ่าน Add-on Host
2. mutation-oriented add-on: ย้าย existing layer command หรือ export preset หนึ่งตัว
   ให้เรียก High-level Workflow API เท่านั้น

เมื่อสอง add-on นี้ผ่าน load/unload, error injection, command/history และ package
compatibility tests จึงเริ่ม public ABI freeze

### 10.7 C# High-level SDK

#### Decision

C# เหมาะสำหรับ application composition, editor tools, automation, gameplay และ add-on
logic เพราะ iteration เร็วและ API อ่านง่าย แต่ **ไม่แทน C++ canonical workflow** และ
ไม่อยู่ใน renderer/GPU ownership hot path

```text
C++ domain/render implementations
  -> C++ low-level contracts
  -> C++ high-level workflows (canonical behavior)
  -> versioned C ABI (stable binary boundary)
       -> C++ ergonomic façade
       -> generated C# interop + hand-written idiomatic C# façade
```

ตัวอย่าง target API:

```csharp
using AEngine;

using var app = App.Init(new AppConfig { Name = "My3DTool" });
var view3D = app.CreateView3D(new View3DDesc { Name = "Main View" });

app.Frame += frame =>
{
    view3D.Update(frame);
    if (frame.Commands.WasTriggered("file.save"))
        app.Save();
};

return app.Run();
```

interop rules:

- ใช้ C exports/function tables; ห้าม P/Invoke C++ mangled symbolsหรือข้าม STL object
- .NET 7+ binding ใช้ source-generated `LibraryImport` เมื่อรองรับ
- native identity/resource ownership ห่อด้วย `SafeHandle`/`IDisposable`; ห้ามพึ่ง
  finalizer เป็น normal cleanup path
- C ABI ใช้ fixed-width/blittable structs, explicit UTF-8 spans/buffers และ host-owned
  allocation/free functions; หลีกเลี่ยง ABI `bool`, platform-width `long` และ hidden copy
- callback ระบุ thread/lifetime; managed exceptionต้องถูกจับที่ boundaryและแปลงเป็น
  structured error ห้ามข้ามเข้า native stack
- ลด per-entity/per-pixel P/Invoke chatty calls ด้วย batch request, spans, snapshots,
  command buffers และ async tickets
- C# façade generate enums/handles/requests/resultsจาก `aengine_api.json`; idiomatic
  wrappersเพิ่มได้แต่ต้องมี parity testsกับ C++ workflow
- .NET runtime เป็น optional package/profile; C++ viewer/headless/game buildต้องทำงานได้
  โดยไม่ติดตั้งหรือโหลด .NET

verification:

- native `sizeof`/offset เทียบ generated managed layoutทุก ABI struct
- lifetime tests: dispose, double-dispose, stale handle, callbackหลัง ownerตาย
- UTF-8/error/array/span round-trip และ allocator ownership tests
- C++ กับ C# เรียก trace เดียวกันแล้วได้ operation/result/state transitionเดียวกัน
- benchmark crossing overheadของ batch/workflow calls; hot pathที่ถี่เกิน budgetต้องย้าย
  batchingลง native workflow ไม่ใช่ bypass contract

## 11. Runtime ownership and thread model

| Object | Owner | Lifetime | Thread/queue rule |
| --- | --- | --- | --- |
| Engine runtime | A-Engine app composition root | process/application session | main thread create/destroy |
| Document service | application session | one or more document sessions | mutation serialized by command service |
| Document/scene/layer handles | domain owner | until explicit delete/document close | snapshots read-safeตาม revision contract |
| Stroke session | Paint service | Begin ถึง Commit/Cancel | input on owning thread; GPU work ticketed |
| GPU resources | render backend | handle release + in-flight completion | backend queues only |
| Workflow job | workflow/job service | queued ถึง terminal + receipt retention | callback defaults main thread |
| Add-on context | Add-on Host | Activate ถึง Deactivate | callbacks on declared host thread |
| UI state | product UI/add-on panel | UI session | main/UI thread |

shutdown order:

1. stop accepting new workflows
2. deactivate add-ons
3. cancel/wait add-on jobs and subscriptions
4. commit/cancel active sessionsตาม explicit policy
5. finish/cancel IO jobs
6. destroy UI/views
7. release domain GPU resource intents
8. wait backend idle and destroy backend
9. destroy document/domain services และ platform runner

## 12. Required operation flows

### 12.1 Paint stroke

```text
View2D/View3D/Add-on input
  -> PaintWorkflow preflight
  -> PaintService Begin freezes snapshot
  -> ProjectionPlan per sample
  -> Render intent executes preview/transient
  -> PaintService claims terminal commit once
  -> Render transaction applies layer pixels
  -> Command transaction records undo/history
  -> CommitReceipt + events + diagnostics
```

ถ้าขั้นใด fail ก่อน commit ต้อง cancel session และคง layer/history เดิม ถ้า GPU
submit แล้วต้องรายงาน ticket state/cleanup disposition ห้าม UI เดาจากภาพ

### 12.2 Layer mutation

```text
UI/Add-on/Automation
  -> LayerWorkflow validation
  -> Command transaction
  -> Layer domain mutation by stable handle
  -> dependent composite invalidation intent
  -> commit transaction
  -> snapshot revision/event/receipt
```

### 12.3 Export

```text
ExportWorkflow validation
  -> immutable document/layer snapshot
  -> canonical compositor/bake plan
  -> render/readback tickets
  -> encoder/file transaction
  -> atomic output disposition + report
```

### 12.4 Add-on activation

```text
discover manifest
  -> validate identity/version/dependencies/capabilities
  -> load DLL and negotiate ABI
  -> allocate scoped AddonContext
  -> register extensions
  -> activate
  -> health/ownership tracking
```

## 13. Implementation and migration order

หลักสำคัญ: **ห้ามสร้าง Low-level API ให้ครบทุกระบบก่อนแล้วค่อยสร้าง High-level API**
เพราะจะเกิด abstraction ที่ไม่มี consumer ให้สร้าง foundation ขั้นต่ำ แล้วเดินทีละ
vertical slice โดยแต่ละ phase ต้องมี API, reference consumer, tests และ deletion/exit
condition ครบ

### Phase 0 — Open-source project contract and research

ทำก่อน production source:

- approve mission/scope ในเอกสารนี้
- ยืนยัน MIT repository policy และจัดทำ third-party license/provenance/SBOM policy
- เลือก compiler/platform matrix และ canonical CMake build/test commands
- เปิด maintained code map และ dependency-direction guard
- บันทึก donor/standard decisions ใน `docs/RESEARCH_BRIEF.md`
- กำหนด contribution, semantic versioning, security และ release policy

สถานะปัจจุบัน:

- prototype AEngine เดิมถูกส่งเข้า Recycle Binตามคำสั่งผู้ใช้
- repositoryใหม่เป็น docs-first Git repository ไม่มี production sourceเก่าปน

Exit:

- MIT/third-party policy, supported platforms และ build toolchainถูกอนุมัติ
- repo structure/target naming/API error modelมี architecture testspec
- ห้ามสร้าง renderer/game/editor scaffoldจน Phase 0 gateผ่าน

### Phase 1 — Foundation and build backbone

สร้างก่อนสุด:

- root CMake project + presets/commandsที่อนุมัติ
- `aengine_foundation`
- typed generational handles
- `OperationId`, API version/capabilities
- `ErrorCode`, `Error`, `Result<T>`
- job/ticket value contracts, allocator/span/string ABI rules
- logging/build identity/crash breadcrumbขั้นต่ำ
- header self-containmentและ forbidden-dependency guard

First consumer:

- headless `aengine_info` tool ที่ query version/capabilitiesผ่าน public API

Exit:

- foundation build/testได้โดยไม่มี SDL, ImGui, Vulkan, APaint หรือ product module
- stale/wrong-type handlesและ error propagation testsผ่าน

### Phase 2 — Application/Platform façade

สร้าง:

- `aengine_platform` และ explicit composition root
- `App::Init`, `Run`, `PumpFrame`, `Quit`
- input/time/window/file-system ports
- `ApplicationServices` injection
- headless runnerและ deterministic frame trace

First consumers:

- `apps/viewer` เรียก `App::Init(); App::Run();`
- headless lifecycle testเรียก `PumpFrame()` จำนวนแน่นอนแล้ว `Quit()`

ห้าม:

- global `Engine::Get()` หรือ service locator
- domain/game/render logicใน `App`

Exit:

- startup failure/quit/shutdown orderและ resource cleanupพิสูจน์ได้
- appหนึ่งตัวสร้างได้โดย include public SDKเท่านั้น

### Phase 3 — World, Scene and Asset vertical slice

สร้าง:

- `aengine_world`, `aengine_scene`, `aengine_assets`
- entity/component/system + deterministic update phases
- transform hierarchy, camera, mesh/material/light snapshots
- stable asset URI/dependency/cache/import job contracts
- glTF 2.0 importer adapterเป็น first runtime asset path

First proof:

- viewerโหลด glTF scene, query object/cameraผ่าน High-level API และ headless snapshotตรงกัน

Exit:

- public APIไม่ expose Flecs/tinygltf/Assimp pointerหรือ types
- import cancel/failureไม่ทิ้ง half-created world
- scene serialization/snapshot revision testsผ่าน

### Phase 4 — Renderer, Shader Library and View3D

สร้างตามลำดับย่อย:

1. `aengine_render_api` opaque resources/intents/tickets
2. `aengine_shader_library` เริ่มจาก math + color-space helpers
3. `aengine_shader` include/compile/reflection/cache/ABI tools
4. `aengine_vulkan_backend` minimal implementation
5. `aengine_renderer` pipeline/effect helpers
6. `View3D::Update`, resize, capture/readback
7. เพิ่ม Noise และ Color Grading library หลัง foundation testsผ่าน

First proof:

- viewer render glTF PBR sceneผ่าน `View3D::Update(frame)`
- Color Grading compute effectใช้ shader library/pipeline helperโดยไม่มี bespoke
  descriptor/pipeline boilerplate

Exit:

- SDK/public headersไม่มี `Vk*`, VMA, volk หรือ backend handle
- validation layer errors=0 สำหรับ proof scene
- shader source/SPIR-V/reflection/host ABIตรงกัน
- resize/shutdownไม่ใช้ resourceหลัง fence lifetime

### Phase 5 — Commands, Workflows, Editor shell and internal add-ons

สร้าง:

- `aengine_commands`, `aengine_workflows`, query snapshots/events
- `App::Save`, project/document transactionและ undo/redo
- reusable editor shell, View3D panel, selection/inspector/gizmoขั้นต่ำ
- internal C++ add-on host, manifest, capabilities, register/unregister

First consumers:

- editor appเปิด/แก้ transform/save/undo/redoผ่าน workflows
- read-only inspector add-on
- mutation add-onที่แก้ transformผ่าน command workflow

Exit:

- editor/add-on/automationใช้ public workflowเดียวกัน
- load/activate/deactivate/unloadไม่ leak registrations/jobs/resources
- saveเป็น atomicและ round-tripได้

### Phase 6 — APaint adoption and reusable Paint feature

สร้าง/ย้าย:

- `aengine_paint`
- `IPaintService` + `PaintWorkflow`
- reuse/migrate typed `PaintStrokeSession`, `PaintStrokeProjectionPlan`, footprint
  และ channel descriptorจาก APaintภายใต้ clean contract
- ย้าย Normal Paint Freehand routeเดียวจาก View2D/View3D/automation

Exit:

- APaint routeที่ย้ายไม่เรียก GPUPainter/StrokeMan/LayerManager/backendโดยตรง
- preview/commit/undo/export parityผ่าน
- old route/fallbackของ sliceถูกลบเมื่อ consumerเป็นศูนย์
- A-Engineไม่มี dependencyกลับไป APaint product

### Phase 7 — Model editing and Sculpt feature packs

สร้างทีละ vertical proof:

- `aengine_geometry`: mesh selection, edit transaction, topology validation
- model editor reference app: select/move/extrudeหนึ่ง operationพร้อม undo/save
- sculpt session: begin/sample/preview/commit/cancel + GPU/CPU ownership contract
- sculpt reference app: one brush, one mesh, deterministic replay

Exit:

- model/sculpt applicationsใช้ App/View3D/Scene/Commands/Workflowsเดิม
- geometry mutationไม่ bypass transaction/history
- ไม่มี duplicate renderer/asset/app loopใน reference apps

### Phase 8 — Runtime/Game feature profile

สร้างเมื่อ foundation/editor proofsเสถียร:

- animation/skin/clip state API
- physics port + chosen backend adapter
- audio port + chosen backend adapter
- gameplay system/module lifecycle
- input mapping, level/session load และ fixed/variable update contracts
- small sample gameที่ใช้ add-on/moduleอย่างน้อยหนึ่งตัว

Exit:

- headless deterministic simulation test
- render/runtime separationและ editor-free buildพิสูจน์ได้
- game buildไม่ link editor/paint/sculpt modulesโดยปริยาย

### Phase 9 — Public SDK/ABI 1.0 and open-source release

ทำเมื่อ internal APIs dogfoodหลาย applicationแล้ว:

- versioned C ABI function tables + generated machine-readable API schema
- C++ convenience SDK และ optional C# SDKที่ generate interopจาก schemaเดียวกัน
- C++/C# templates และ external add-on/app examples
- compatibility hostสำหรับ previous supported minor version
- package/install/exported CMake targets
- contributor docs, security policy, license/SBOM และ reproducible release artifacts
- migrate/remove remaining APaint/AEngine donor adaptersตาม consumer-zero evidence

Exit:

- viewer, editor, APaint adoption proof, model/sculpt proof และ sample gameใช้ public
  A-Engine APIตาม scopeของตน
- external app/add-on buildนอก source treeผ่าน
- C++/C# workflow parity, interop layout/lifetimeและ packaging testsผ่าน
- ABI/API compatibility, dependency, shader, runtimeและ release gatesผ่าน

## 14. Per-slice ledger

ก่อน implement ทุก slice ต้องบันทึก:

| Field | Required |
| --- | --- |
| User outcome | use case ที่ game/app/APaint/add-on ทำได้หลัง slice |
| Transform | semantic change เดียว |
| Current owner/route | source/header/caller จริง |
| Target owner/API | interface, state และ lifetime |
| Invariants | behavior, ABI, GPU, history, format, latency |
| Consumers | migrated/remaining |
| Scope | exact files/symbols และ excluded paths |
| Baseline | focused/full results และ known failures |
| Verification | static/unit/integration/runtime/manual |
| Deletion condition | old path ที่ต้องเป็นศูนย์ |
| Rollback | smallest reversible checkpoint |

ห้ามเริ่ม slice ถ้า owner, lifetime, consumer inventory หรือ focused proof ยังไม่ทราบ

## 15. Verification strategy

Architecture นี้ลดการทดสอบวนด้วยการทำให้ failure อยู่ในชั้นที่ระบุได้ ไม่ได้ยกเลิก
การทดสอบ

| Level | Run when | Proof |
| --- | --- | --- |
| Header/static | ทุก API batch | self-contained headers, forbidden includes/links, ABI sizes |
| Contract/unit | ทุก low-level change | handles, state transitions, validation, plan equality, errors |
| Workflow integration | ทุก vertical slice | fake services, transaction/rollback, exact calls/receipts |
| Focused runtime guard | เมื่อเพิ่ม/ย้าย production caller | state/log/pixel/readback ของ route ที่ย้าย |
| Changed gate | จบ reviewable slice | cross-module regression ตาม changed scope |
| Full guard | milestone/pre-merge/release | A-Engine integration + guardของ reference productที่ได้รับผลกระทบ |
| Manual QA | input feel/visual/performance | named scenario + hardware/build identity |

กฎ:

- full guard ไม่ต้องรันหลังแก้เอกสารหรือทุก helper เล็ก
- failure ใน focused test ต้องหยุด slice ห้ามกลบด้วย full rerun ซ้ำ
- flaky pass ต้องถือเป็น reliability defectและเก็บ fingerprint/sequence
- fake backend proof ไม่แทน Vulkan runtime proof แต่ช่วยระบุว่า failure อยู่ workflow
  หรือ backend
- screenshot อย่างเดียวไม่พิสูจน์ commit/history/export

### 15.1 Mandatory engine/add-on tests

- stale/forged/wrong-type handle rejection
- transaction rollback และ double-commit rejection
- stroke duplicate terminal transition และ preview/commit equality
- job cancellation before submit, during GPU work และ after completion
- add-on version/dependency/capability rejection
- add-on deactivate/unload with active resource must be blocked
- callback throws/fails/returns invalid data without corrupting host state
- deterministic workflow trace replay
- no direct native symbol in SDK/public headers
- previous supported SDK minor version load test

## 16. API versioning and compatibility

- internal C++ interface เปลี่ยนได้ระหว่าง pre-1.0 แต่ทุก change ต้อง migrate consumer
  ใน slice เดียวกัน
- public add-on ABI ใช้ semantic versioning
- minor version เพิ่ม function ต่อท้าย function table/struct ที่มี `structSize`
- breaking layout/semantic change ต้อง major version
- capability แยกจาก version เพราะ backend/build edition อาจรองรับไม่เท่ากัน
- serialized project format version แยกจาก engine API version
- shader ABI version แยกจาก add-on ABI และต้องมี contract/guard ของตน
- deprecated API ต้องมี caller inventory, replacement และ removal release ชัดเจน

## 17. Security and stability boundaries

v1 native add-ons เป็น trusted in-process code จึงไม่สามารถกัน memory corruption หรือ
process crash ได้เต็มรูปแบบ Host ต้องลด blast radius ด้วย:

- validate manifest/API/capability ก่อน load
- scoped service tables
- host-owned resource tracking
- no native handles/internal pointers
- structured callback/error boundaries
- deterministic deactivate/unregister
- add-on ID ใน log/crash breadcrumb

untrusted marketplace add-on, script sandbox หรือ out-of-process worker เป็น design
slice แยกในอนาคต ห้ามอ้างว่า in-process ABI เป็น security sandbox

## 18. Stop lines

- ไม่สร้าง production scaffold ก่อน Phase 0 อนุมัติ platform/toolchain/build และ
  third-party provenance/SBOM policy
- ไม่ rewrite APaint หรือ copy legacy managersเข้า engine directoryทั้งก้อน
- ไม่ให้ `aengine_*` include/link APaint product targetหรือ borrow sibling source path
- ไม่สร้าง API/target/registry ที่ไม่มี production consumer ใน slice เดียวกัน
- ไม่สร้าง `EngineManager`, global service locator หรือ god facade
- ไม่สร้าง shader node authoring subsystem; shader source of truthต้องเป็น text
- ไม่เปิด public add-on ABI ก่อน internal dogfood ผ่านสอง consumer
- ไม่ expose Vulkan/VMA/ImGui/SDL/internal pointer ผ่าน SDK
- ไม่ให้ convenience API สร้าง route/semantics แยกจาก primitive API
- ไม่เปลี่ยน shader ABI, project format หรือ backend พร้อม structural slice เว้นแต่
  slice นั้น own contract และ verification ทั้งหมด
- ไม่คง legacy/new dual route หลัง deletion condition ผ่าน
- ไม่เพิ่ม tolerance, regenerate baseline หรือ silent fallback เพื่อให้ migrationผ่าน

## 19. Open questions requiring dedicated slices

คำถามเหล่านี้ห้ามเดารวมใน implementation แรก:

- contributor policy และ third-party license/provenance/SBOM policyภายใต้ MIT
- compiler, Windows/Linux/macOS และ GPU/driver support matrix รุ่นแรก
- ใช้ Flecs หลัง spike หรือเลือก ECS implementationอื่น
- internal scene serialization และบทบาทของ glTF/OpenUSD
- APaint รองรับหลาย document พร้อมกันใน v1 engine หรือเริ่ม one active document
- stable persistent ID format สำหรับ object/layer/material และ project merge
- public SDK v1 รองรับเฉพาะ Windows native add-onหรือข้าม platformทันที
- SDK UI ใช้ host widget description, ImGui compatibility layer หรือ panel webview
- custom paint/render extension เปิดระดับใดโดยไม่ผูก shader/backend ABI
- scripting language/binding สำหรับ gameplay/automation จะเลือกเมื่อใด
- physics และ audio backend รุ่นแรก
- add-on package signing/trust policy สำหรับ distribution
- crash isolation ต้องใช้ out-of-process worker ใน releaseใด

แต่ละคำถามต้องมี consumer, constraints, prototype และ acceptance test ก่อนตัดสิน

## 20. Definition of Done

Architecture Engine/API ถือว่าใช้งานได้จริงเมื่อ:

- `App::Init/Run/PumpFrame/Save/Quit` และ `View3D::Update` ใช้ได้จาก public C++ API
- viewer, editor, APaint adoption proof, model/sculpt proof และ sample gameใช้ API
  สาธารณะตาม phaseของตน โดยไม่ duplicate app/render/asset loop
- APaint product UI ใช้ High-level Workflow API สำหรับ migrated product-critical routes
- automation และ internal add-onsใช้ API เดียวกัน ไม่มี privileged hidden path
- Low-level public headersไม่มี native backend/UI dependencies
- Normal Paint View2D/View3D ใช้ session/projection/commit contractเดียวกัน
- persistent layer mutations ผ่าน command transactionและ undo/redo parity
- project/export workflowมี atomic/cancellable receipts และ round-trip evidence
- internal add-onsอย่างน้อยสองตัวผ่าน lifecycle/ownership tests
- external sample app/add-on buildนอก source treeด้วย exported packageได้
- C# sample appเรียก workflowเดียวกับ C++ และผ่าน ABI layout/lifetime/parity tests
- machine-readable API/command/component/shader schemasตรงกับ headers/runtime
- shader helperใหม่ถูกเพิ่มผ่าน pure library + compile/reflection/GPU/runtime proof
- public SDK compatibility suite ผ่านก่อนประกาศ API 1.0
- legacy direct routes/adaptersถูกลบตาม consumer-zero evidence
- architecture guard, focused runtime evidence และ milestone full guard ผ่าน
- license, third-party notices/SBOM, contributor/security policy และ reproducible
  artifactsพร้อมสำหรับ open-source release
- เอกสาร SDK, compiling examples, version matrix และ failure behaviorตรงกับ sourceจริง

จนกว่าจะครบเงื่อนไขเหล่านี้ ให้เรียกระบบว่า `engine migration` ไม่ใช่ stable public
engine/SDK
