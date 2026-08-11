# A-Engine / APaint Ownership Boundary

Status: **normative Phase 0 ownership and migration contract**

Architecture ID: `AE-APAINT-OWNERSHIP-BOUNDARY`

Reviewed: 2026-08-11

เอกสารนี้อ่านร่วมกับ [`AENGINE_API_ARCHITECTURE.md`](AENGINE_API_ARCHITECTURE.md)
และกำหนดว่า responsibility ใดควรอยู่ใน A-Engine หรือ APaint ระหว่างการสร้าง engine
และ migration จาก donor application โดยไม่เปลี่ยน phase order ของ canonical
architecture

หากเอกสารนี้ขัดกับ canonical architecture ให้หยุด implementation และแก้ decision
ให้ตรงกันก่อน ห้ามเลือกข้อความที่สะดวกกว่าเพื่อเดิน production change ต่อ

## 1. Decision

ใช้หลัก ownership ดังนี้:

- **A-Engine เป็นเจ้าของ reusable mechanism, backend-neutral contract และ generic
  execution infrastructure** ที่สามารถทำงานได้โดยไม่รู้จัก APaint product state
- **APaint เป็นเจ้าของ product experience, product policy, presets, workspace และ
  `.apaint` project/document schema**
- optional capability เช่น paint, editor และ geometry อยู่เป็น **A-Engine feature
  pack** ไม่ใช่ foundation ที่ game/viewer ทุกตัวต้อง link
- A-Engine ห้าม include, link, load หรือ query APaint product target เพื่อให้ตัวเองทำงาน
- APaint เรียก A-Engine ผ่าน public API/workflow ของ route ที่ migrate แล้วเท่านั้น
- legacy adapter ใช้ได้ชั่วคราวใน migration slice แต่ต้องมี consumer inventory และ
  deletion condition ชัดเจน

สรุป dependency direction:

```text
APaint UI / Product Workflow / Project Schema
                    |
                    v
        A-Engine High-level Workflows
                    |
                    v
 A-Engine Core + Optional Feature Packs + Render Intent
                    |
                    v
      Platform / Vulkan Backend Implementations
```

เส้นทางย้อนกลับต่อไปนี้เป็น forbidden dependency:

```text
A-Engine -> APaint
A-Engine -> APaint manager aggregate
Renderer/Vulkan backend -> APaint UI or project policy
Paint feature -> APaint preset browser or .apaint schema
```

## 2. Placement categories

### 2.1 A-Engine Core

Core คือ capability ที่ application profile ขั้นต่ำใช้ร่วมกันได้ และต้อง build/test ได้
โดยไม่ต้อง link APaint, paint, editor หรือ sculpt feature

| Area | A-Engine Core owns |
| --- | --- |
| Foundation | `Result<T>`, structured errors, operation IDs, typed/generational handles, versions, capabilities |
| Application | init/run/pump/quit lifecycle, composition root contract, deterministic shutdown order |
| Platform | window/input/time/filesystem ports และ platform adapters |
| Jobs | async tickets, progress, cancellation, terminal receipts และ callback delivery rules |
| Diagnostics | logs, traces, build identity, failure fingerprints และ crash breadcrumbs |
| World/Scene | entity/object/transform/camera/light/mesh/material identities และ immutable snapshots |
| Assets | asset URI, import/decode job, dependency/cache identity และ failure cleanup |
| Commands | mutation transaction, undo/redo, rollback, command receipt และ revision conflict |
| Render API | opaque texture/buffer/resource identities, render/compute/readback intents และ tickets |
| Shader | source/include/compile/reflection/cache/ABI validation และ reusable pure GLSL library |
| Renderer | render pass/pipeline/effect orchestration, resource lifetime และ frame submission |
| Backend | Vulkan device/resources/descriptors/barriers/queues/synchronization behind private implementation |
| Viewport | backend-neutral `View3D`/capture/resize/camera/render intent contracts |

