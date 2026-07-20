# ADR-0001 — Three.js as scene plumbing only; shaders stay raw portable GLSL

**Status:** accepted · **Decision:** [D3](../design/log.md#d3--threejs-as-scene-plumbing-only-shaders-stay-raw-portable-glsl-2026-07-20) (full rationale + rejected alternatives live there)

**Context:** shaders built here are destined for Unreal Engine 5/6; anything Three-specific baked into them is portability debt.

**Decision:** use Three.js for camera/scene/primitives, but compile authored shaders via `RawShaderMaterial` (or `ShaderMaterial` for injected matrices only) and forbid Three's lighting/fog/shadow chunk includes in authored GLSL.

**Why it's an ADR:** hard to reverse (it defines the shader authoring format for every entry), surprising without context ("why use Three but refuse its material system?"), and a real trade-off (Three's chunks give free lighting at the cost of portability).
