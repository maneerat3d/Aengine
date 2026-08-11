# A-Engine High-level UI Architecture

Status: **normative Phase 0 UI ownership and API contract**

Architecture ID: `AE-HIGH-LEVEL-UI-IMGUI`

Reviewed: 2026-08-11

เอกสารนี้อ่านร่วมกับ
[`AENGINE_API_ARCHITECTURE.md`](AENGINE_API_ARCHITECTURE.md) และ
[`AENGINE_APAINT_BOUNDARY.md`](AENGINE_APAINT_BOUNDARY.md)
เพื่อกำหนด ownership ของ High-level UI API, Dear ImGui backend และ product UI ของ
APaint โดยไม่เปลี่ยน phase order ของ canonical architecture

API และชื่อ target ในเอกสารนี้เป็น target contract จนกว่า phase ที่มี consumer จริงจะ
เริ่ม implement ห้ามสร้าง scaffold ทั้งหมดล่วงหน้า

## 1. Decision

ใช้ architecture ดังนี้:

- **A-Engine เป็นเจ้าของ High-level UI API, UI host lifecycle, editor UI
  infrastructure และ canonical Dear ImGui backend รุ่นแรก**
- **APaint สร้าง product-specific panels, dialogs, workspaces, controllers และ
  presentation policy ด้วย A-Engine UI API**
- public A-Engine UI headers ห้าม expose `ImGuiContext`, `ImDrawList`, `ImTextureID`,
  SDL window/event pointer, Vulkan handle หรือ backend-owned descriptor
- Dear ImGui เป็น implementation/backend รุ่นแรกที่อนุมัติ ไม่ใช่ public API identity
- A-Engine ไม่ต้องรองรับ Qt, WebView หรือ UI backend หลายตัวในรุ่นแรก แต่ boundary ต้อง
  กัน implementation ownership และ native typesออกจาก APaint
- High-level UI API ต้องเน้น semantic components และเพิ่ม immediate primitives เท่าที่
  consumerจริงต้องใช้ ห้ามสร้าง wrapper 1:1 ครบทุกฟังก์ชันของ ImGui
- UI ทำหน้าที่แสดง snapshot และส่ง user intent ไป controller/workflow ห้ามเป็น owner
  ของ persistent domain mutation

สรุป dependency direction:

```text
APaint Product UI
  panels / dialogs / workspaces / controllers / view models
                         |
                         v
       A-Engine High-level UI + Editor UI APIs
                         |
             +-----------+-----------+
             |                       |
             v                       v
 A-Engine Workflows/Queries     A-Engine UI Host
                                     |
                                     v
                         Dear ImGui Backend
                                     |
                         SDL3 + Render/Vulkan integration
```

เส้นทางย้อนกลับและ bypass ต่อไปนี้ห้ามเกิดใน migrated routes:

```text
A-Engine UI -> APaint product headers
A-Engine UI public API -> ImGui/SDL/Vulkan native types
APaint panel -> Vulkan descriptor or ImTextureID ownership
UI widget -> direct manager/domain mutation
A-Engine backend -> APaint panel or product policy
```

## 2. Module ownership

ชื่อ target ต่อไปนี้สร้างเมื่อมี consumer ใน vertical slice เท่านั้น

### 2.1 `aengine_ui`

เป็นเจ้าของ backend-neutral High-level UI contracts และ UI host mechanism เช่น:

- UI frame/session contract และ registered UI surface lifetime
- panel/window registration และ visibility state contract
- docking intent, workspace slot และ layout persistence primitives
- menu, toolbar, status bar และ command presentation
- modal, popup, notification และ progress presentation
- semantic property grid, table, tree, list และ form descriptors
- limited immediate UI primitives สำหรับ custom content ที่ semantic APIยังไม่ครอบคลุม
- focus, keyboard navigation, shortcut routing และ stable UI test IDs
- style tokens, spacing, typography roles และ icon identity contracts
- opaque UI texture/viewport presentation handle
- UI diagnostics, invalid-handle reporting และ deterministic interaction trace

`aengine_ui` public API ต้อง buildได้โดยไม่ include Dear ImGui, SDL3, Vulkan, VMA หรือ
APaint product headers

### 2.2 `aengine_ui_imgui`