Core public API ห้ามมี APaint name, `.apaint` schema, brush preset catalog, active paint
layer policy หรือ native Vulkan/SDL/ImGui types

### 2.2 A-Engine optional feature packs

Feature packs ใช้ Core contracts แต่ไม่ถูก link โดย default ใน viewer/game profile

#### `aengine_paint`

เป็นเจ้าของ reusable paint mechanism เช่น:

- typed stroke lifecycle: Begin / Append / Commit / Cancel
- stroke spacing/interpolation และ deterministic sample identity
- brush snapshot, tip sampling และ pressure/dynamics contract
- projection plan, paint footprint และ target validation
- logical material channel descriptors และ multi-channel payload
- Color/Scalar/Normal/Height blend policies
- transient preview, dirty region และ preview/commit equality contract
- backend-neutral paint execution plan และ render intent
- paint history transaction/receipt integration
- reusable paint shader programs/helpersที่ไม่ผูก APaint UI/preset/schema

`aengine_paint` ไม่เป็นเจ้าของ active toolbar selection, brush categories, APaint default
channels, export packing preset หรือ `.apaint` serialization

#### `aengine_editor`

พิจารณาเป็นเจ้าของเฉพาะ editor mechanism ที่มี consumer จริง เช่น viewport host,
selection snapshot, gizmo, inspector/property descriptor, command palette และ extension
registration

ห้ามย้าย APaint ImGui panels ทั้งก้อนเพื่อประกาศว่าเป็น generic editor framework
ก่อนมี narrow contract และ consumer ที่พิสูจน์ reuse

#### `aengine_geometry`

พิจารณาเป็นเจ้าของ mesh query, topology validation, BVH/spatial query, mesh edit
transaction, generic bake geometry และ sculpt session primitive ที่ไม่ผูก product UI

Bake preset, output naming, export channel policy และ human workflow ยังเป็นของ APaint

### 2.3 APaint product

APaint เป็น product shell และ owner ของสิ่งต่อไปนี้:

- menus, toolbars, panels, dialogs, docking/workspace layout และ shortcuts
- active tool/layer/material/channel/paint-target presentation state
- product defaults เช่น texture resolution, initial channels, layer creation และ blend
  defaults
- brush/material preset catalog, categories, favorites, thumbnails และ marketplace
  metadata
- `.apaint` document/project schema, migrations, autosave/recovery และ recent projects
- APaint-specific channel packing, export presets, naming rules และ output layout
- onboarding, product telemetry, help text, icons, theme, templates, sample assets และ
  default environment/look presets
- product orchestration ที่เชื่อม user intent กับ A-Engine workflows

A-Engine อาจให้ generic URI, atomic file transaction, serialization primitives,
readback/export jobs และ command infrastructure แต่ APaint ยังคงเป็น owner ของ schema
และ policy ที่บอกว่าไฟล์ APaint หมายถึงอะไร

### 2.4 Temporary migration adapters

Adapter อยู่ใน APaint หรือ migration integration layer ไม่ใช่ public A-Engine SDK

ตัวอย่าง:

```text
APaint UI
  -> A-Engine PaintWorkflow
     -> LegacyPaintAdapter
        -> current APaint implementation
```

Adapter ต้องมี:

- current caller/consumer inventory
- exact donor symbols/filesที่ห่ออยู่
- behavior/invariant ที่รักษา
- diagnostics แยก legacy/new route
- focused parity tests
- deletion condition และ target phase

เมื่อ migrated consumer เป็นศูนย์ต้องลบ adapterและ old route ห้ามคงสอง semantics
เพราะต้องการ fallback ที่ไม่มี owner

## 3. APaint subsystem migration target

ตารางนี้เป็น placement target ไม่ใช่คำสั่งให้ย้าย class เดิมทั้ง class แต่ละ manager
ต้องแยก responsibility และย้ายทีละ route

