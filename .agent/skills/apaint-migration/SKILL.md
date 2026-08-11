---
name: apaint-migration
description: Study APaint as donor/reference evidence and migrate reusable behavior into A-Engine through explicit ownership, adapters, characterization tests, and deletion conditions.
---

# APaint Migration

Use whenever inspecting APaint for reuse, moving behavior from APaint, introducing an adapter between repositories, or consolidating a duplicated route.

## Required sources

Read `docs/AENGINE_APAINT_BOUNDARY.md`, `docs/AENGINE_API_ARCHITECTURE.md`, `docs/CODE_SHAPE_POLICY.md`, and the relevant APaint feature contract/source path.

## Reference workflow

Reference -> understand responsibility/problem/trade-off -> compare current A-Engine/APaint ownership -> design A-Engine-native contract -> implement new C++/backend code -> characterize/validate -> migrate consumer -> delete obsolete route.

## Rules

- APaint is donor/reference evidence, never an A-Engine dependency.
- Do not copy manager trees, implementation blocks, shaders, or translate C#/other donor code line-for-line.
- Before migration record provenance/license, current call path, consumer inventory, source owner, target owner, contract, tests, remaining legacy consumers, and deletion condition.
- If product policy cannot yet be separated from reusable mechanism, leave it in APaint and add characterization evidence first.
- Move one route at a time through an explicit adapter; do not keep legacy/new active state once consumers reach zero.
- Never create duplicate document/layer/paint/GPU ownership across APaint and A-Engine.
- APaint product semantics such as workspace/default/theme/`.apaint` policy remain product-owned unless a reusable engine contract is explicitly approved.

## Validation

Compare behavior against characterization evidence, run A-Engine focused tests/guards and relevant APaint regression lanes, and require human QA only for visual/brush-feel/product behavior automation cannot decide.