เป็น private/concrete implementation ของ `aengine_ui` สำหรับ Dear ImGui และเป็น owner
ของรายละเอียดต่อไปนี้:

- `ImGuiContext`, `ImGuiIO`, `ImDrawData` และ Dear ImGui lifecycle
- font atlas creation/upload และ backend font resources
- docking implementation และ translation จาก A-Engine layout intent
- SDL3 event/input forwarding สำหรับ UI
- rendering integration และ submission ของ ImGui draw data
- mapping จาก A-Engine opaque texture/view handle ไป `ImTextureID`
- Vulkan descriptor/image-view lifetime ที่ต้องใช้สำหรับ UI texture presentation
- backend cache, in-flight resource retention และ shutdown ordering

APaint และ public SDK ห้ามสร้าง เก็บ ทำลาย หรือ cache object เหล่านี้เอง

### 2.3 `aengine_editor`

สร้างบน `aengine_ui` สำหรับ reusable DCC/editor mechanisms ที่มี consumerจริง เช่น:

- editor shell และ workspace host
- viewport panel/overlay host
- hierarchy, inspector และ property presentation framework
- selection presentation และ gizmo integration
- command palette และ editor command contribution
- panel/menu/toolbar extension registry
- asset browser frameworkเมื่อมี consumerจริง

`aengine_editor` ห้ามเป็น owner ของ APaint layer semantics, brush catalog, export preset
หรือ `.apaint` project policy

### 2.4 APaint product UI

APaint เป็นเจ้าของสิ่งต่อไปนี้:

- product panel/dialog/workspace definitions และ content composition
- Layer, Brush, Material, Channel, Mask, Bake, Export และ Project UI
- default panel arrangement, visible panels และ APaint workspace presets
- APaint icons, theme values, labels, tooltips และ localization content
- view models, controllers และ action interfacesที่แปลง user intentเป็น product workflow
- active tool/channel/brush/material/target presentation policy
- product commands เช่น workspace/tool/channel/export actions
- brush/material preset browser, favorites, thumbnails และ catalog metadata

APaint ใช้ A-Engine UI API เพื่อประกอบหน้าจอ แต่ไม่เป็น owner ของ UI frame lifecycle,
Dear ImGui context, SDL3 event bridge หรือ Vulkan resourcesสำหรับวาด UI

## 3. Public API levels

A-Engine UI มีสองระดับที่ลง backend execution path เดียวกัน

### 3.1 Semantic High-level API

ใช้เป็น default สำหรับ application และ add-on UI:

```cpp
ui.RegisterPanel({
    .id = PanelId{"apaint.layers"},
    .title = "Layers",
    .defaultDock = DockArea::Right,
}, layerPanelController);

ui.MenuBar(menuModel);
ui.Toolbar(toolbarModel);
ui.PropertyGrid(propertyModel, propertyActions);
ui.ShowModal(exportDialogModel, exportDialogActions);
ui.Notify(notification);
```

semantic API อธิบาย intent, identity, state และ action ไม่ expose widget backend

### 3.2 Limited immediate API

ใช้เมื่อ panel content ต้องจัด layout/custom interaction ที่ semantic componentยังไม่
ครอบคลุม:

```cpp
void APaintBrushPanel::Draw(
    AEngine::UI::Context& ui,
    const BrushPanelViewModel& model,
    IBrushPanelActions& actions)
{
    ui.BeginHorizontal();
    ui.Text("Size");
    if (ui.SliderFloat(WidgetId{"brush.size"}, model.size, 1.0f, 500.0f)) {
        actions.SetBrushSize(model.size);
    }
    ui.EndHorizontal();
}
```

กฎ:

- เพิ่ม primitive ตาม consumerจริง ไม่ mirror Dear ImGui APIทั้งหมด
- widget ทุกตัวที่มี interactionสำคัญต้องมี stable `WidgetId`
- return value แสดง user intent/interaction ไม่ mutate domain ownerเอง
- backend-specific flagsต้องไม่รั่วเป็น integer bitmaskใน public API
- escape hatch ที่รับ raw ImGui callback/typeไม่เป็น public/stable API

## 4. Product UI composition pattern

แยกอย่างน้อยสาม responsibility:

```text
Panel/View
  -> emits user intent
APaint Controller/Product Workflow
  -> applies APaint policy and builds requests
A-Engine Domain Workflow
  -> validates, mutates, records command/history and returns receipt
```