| APaint subsystem | Candidate A-Engine ownership | Must remain APaint product ownership |
| --- | --- | --- |
| `PaintMan` | paint execution/session/render intent primitives | active product orchestration, APaint defaults และ UI integration |
| `StrokeMan` | stroke state machine, spacing/interpolation, sample identity | input binding, product telemetry และ UI feedback |
| `BrushMan` | brush snapshot, tip/dynamics contracts | preset browser, categories, favorites, thumbnails และ catalog metadata |
| `ToolMan` | tool/session interface and capability contract | toolbar selection, shortcuts และ product tool policy |
| `LayerMan` | reusable layer query/commands only after semantics and consumer are proven | layer panel, active layer presentation, APaint defaults และ project binding |
| `CompositorMan` | composite plan, blend execution, dirty-region/resource scheduling | APaint channel graph, packing/export policy และ display choices |
| `MaterialMan` | generic PBR material/channel descriptors | APaint paint-material presets และ material UI |
| `MaskMan` | generic mask resource/operation contracts | mask panels, project bindings และ APaint defaults |
| `RenderMan` | renderer/render API/backend implementation | APaint render profile and product presentation settings |
| `PBRMan` | generic PBR renderer and shader library | viewport look presets and APaint-specific display workflow |
| `BakeMan` | generic bake execution, geometry inputs, tickets/readback | bake UI, presets, output naming และ export policy |
| `QueryMan` | picking/query/readback services | APaint selection and active-target policy |
| `GBufferMan` | renderer-owned G-buffer resources/passes | APaint debug panel and display-channel selection |
| `SceneMan` | scene/object/camera/mesh/material contracts | active paint object/material slot and project presentation state |
| `ComMan` | command transaction, undo/redo and receipts | APaint command definitions, labels, shortcuts and product grouping |
| `SparseMan` | sparse/virtual texture infrastructure after a real consumer slice | APaint sparse-paint settings and product policy |
| `ProjectMan` | URI, async IO, atomic write and generic package primitives | `.apaint` schema, migrations, autosave naming and recent-project behavior |

## 4. Decision test for new or migrated code

ก่อนเลือก placement ให้ตอบคำถามตามลำดับ:

1. **Product independence** — behavior ทำงานได้โดยไม่อ่าน APaint UI state, presets,
   globals หรือ `.apaint` schemaหรือไม่
2. **Responsibility** — code กำหนด generic mechanism หรือกำหนดว่า APaint ต้องให้ผู้ใช้
   ทำงานอย่างไร
3. **Boundary** — public contract สามารถใช้ opaque/typed values โดยไม่เปิด manager,
   raw pointer หรือ `Vk*` typesหรือไม่
4. **Current consumer** — มี production/reference consumer ใน vertical slice เดียวกัน
   และมี focused proofหรือไม่
5. **Ownership/lifetime** — owner, state transition, thread/queue, resource lifetime และ
   terminal cleanup ระบุได้หรือไม่
6. **Migration exit** — ระบุ old caller route และ deletion condition ได้หรือไม่

ผลตัดสิน:

- generic mechanism + explicit contract + current consumer/proof -> A-Engine Core หรือ
  feature packตาม profile
- product UX/policy/schema/preset -> APaint
- ยังแยก owner หรือ contract ไม่ได้ -> คงไว้ใน APaint และทำ characterization sliceก่อน

การมี consumer ตัวที่สองช่วยยืนยัน abstraction แต่ไม่ใช่เงื่อนไขบังคับ A-Engine feature
สามารถเริ่มจาก consumerจริงหนึ่งตัวได้ หาก contract ไม่ผูก product และมี test/deletion
condition ครบ ห้ามสร้าง abstraction เพียงเพราะคาดว่าอาจ reuse ในอนาคต

## 5. Required migration workflow

ทุก APaint adoption slice ใช้ flow ต่อไปนี้:

