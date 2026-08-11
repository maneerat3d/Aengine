---
name: validation-evidence
description: Validate A-Engine changes with focused tests, canonical self-hosted Windows CI, fail-fast evidence, and reproducible failure reporting.
---

# Validation and Evidence

Use for build/test work, CI changes, failure triage, regression proof, or any completion claim.

## Canonical environment and command

Follow `AGENTS.md`, `README.md`, and `.github/workflows/windows-x64.yml`. The normal build/test entrypoint is repository-root `build.bat` only. Phase 1 baseline is Windows x64, Visual Studio 2022 17.14, MSVC 19.44/toolset 14.44, Windows SDK 10.0.26100.0, CMake presets, and Ninja behind that entrypoint.

Do not invoke `cmake`, `ninja`, `ctest`, or AI-map PowerShell scripts directly during normal agent work. Direct invocation is allowed only while diagnosing or maintaining the build/generator path, and final validation must return to `build.bat`.

## Forward-only validation

1. Identify changed files, affected owner/subsystem, focused tests, and architecture guards using the AI code map.
2. Use `build.bat test <regex>` for the smallest relevant focused test when appropriate.
3. On failure, preserve the first useful failure evidence and reproduce that check through `build.bat` unless debugging the build entrypoint itself.
4. Fix the root cause; do not weaken tests, baselines, maps, or guards merely to get green.
5. Rerun the failed check, then affected validation, then repository-root `build.bat` for final Debug+Release evidence when the slice requires completion.
6. Do not repeat previously valid evidence unless a later change invalidates it.

## Required guards

Keep `aengine.architecture.guard`, `aengine.architecture.source_shape`, `aengine.architecture.agent_skills`, `aengine.architecture.ai_code_map`, public-header self-containment, focused contract tests, and real consumer proof relevant to the slice.

## AI map evidence

`build.bat` fingerprints source/CMake/tests/module manifests, regenerates the AI code map only when inputs change, and writes generated files only when navigation structure changes. CI must fail when committed `.agent/code-map/current` is stale. Commit generated map changes in the same slice; never hand-edit generated map files.

## Completion

Do not report a slice complete while a relevant check is failed, blocked, or not run unless the maintainer explicitly accepts that exception. Report branch/commit, toolchain, `build.bat` result, tests/guards, failure fingerprint when applicable, generated-map state, and remaining human QA.