ตัวอย่าง:

```cpp
class LayerPanel {
public:
    void Draw(AEngine::UI::Context& ui,
              const LayerPanelViewModel& model,
              ILayerPanelActions& actions);
};

class APaintLayerController final : public ILayerPanelActions {
public:
    void CreateLayer() override {
        layerWorkflow_.CreatePaintLayer(BuildAPaintDefaultLayerRequest());
    }

private:
    AEngine::ILayerWorkflow& layerWorkflow_;
};
```

`LayerPanel` ไม่อ่าน `LayerMan`, mutable `Layer*` หรือ Vulkan resources ส่วน controller
เป็น owner ของ APaint defaults และเรียก canonical A-Engine workflow

## 5. State ownership

| State | Owner |
| --- | --- |
| panel open/closed, dock placement, scroll, popup, hover, temporary edit buffer | A-Engine UI host หรือ APaint UI sessionตาม contract |
| APaint workspace choice, active tool/channel/brush preset, export preset | APaint product state |
| layer hierarchy/opacity, scene objects, document revision, stroke session, job state | A-Engine domain/workflow owner |
| `.apaint` serialization of product settings/workspace references | APaint project schema |
| ImGui context/font atlas/draw lists/texture descriptor mapping | `aengine_ui_imgui` |

UI ห้ามเก็บ mutable domain modelสำเนาที่เปลี่ยนแยกจาก canonical owner ให้ใช้ immutable
snapshot/revision และส่ง actionกลับ controller/workflow

ตัวอย่างต้องห้าม:

```text
LayerPanel::localLayers
LayerMan::layers
Document::layers
```

ตัวอย่างที่ต้องการ:

```cpp
auto snapshot = layerQuery.GetSnapshot(document);
layerPanel.Draw(ui, BuildViewModel(snapshot), layerActions);
```

## 6. Viewport and texture presentation

APaint ห้ามรับ `VkImageView`, descriptor set หรือ `ImTextureID` เพื่อแสดง View2D/View3D

public UI API ใช้ opaque handle:

```cpp
ui.Viewport({
    .id = WidgetId{"apaint.view3d"},
    .source = view3D.OutputTexture(),
    .interaction = ViewportInteraction::CameraAndPaint,
});
```

ownership route:

```text
A-Engine Texture/View Handle
  -> render backend resource
  -> UI backend presentation registration
  -> Dear ImGui descriptor / ImTextureID
```

กฎ:

- stale/released handleต้อง fail closedพร้อม structured diagnostic
- UI backend retain resourceตาม in-flight frame rule ไม่ให้ APaintเดา fence lifetime
- resize/recreateใช้ handle revision/generation ไม่ reuse native descriptorแบบเงียบ
- UI presentation registrationไม่ให้สิทธิ์ caller mutate texture/resource

## 7. Commands, menus and shortcuts

UI infrastructureควร bind presentationกับ command identity:

```cpp
ui.MenuItem({
    .command = CommandId{"history.undo"},
    .label = "Undo",
    .shortcut = Shortcut{"Ctrl+Z"},
});
```

A-Engine command presentationอาจให้ enabled/checked/label/shortcut state ส่วน execution
ต้องผ่าน command/workflow owner

แบ่ง identity ดังนี้:

- generic engine commands เช่น `history.undo`, `document.save`, `layer.create`
- APaint product commands เช่น `apaint.tool.brush`, `apaint.channel.normal`,
  `apaint.workspace.painting`, `apaint.export.texture_set`

APaint commandสามารถเติม product defaultsแล้ว delegateไป A-Engine workflow แต่ห้ามสร้าง
persistent mutation routeคู่แข่ง

## 8. UI extension boundary

generic add-on UI ใช้ A-Engine panel/menu/command/property extension contracts

APaint-specific extension เช่น brush catalog, paint channel tool หรือ export presetใช้
APaint extension contract ซึ่งประกอบบน A-Engine generic UI/Add-on infrastructureอีกชั้น

```text
APaint Add-on
  -> APaint Product Extension API
  -> A-Engine UI/Add-on API
  -> Dear ImGui Backend
```

add-onไม่ได้รับ ImGui/Vulkan/manager pointerจาก host และ lifecycleต้อง unregister panels,
commands, callbacks และ presentation resourcesก่อน unload