```text
Inspect current APaint route
  -> record owner/callers/state/lifetime/invariants
  -> select one product outcome
  -> define narrow A-Engine contract
  -> implement behind adapter or new owner
  -> migrate one real consumer
  -> run focused parity/runtime evidence
  -> remove migrated legacy route when consumer reaches zero
```

Per-slice ledger ต้องระบุอย่างน้อย:

| Field | Required content |
| --- | --- |
| User outcome | สิ่งที่ผู้ใช้ APaint ทำได้หลัง slice |
| Current owner | donor files/symbols/call pathจริง |
| Target placement | A-Engine Core, feature pack, APaint หรือ temporary adapter |
| Product policy | policy ที่ต้องคงอยู่ APaint |
| Invariants | preview/commit, undo/history, channel/format, latency, failure behavior |
| Dependencies | allowed/forbidden dependency direction |
| Consumers | migrated and remaining callers |
| Verification | unit/contract/integration/runtime/manual evidence |
| Deletion condition | old path/adapterที่ต้องถูกลบ |

## 6. Reference flows

### 6.1 Paint stroke

```text
APaint input adapter/UI
  -> APaint validates product selection/policy
  -> A-Engine PaintWorkflow preflight
  -> aengine_paint session/projection/execution plan
  -> A-Engine render intent
  -> Vulkan backend submit/sync
  -> paint commit receipt
  -> APaint updates UI/project dirty presentation
```

A-Engine เป็น owner ของ stroke semantics และ execution mechanism ส่วน APaint เป็น
owner ของสิ่งที่ผู้ใช้เลือกและวิธีแสดงผล product state

### 6.2 Project save

```text
APaint builds .apaint document snapshot/schema payload
  -> A-Engine generic async IO / atomic file transaction
  -> terminal save receipt
  -> APaint updates recent-project/autosave/product status
```

A-Engine ห้ามตีความ `.apaint` layer/channel/preset semantics

### 6.3 Export

```text
APaint selects preset, channel packing and output naming
  -> A-Engine export/composite/readback jobs
  -> generic encoder/file transaction
  -> APaint presents product report and remembers preset
```

## 7. Stop lines

- ไม่ย้าย APaint manager tree หรือ manager aggregate เข้า A-Engine ทั้งก้อน
- ไม่สร้าง `AEngineManager`, `APaintApi` god facade หรือ global service locator
- ไม่ duplicate active state/ownership ระหว่าง APaint กับ A-Engine
- ไม่ให้ A-Engine public header expose Vulkan, SDL, ImGui, Flecs implementation หรือ
  mutable product pointers
- ไม่ย้าย APaint panel, preset catalog, product defaults หรือ `.apaint` schemaเข้า Core
- ไม่ทำ generic abstractionโดยไม่มี current consumer, contract และ focused proof
- ไม่คง legacy/new routeหลัง deletion conditionผ่าน
- ไม่ใช้ silent fallback เพื่อซ่อน capability, migration หรือ runtime failure
- ไม่ refactor subsystemอื่นนอก migration sliceเพียงเพื่อจัด directoryให้ดูสะอาด

## 8. Phase alignment

- Phase 1-4 สร้าง Core mechanisms โดยใช้ `aengine_info` และ glTF viewer เป็น consumers
- Phase 5 สร้าง command/workflow/editor mechanismsเฉพาะที่ reference editorใช้จริง
- Phase 6 เริ่ม `aengine_paint` จาก APaint routeเดียวพร้อม parity evidence
- APaint product UI/schema/presetsยังอยู่ APaintตลอด migration
- public SDK/ABI freezeเกิดหลัง internal dogfoodและ ownership boundaryผ่าน testsแล้ว

เป้าหมายไม่ใช่ย้าย APaint ไปอีก repository แต่คือทำให้ reusable mechanism มี owner
ชัดเจน ขณะที่ APaint ยังคงเป็นผลิตภัณฑ์ที่ควบคุม UX, policy และ project semanticsของตนเอง
