# A-Engine Agent Skills

Skills in this directory are focused procedural overlays for AI contributors. They do not replace canonical architecture or source-of-truth documents.

Authority order remains:

1. current production source for implemented behavior;
2. `AGENTS.md`;
3. canonical documents under `docs/`;
4. relevant skill in this directory;
5. tests/evidence and reference material as defined by the canonical architecture.

Load only the skills relevant to the current slice:

| Skill | Use when |
| --- | --- |
| `software-architecture` | module boundaries, ownership, lifecycle, composition root, new subsystem or Phase planning |
| `cpp-api-contracts` | public C++ headers, Result/Error, handles, ABI-facing values, service interfaces |
| `validation-evidence` | build/test/CI, regression evidence, failure triage, completion claims |
| `third-party-governance` | first or changed dependency, license/provenance, lock/SBOM policy |
| `vulkan-backend` | renderer/backend, GPU resource lifetime, synchronization, shader/pipeline implementation |
| `ui-architecture` | High-level UI API, ImGui backend, panel/menu/viewport infrastructure |
| `apaint-migration` | APaint donor/reference study, adapter migration, ownership transfer |

Do not load every skill by default. Small context and explicit ownership make AI review more reliable.