## 9. Verification

UI vertical slice ต้องมี evidence ตาม scope:

| Evidence | Required proof |
| --- | --- |
| Header/static | public UI headersไม่มี `imgui.h`, SDL/Vulkan/VMA/APaint includes |
| Contract | duplicate/stale panel/widget/texture handlesถูก reject |
| Lifecycle | init, frame begin/end, panel unregister และ shutdown order deterministic |
| Command | menu/shortcut dispatchลง canonical command/workflow routeเดียวกัน |
| State | snapshot revisionและcontroller actionsไม่สร้าง duplicate persistent state |
| Backend | ImGui context/font/descriptor resourcesถูกสร้างและทำลายโดย backend owner |
| Viewport | resize/recreate/in-flight texture presentationไม่ใช้ stale descriptor |
| Interaction | stable widget IDsและ deterministic action traceสำหรับ focused UI test |
| Runtime | SDL3 input, docking, modal, notification และ viewport renderทำงานใน reference app |
| Manual | layout, visual hierarchy, focus, keyboard navigation และ interaction feel |

screenshotอย่างเดียวไม่พิสูจน์ command dispatch, state ownership หรือ texture lifetime

## 10. Initial vertical slice

ห้ามสร้าง widget catalogหรือ editor frameworkเต็มระบบล่วงหน้า UI sliceแรกควรมี:

1. `UiHost` lifecycleผูกกับ `App` frame lifecycle
2. Dear ImGui backend initialization/shutdown
3. main dockspace และ panel registration
4. menu/command binding
5. text, button, selectable, slider, tree/table/property rowขั้นต่ำ
6. modal และ notification
7. opaque texture/`ViewportWidget` integration
8. stable UI IDs และ focused interaction trace
9. reference viewer/editor panelหนึ่งตัวเป็น consumer
10. APaint panelหนึ่งตัวเป็น migration consumerถัดไป

สิ่งที่ยังไม่สร้างจนมี consumerจริง: node editor, timeline, animation editor, complete
asset browser, visual UI designer และ wrapperครบทุก Dear ImGui function

## 11. Phase alignment

- Phase 2 สร้าง application/platform lifecycle และ window/input portsก่อน
- Phase 4 อาจสร้าง minimal `UiHost` + Dear ImGui backend + viewport presentation เมื่อ
  viewerเป็น consumerจริงและ renderer lifecycleพร้อม
- Phase 5 ขยาย High-level UI/editor APIs ผ่าน reference editor, command และ internal
  add-on consumers
- Phase 6 ย้าย APaint panelsทีละ routeให้ใช้ A-Engine UI + workflow contracts พร้อม
  parity evidenceและลบ direct ImGui/product-manager routeเมื่อ consumerเป็นศูนย์
- public add-on UI ABI freezeหลัง internal UI consumersและlifecycle testsผ่าน

## 12. Stop lines

- ไม่ expose `ImGui*`, SDL, Vulkan, VMA หรือ backend descriptorใน public UI API
- ไม่สร้าง `UIMan`, global UI service locator หรือ `DrawEverything()` god facade
- ไม่ให้ UI widget mutate document/layer/paint/GPU ownerโดยตรง
- ไม่ duplicate persistent stateใน panel/view modelและ domain owner
- ไม่ wrap Dear ImGui APIแบบ 1:1 ทั้งชุดโดยไม่มี consumerและsemantic value
- ไม่ให้ APaint own UI renderer resourcesหรือ texture descriptor lifetimeใน migrated route
- ไม่ย้าย APaint panel content/product policyเข้า A-Engineเพียงเพราะใช้ widgetกลาง
- ไม่เปิด raw ImGui escape hatchเป็น stable add-on API
- ไม่คง direct ImGui pathกับ A-Engine UI pathคู่กันหลัง deletion conditionผ่าน
- ไม่อ้าง backend-neutralเพื่อบังคับสร้างหลาย UI backendก่อนมี requirement

เป้าหมายคือให้ A-Engine เป็นเจ้าของ UI mechanism และ Dear ImGui integration ขณะที่
APaint เป็นเจ้าของ product experienceและสร้างหน้าจอผ่าน High-level API โดยไม่มี native
UI/render ownershipรั่วข้าม boundary
