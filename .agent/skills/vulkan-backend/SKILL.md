---
name: vulkan-backend
description: Design and review A-Engine Vulkan renderer/backend implementation while preserving backend-neutral public APIs, explicit GPU lifetime, and testable synchronization.
---

# Vulkan Backend

Use for Phase 4 renderer/backend work, Vulkan resource lifetime, synchronization, shader/pipeline implementation, descriptors, readback, or GPU scheduling.

## Required sources

Read `AGENTS.md`, renderer/shader sections of `docs/AENGINE_API_ARCHITECTURE.md`, and `docs/CODE_SHAPE_POLICY.md`. Read feature-specific paint/render contracts when migrating APaint behavior.

## Boundary rules

- Vulkan is a private backend implementation; public engine headers expose opaque resources/intents/tickets, never `Vk*`, VMA, volk, descriptor ownership, or command-buffer ownership.
- Separate backend-neutral render intent from Vulkan resource execution.
- Keep resource lifetime, synchronization policy, pipeline/shader compilation, and feature-specific rendering in focused owners rather than one renderer manager.
- Prefer explicit command/fence/queue ownership and deterministic state transitions.
- Avoid per-frame/per-stroke allocations, descriptor rebuilds, and `vkDeviceWaitIdle` when correctness does not require them.
- Correctness and synchronization evidence come before optimization.

## Shader rules

Use textual GLSL 450 -> SPIR-V for Vulkan 1.2 baseline. Reusable shader helpers are pure modules without descriptors, push constants, hidden globals, or `main()`.

## Validation

Add focused CPU contract tests for planning/lifetime where possible, reflection/ABI tests for host-shader bindings, and narrow GPU/runtime tests for synchronization or rendering behavior. Record resource owner, transition/synchronization model, and evidence path for every risky slice.
