---
name: validation-evidence
description: Validate A-Engine changes with focused tests, canonical self-hosted Windows CI, fail-fast evidence, and reproducible failure reporting.
---

# Validation and Evidence

Use for build/test work, CI changes, failure triage, regression proof, or any completion claim.

## Canonical environment

Follow `AGENTS.md`, `README.md`, and `.github/workflows/windows-x64.yml`. Phase 1 baseline is Windows x64, Visual Studio 2022 17.14, MSVC 19.44/toolset 14.44, Windows SDK 10.0.26100.0, CMake presets, and Ninja.

## Forward-only validation

1. Identify changed files, affected owner/subsystem, focused tests, and architecture guards.
2. Run the smallest relevant check first.
3. On failure, preserve the first useful failure evidence and reproduce that check directly.
4. Fix the root cause; do not weaken tests, baselines, or guards merely to get green.
5. Rerun the failed check, then the affected lane, then final Debug/Release CI when the slice requires it.
6. Do not repeat previously valid evidence unless a later change invalidates it.

## Required guards

Keep `aengine.architecture.guard`, `aengine.architecture.source_shape`, public-header self-containment, focused contract tests, and the real consumer proof relevant to the slice.

## CI rules

- Workflows must fail fast after configure/build/test errors.
- Pin approved toolchains; do not use an accidental `latest` compiler as canonical evidence.
- Self-hosted jobs must not rely on unrelated files or mutable state outside the checkout.
- Use concurrency cancellation for superseded branch/PR runs when possible.

## Completion

Do not report a slice complete while a relevant check is failed, blocked, or not run unless the maintainer explicitly accepts that exception. Report branch/commit, toolchain, build result, tests/guards, failure fingerprint when applicable, and remaining human QA.
