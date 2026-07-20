# ADR-0002 — Threlte for scene composition

**Status:** accepted · **Decision:** [D8](../design/log.md#d8--custom-scenes-as-svelte-components-via-threlte-2026-07-20) (full rationale + rejected alternatives live there)

**Context:** custom per-shader scenes should be authored as Svelte components wrapping Three.js elements, with the shader material targetable onto chosen meshes.

**Decision:** adopt Threlte (`@threlte/core`) as the single rendering path — custom scenes are `Scene.svelte` files receiving the compiled material as a prop; the built-in quad/primitive harnesses run on Threlte too.

**Why it's an ADR:** hard to reverse (every scene and the harness itself are authored against it), surprising without context (an extra framework layer on top of Three.js), and a real trade-off (declarative authoring + solved lifecycle/reactivity vs. an added dependency).
