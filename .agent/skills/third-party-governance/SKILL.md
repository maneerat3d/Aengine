---
name: third-party-governance
description: Govern A-Engine third-party dependencies, provenance, licenses, version locks, public-boundary isolation, and SBOM gates.
---

# Third-Party Governance

Use before adding, upgrading, replacing, vendoring, downloading, or linking any third-party dependency or binary tool.

## Required sources

Read `docs/PHASE_0_APPROVAL.md`, `docs/AENGINE_API_ARCHITECTURE.md`, and the repository license/provenance policy.

## Hard gate

P0-07 must be resolved in the same slice that introduces the first third-party dependency: select and validate the approved SPDX JSON/JSON-LD serialization and SBOM generator before the dependency enters production use.

## Dependency record

Record name, exact version/revision, upstream URL, license expression, copyright/notice obligations, acquisition method, integrity hash when applicable, owner, consumer target, update policy, and public/private exposure.

## Rules

- Repository MIT license never relicenses imported code/assets/binaries.
- Prefer dependencies as private implementation details.
- Public SDK headers must not expose dependency ABI types or allocator ownership.
- Pin reproducible versions; avoid floating branches/tags or `latest` acquisition.
- Do not copy donor/source code merely because it is available; provenance and license compatibility are mandatory.
- Keep one canonical dependency acquisition route and lock state.
- Reject a dependency when its responsibility overlaps an existing owner without a clear consolidation plan.

## Validation

Build the real consumer, run license/provenance checks and relevant architecture guards, verify resolved version/hash, and ensure dependency removal leaves a defined adapter/owner boundary rather than leaking through public contracts.
